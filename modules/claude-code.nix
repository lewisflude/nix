# Claude Code CLI configuration
{
  config,
  inputs,
  ...
}:
let
  inherit (config) constants aiCli trustedDirs;
in
{
  # Claude Code from sadjow/claude-code-nix (hourly upstream updates, Cachix cache).
  # The "n" prefix sorts after "l" (llm-agents) so this overlay applies later
  # and wins precedence for `claude-code`.
  overlays.native-claude-code =
    _final: prev:
    let
      pkgs = inputs.claude-code-nix.packages.${prev.stdenv.hostPlatform.system} or null;
    in
    if pkgs != null then { claude-code = pkgs.default; } else { };

  # Claude Desktop (Linux only). Patches around nodePackages.asar removal in nixpkgs 2026-03-03.
  overlays.claude-desktop =
    final: prev:
    if prev.stdenv.hostPlatform.isLinux then
      let
        src = inputs.claude-desktop-linux;
        patchy-cnb = prev.callPackage "${src}/pkgs/patchy-cnb.nix" { };
        claude-desktop-unwrapped = prev.callPackage "${src}/pkgs/claude-desktop.nix" {
          inherit patchy-cnb;
          nodePackages = {
            inherit (final) asar;
          };
        };
      in
      {
        claude-desktop = prev.buildFHSEnv {
          name = "claude-desktop";
          targetPkgs = p: [
            p.docker
            p.glibc
            p.openssl
            p.nodejs
            p.uv
          ];
          runScript = "${claude-desktop-unwrapped}/bin/claude-desktop";
          extraInstallCommands = ''
            mkdir -p $out/share/applications
            cp ${claude-desktop-unwrapped}/share/applications/claude.desktop $out/share/applications/
            mkdir -p $out/share/icons
            cp -r ${claude-desktop-unwrapped}/share/icons/* $out/share/icons/
          '';
        };
      }
    else
      { };

  flake.modules.nixos.claudeCode = _: {
    networking.firewall.allowedTCPPorts = [ constants.ports.mcp.docs ];
  };

  flake.modules.homeManager.claudeCode =
    {
      lib,
      pkgs,
      config,
      osConfig ? { },
      ...
    }:
    let
      secretAvailable = aiCli.secretAvailable osConfig;
      secretPath = aiCli.secretPath osConfig;

      abletonRemoteScript = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/ahujasid/ableton-mcp/e0083285426dedb5c93ce8a532ecfbb25ae9a3ca/AbletonMCP_Remote_Script/__init__.py";
        hash = "sha256-dYyQES4n88JQAT6yDkRXVfsD9VPA4S9RKlVtgi7XhTs=";
      };
      blenderMcpAddon = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/ahujasid/blender-mcp/7636d13bded82eca58eb93c3f4cd8708dfdfbe8b/addon.py";
        hash = "sha256-ipXFL9AUGg6QlD6WgEhFvSW3bJRPc1XkIrltuXH1AFA=";
      };

      # Shared prompt body, also used by the Codex skill (modules/codex.nix).
      # Each consumer supplies its own frontmatter.
      organizeSamplesCommand = ''
        ---
        description: Organise ~/Music/samples after new music-production torrents have landed. Surveys, proposes a taxonomy, and moves items with confirmation.
        allowed-tools: Bash(ls:*), Bash(find:*), Bash(file:*), Bash(du:*), Bash(mv:*), Bash(mkdir:*), Bash(rmdir:*), Read, Glob, Grep
        argument-hint: [optional focus: drums|synths|loops|...]
        ---

      ''
      + builtins.readFile ../pkgs/prompts/organize-samples.md;

      mcpServers =
        aiCli.mcpServers pkgs osConfig
        // {
          # SPICEBridge (PyPI-only, not in nixpkgs): run via uvx with ngspice on
          # PATH for the simulation backend. Local stdio only — never the
          # `setup-cloud` wizard, which opens a public Cloudflare tunnel.
          spicebridge = {
            command = "${pkgs.writeShellScript "mcp-spicebridge" ''
              export PATH="${pkgs.ngspice}/bin:$PATH"
              ${aiCli.uvxEnv pkgs}
              exec ${pkgs.uv}/bin/uvx spicebridge "$@"
            ''}";
          };
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          # KiCAD MCP (mixelpixx/KiCAD-MCP-Server, not in nixpkgs): a Node server
          # built as pkgs.kicad-mcp that drives KiCAD through its bundled Python
          # `pcbnew` bindings. KICAD_PYTHON must point at KiCAD.app's own python3
          # so pcbnew's ABI matches the installed KiCAD; PYTHONPATH is derived from
          # that interpreter (mirrors the project's setup-macos.sh) rather than
          # hardcoding a minor version. Darwin-only: this is the macOS KiCAD.app
          # layout — KiCAD on Linux would use a nixpkgs interpreter instead.
          kicad = {
            command = "${pkgs.writeShellScript "mcp-kicad" ''
              # Prefer the venv built by the kicadMcpVenv activation hook: it has
              # the third-party Python deps and still sees pcbnew via
              # --system-site-packages. Fall back to KiCAD's own interpreter if
              # the venv hasn't been provisioned yet.
              kicad_py="$HOME/.local/share/kicad-mcp/venv/bin/python"
              [ -x "$kicad_py" ] || kicad_py="/Applications/KiCad/KiCad.app/Contents/Frameworks/Python.framework/Versions/Current/bin/python3"
              if [ -x "$kicad_py" ]; then
                export KICAD_PYTHON="$kicad_py"
                export PYTHONPATH="$("$kicad_py" -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')"
              fi
              export NODE_ENV=production
              export LOG_LEVEL=info
              export KICAD_AUTO_LAUNCH=false
              exec ${pkgs.kicad-mcp}/bin/kicad-mcp "$@"
            ''}";
          };
        }
        // lib.optionalAttrs (secretAvailable "KAGI_API_KEY") {
          kagi = {
            command = "${pkgs.writeShellScript "mcp-kagi" ''
              export KAGI_API_KEY="$(cat ${lib.escapeShellArg (secretPath "KAGI_API_KEY")})"
              ${aiCli.uvxEnv pkgs}
              exec ${pkgs.uv}/bin/uvx kagimcp "$@"
            ''}";
          };
        };

      claudeDesktopConfigDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "$HOME/Library/Application Support/Claude"
        else
          "$HOME/.config/Claude";

      # Filesystem MCP is Claude Desktop-only: the CLI clients have native
      # Read/Edit/Write tools and don't need a duplicate. Paths use ~ which the
      # wrapper script expands at launch, so the allowlist resolves per-user.
      claudeDesktopFilesystemDirs = [
        "~/Obsidian Vault"
        "~/Music/samples"
        "~/.config/nix"
        "~/Documents"
      ];

      claudeDesktopFilesystemServer = {
        command = "${pkgs.writeShellScript "mcp-filesystem" ''
          export PATH="${pkgs.nodejs}/bin:$PATH"
          dirs=()
          for d in ${
            lib.concatMapStringsSep " " (
              d: ''"${lib.replaceStrings [ "~" ] [ "\${HOME}" ] d}"''
            ) claudeDesktopFilesystemDirs
          }; do
            if [ -d "$d" ]; then
              dirs+=("$d")
            else
              echo "mcp-filesystem: skipping missing dir $d" >&2
            fi
          done
          exec ${pkgs.nodejs}/bin/npx -y @modelcontextprotocol/server-filesystem "''${dirs[@]}" "$@"
        ''}";
      };

      # Claude Desktop only accepts stdio servers ({ command, args, env }).
      # Wrap HTTP/URL servers with `npx mcp-remote` so they appear as stdio.
      # Header values may contain ${VAR} placeholders that the wrapper script
      # leaves for the shell to expand at launch time.
      #
      # `figma` is excluded: mcp-remote uses Dynamic Client Registration, which
      # Figma's OAuth rejects (403). Add Figma via Claude Desktop's native
      # Connectors UI instead — it uses a pre-registered OAuth client.
      claudeDesktopServers =
        lib.mapAttrs (
          name: server:
          if server ? url then
            let
              headerArgs = lib.concatStringsSep " " (
                lib.mapAttrsToList (k: v: ''--header "${k}: ${v}"'') (server.headers or { })
              );
            in
            {
              command = "${pkgs.writeShellScript "mcp-remote-${name}" ''
                export PATH="${pkgs.nodejs}/bin:$PATH"
                exec npx -y mcp-remote ${lib.escapeShellArg server.url} ${headerArgs} "$@"
              ''}";
            }
          else
            server
        ) (lib.removeAttrs mcpServers [ "figma" ])
        // {
          filesystem = claudeDesktopFilesystemServer;
        };

      claudeDesktopServersJson = builtins.toJSON claudeDesktopServers;
    in
    {
      programs.mcp = {
        enable = true;
        servers = mcpServers;
      };

      programs.zsh.initContent = lib.mkIf config.programs.zsh.enable (
        lib.mkAfter (
          aiCli.mkTrustedWrapper {
            cmd = "claude";
            trustedFlag = "--dangerously-skip-permissions";
            inherit trustedDirs;
          }
        )
      );

      # Claude Desktop reads claude_desktop_config.json. The app writes its own
      # preferences to the same file, so merge into .mcpServers rather than
      # overwriting the whole document.
      home.activation = {
        # Home-manager symlinks ~/.claude/settings.json to a read-only /nix/store path.
        # Claude Code's /effort and /model commands need to write to that file, so we
        # replace the symlink with a writable copy after activation. Rebuilds reset the
        # file to the declarative values; runtime /effort changes persist until the next
        # `nh home switch`.
        claudeCodeMutableSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          SETTINGS="$HOME/.claude/settings.json"
          if [ -L "$SETTINGS" ]; then
            TARGET=$(${pkgs.coreutils}/bin/readlink -f "$SETTINGS")
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm "$SETTINGS"
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 644 "$TARGET" "$SETTINGS"
          fi
        '';

        claudeDesktopMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          CONFIG_DIR="${claudeDesktopConfigDir}"
          CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"
          $DRY_RUN_CMD mkdir -p "$CONFIG_DIR"
          if [ ! -s "$CONFIG_FILE" ]; then
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/tee "$CONFIG_FILE" <<<'{}' > /dev/null
          fi
          TMP=$(${pkgs.coreutils}/bin/mktemp)
          ${pkgs.jq}/bin/jq --argjson servers '${claudeDesktopServersJson}' \
            '.mcpServers = $servers' "$CONFIG_FILE" > "$TMP"
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$TMP" "$CONFIG_FILE"
        '';

        blenderMcpAddon = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if [ -d "$HOME/.config/blender" ]; then
            BLENDER_BASE="$HOME/.config/blender"
          elif [ -d "$HOME/Library/Application Support/Blender" ]; then
            BLENDER_BASE="$HOME/Library/Application Support/Blender"
          else
            exit 0
          fi
          for ver in "$BLENDER_BASE"/[0-9]*/; do
            [ -d "$ver" ] || continue
            DEST="$ver/scripts/addons/blender_mcp"
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$DEST"
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 644 \
              ${blenderMcpAddon} "$DEST/__init__.py"
          done
        '';
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        # KiCAD's bundled Python is 3.9 (EOL, no longer in nixpkgs) and the MCP
        # server's Python side needs sexpdata/Pillow/pydantic/cairosvg/etc. Build
        # a venv from KiCAD's own interpreter (--system-site-packages keeps pcbnew
        # visible) and pip-install the server's pinned requirements. Re-runs only
        # when requirements.txt changes (stamped by its store path). Skips cleanly
        # on machines without KiCAD installed.
        kicadMcpVenv = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          KICAD_PY="/Applications/KiCad/KiCad.app/Contents/Frameworks/Python.framework/Versions/Current/bin/python3"
          if [ ! -x "$KICAD_PY" ]; then
            echo "kicad-mcp: KiCAD Python not found, skipping venv provisioning" >&2
          else
            VENV_DIR="$HOME/.local/share/kicad-mcp/venv"
            REQ="${inputs.kicad-mcp-server}/requirements.txt"
            STAMP="$HOME/.local/share/kicad-mcp/.requirements-stamp"
            if [ ! -x "$VENV_DIR/bin/python" ]; then
              $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$HOME/.local/share/kicad-mcp"
              $DRY_RUN_CMD "$KICAD_PY" -m venv --system-site-packages "$VENV_DIR"
            fi
            if [ "$(${pkgs.coreutils}/bin/cat "$STAMP" 2>/dev/null)" != "$REQ" ]; then
              $DRY_RUN_CMD "$VENV_DIR/bin/python" -m pip install --disable-pip-version-check -r "$REQ" \
                && $DRY_RUN_CMD ${pkgs.coreutils}/bin/tee "$STAMP" <<<"$REQ" > /dev/null
            fi
          fi
        '';

        abletonRemoteScript = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ABLETON_PREFS="$HOME/Library/Preferences/Ableton"
          [ -d "$ABLETON_PREFS" ] || exit 0
          for ver in "$ABLETON_PREFS"/Live*/; do
            [ -d "$ver" ] || continue
            DEST="$ver/User Remote Scripts/AbletonMCP"
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$DEST"
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 644 \
              ${abletonRemoteScript} "$DEST/__init__.py"
          done
        '';
      };

      programs.claude-code = {
        enable = true;
        package = pkgs.claude-code;
        enableMcpIntegration = true;

        lspServers = {
          nix = {
            command = "${pkgs.nixd}/bin/nixd";
            extensionToLanguage = {
              ".nix" = "nix";
            };
          };
          typescript = {
            command = "${pkgs.typescript-language-server}/bin/typescript-language-server";
            args = [ "--stdio" ];
            extensionToLanguage = {
              ".ts" = "typescript";
              ".tsx" = "typescriptreact";
              ".js" = "javascript";
              ".jsx" = "javascriptreact";
              ".mjs" = "javascript";
              ".cjs" = "javascript";
            };
          };
          python = {
            command = "${pkgs.pyright}/bin/pyright-langserver";
            args = [ "--stdio" ];
            extensionToLanguage = {
              ".py" = "python";
              ".pyi" = "python";
            };
          };
          rust = {
            command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
            extensionToLanguage = {
              ".rs" = "rust";
            };
          };
          go = {
            command = "${pkgs.gopls}/bin/gopls";
            args = [ "serve" ];
            extensionToLanguage = {
              ".go" = "go";
            };
          };
        };

        settings = {
          effortLevel = "medium";

          env = {
            DISABLE_AUTOUPDATER = "1";
          };

          attribution = {
            commit = "Co-Authored-By: Claude <noreply@anthropic.com>";
          };

          enabledPlugins = {
            "code-simplifier@claude-plugins-official" = true;
            "figma@claude-plugins-official" = true;
          };

          permissions = {
            defaultMode = "acceptEdits";
            allow = [
              "Read"
              "Edit"
              "Write"
              "WebFetch"
              "WebSearch"
              # dev tools
              "Bash(git *)"
              "Bash(gh *)"
              "Bash(nix *)"
              "Bash(npm *)"
              "Bash(npx *)"
              "Bash(node *)"
              "Bash(cargo *)"
              "Bash(rustc *)"
              "Bash(rustup *)"
              "Bash(go *)"
              "Bash(python *)"
              "Bash(python3 *)"
              "Bash(uv *)"
              "Bash(pip *)"
              "Bash(make *)"
              "Bash(cmake *)"
              # formatters
              "Bash(treefmt *)"
              "Bash(nixfmt *)"
              "Bash(biome *)"
              "Bash(prettier *)"
              # filesystem
              "Bash(jq *)"
              "Bash(mdfind *)"
              "Bash(awk *)"
              # network
              "Bash(curl *)"
              # MCP read-only
              "mcp__plugin_claude-code-home-manager_figma__get_screenshot"
              "mcp__plugin_claude-code-home-manager_figma__get_metadata"
              # containers (read-only)
              "Bash(docker ps *)"
              "Bash(docker logs *)"
              "Bash(docker inspect *)"
              "Bash(docker images *)"
              # env tools
              "Bash(direnv *)"
              "Bash(devenv *)"
            ];
            ask = [
              "Bash(git push --force*)"
              "Bash(git push -f *)"
            ];
            deny = [
              "Bash(sudo *)"
              "Bash(rm -rf *)"
              "Bash(chmod *)"
              "Bash(chown *)"
              "Bash(nixos-rebuild *)"
              "Bash(darwin-rebuild *)"
              "Bash(nh os *)"
              "Bash(nh home *)"
              "Read(./.env)"
              "Read(./.env.*)"
              "Read(./secrets/**)"
              "Read(**/id_rsa*)"
              "Read(**/*.pem)"
            ];
          };

          hooks = {
            PostToolUse = [
              {
                matcher = "Edit|Write";
                hooks = [
                  {
                    type = "command";
                    command = ''
                      INPUT=$(cat)
                      FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
                      if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
                        treefmt "$FILE_PATH" 2>/dev/null || true
                      fi
                    '';
                    timeout = 30;
                  }
                ];
              }
            ];
          };
        };

        skills = {
          dendritic-pattern = builtins.readFile ../pkgs/claude-code/skills/dendritic-pattern.md;
          blender-help = builtins.readFile ../pkgs/claude-code/skills/blender-help.md;
        };

        commands = {
          organize-samples = organizeSamplesCommand;
          build-drum-rack = builtins.readFile ../pkgs/claude-code/commands/build-drum-rack.md;
        };

        agents = {
          nix-module = builtins.readFile ../pkgs/claude-code/agents/nix-module.md;
          code-reviewer = builtins.readFile ../pkgs/claude-code/agents/code-reviewer.md;
        };
      };

      # claudeCodeMutableSettings above replaces Home Manager's
      # ~/.claude/settings.json symlink with a writable file after each
      # activation. On the next activation, Home Manager must overwrite that
      # mutable file instead of trying to create a .hm-backup that may already
      # exist from an earlier switch. The key must match the absolute-path key
      # used by programs.claude-code (cfg.configDir defaults to
      # "${homeDirectory}/.claude") to avoid a target-conflict assertion.
      home.file."${config.home.homeDirectory}/.claude/settings.json".force = true;

      home.packages =
        let
          llmAgentPkgs = pkgs.llmAgents or { };
        in
        lib.optionals (llmAgentPkgs ? ccusage) [ llmAgentPkgs.ccusage ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.claude-desktop ];
    };
}
