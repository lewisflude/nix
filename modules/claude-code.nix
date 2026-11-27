# Claude Code CLI configuration
{
  config,
  inputs,
  ...
}:
let
  inherit (config) constants aiCli;
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
      config,
      lib,
      pkgs,
      osConfig ? { },
      ...
    }:
    let
      # Atuin records Claude's Bash calls in shell history. Declared here
      # because the settings merge replaces whole hook arrays, so a hook
      # `atuin` writes into settings.json at runtime would be lost.
      atuinHooks = lib.optional config.programs.atuin.enable {
        matcher = "^Bash$";
        hooks = [
          {
            type = "command";
            command = "${lib.getExe config.programs.atuin.package} hook claude-code";
          }
        ];
      };

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

      jq = lib.getExe pkgs.jq;
      git = lib.getExe pkgs.git;

      statusLineScript = pkgs.writeShellScript "claude-status-line" ''
        input=$(cat)
        dir=$(${jq} -r '.workspace.current_dir // .cwd // "."' <<<"$input")
        branch=$(${git} -C "$dir" branch --show-current 2>/dev/null)
        ${jq} -r --arg branch "$branch" '
          [ .model.display_name + (if .effort.level then " (\(.effort.level))" else "" end),
            "\(.context_window.used_percentage // 0 | floor)% context",
            (.workspace.current_dir // .cwd // "" | split("/") | last // ""),
            $branch
          ] | map(select(. != null and . != "")) | join(" | ")' <<<"$input"
      '';

      notifyHook = pkgs.writeShellScript "claude-notify" ''
        message=$(${jq} -r '.message // "Claude Code needs your attention"')
        ${
          if pkgs.stdenv.hostPlatform.isDarwin then
            ''
              /usr/bin/osascript \
                -e 'on run argv' \
                -e 'display notification (item 1 of argv) with title "Claude Code"' \
                -e 'end run' "$message" >/dev/null 2>&1 || true
            ''
          else
            ''
              ${lib.getExe pkgs.libnotify} --app-name="Claude Code" -- "Claude Code" "$message" || true
            ''
        }
      '';

      # treefmt comes from the project's environment so that its own config
      # applies. Failures reach Claude as context instead of being swallowed.
      formatHook = pkgs.writeShellScript "claude-format" ''
        file=$(${jq} -r '.tool_input.file_path // empty')
        [ -f "$file" ] || exit 0
        command -v treefmt >/dev/null 2>&1 || exit 0
        if ! output=$(treefmt "$file" 2>&1); then
          case "$output" in
            *"failed to find treefmt config"*) exit 0 ;;
          esac
          ${jq} -n --arg output "''${output: -2000}" '{
            hookSpecificOutput: {
              hookEventName: "PostToolUse",
              additionalContext: ("treefmt failed:\n" + $output)
            }
          }'
        fi
      '';

      # Exit 2 sends stderr back to Claude; stop_hook_active prevents loops.
      nixParseHook = pkgs.writeShellScript "claude-nix-parse" ''
        input=$(cat)
        [ "$(${jq} -r '.stop_hook_active // false' <<<"$input")" = true ] && exit 0
        command -v nix-instantiate >/dev/null 2>&1 || exit 0
        cd "$(${jq} -r '.cwd // "."' <<<"$input")" || exit 0
        root=$(${git} rev-parse --show-toplevel 2>/dev/null) || exit 0
        cd "$root" || exit 0
        failed=0
        while IFS= read -r -d "" file; do
          [ -f "$file" ] || continue
          if ! output=$(nix-instantiate --parse "./$file" 2>&1 >/dev/null); then
            printf 'Nix parse error in %s:\n%s\n' "$file" "$output" >&2
            failed=2
          fi
        done < <(
          ${git} diff -z --name-only HEAD -- '*.nix' 2>/dev/null
          ${git} ls-files -z --others --exclude-standard -- '*.nix'
        )
        exit "$failed"
      '';
    in
    {
      programs.mcp = {
        enable = true;
        servers = mcpServers;
      };

      # Claude Desktop reads claude_desktop_config.json. The app writes its own
      # preferences to the same file, so merge into .mcpServers rather than
      # overwriting the whole document.
      home.activation = {
        claudeDesktopMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          CONFIG_DIR="${claudeDesktopConfigDir}"
          CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"
          run mkdir -p "$CONFIG_DIR"
          if [ ! -s "$CONFIG_FILE" ]; then
            run ${pkgs.coreutils}/bin/tee "$CONFIG_FILE" <<<'{}' > /dev/null
          fi
          TMP=$(${pkgs.coreutils}/bin/mktemp)
          ${pkgs.jq}/bin/jq --argjson servers '${claudeDesktopServersJson}' \
            '.mcpServers = $servers' "$CONFIG_FILE" > "$TMP"
          run ${pkgs.coreutils}/bin/mv "$TMP" "$CONFIG_FILE"
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
            run ${pkgs.coreutils}/bin/mkdir -p "$DEST"
            run ${pkgs.coreutils}/bin/install -m 644 \
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
              run ${pkgs.coreutils}/bin/mkdir -p "$HOME/.local/share/kicad-mcp"
              run "$KICAD_PY" -m venv --system-site-packages "$VENV_DIR"
            fi
            if [ "$(${pkgs.coreutils}/bin/cat "$STAMP" 2>/dev/null)" != "$REQ" ]; then
              run "$VENV_DIR/bin/python" -m pip install --disable-pip-version-check -r "$REQ" \
                && run ${pkgs.coreutils}/bin/tee "$STAMP" <<<"$REQ" > /dev/null
            fi
          fi
        '';

        abletonRemoteScript = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ABLETON_PREFS="$HOME/Library/Preferences/Ableton"
          [ -d "$ABLETON_PREFS" ] || exit 0
          for ver in "$ABLETON_PREFS"/Live*/; do
            [ -d "$ver" ] || continue
            DEST="$ver/User Remote Scripts/AbletonMCP"
            run ${pkgs.coreutils}/bin/mkdir -p "$DEST"
            run ${pkgs.coreutils}/bin/install -m 644 \
              ${abletonRemoteScript} "$DEST/__init__.py"
          done
        '';
      };

      # The Nix build is Claude's native binary, so its self-check expects the
      # native installer's ~/.local/bin (also XDG_BIN_HOME) on PATH and warns
      # in /status otherwise. sessionPath prepends: keep `claude` out of it
      # (DISABLE_AUTOUPDATER stops the native installer writing one there).
      home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

      programs.claude-code = {
        enable = true;
        package = pkgs.claude-code;
        enableMcpIntegration = true;
        # Merges into a writable file so runtime changes (/effort, /model)
        # survive. Keys removed from here linger on disk until deleted by hand.
        mutableSettings = true;

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
          # Opus 5.5 and later ignore the user-level effortLevel above.
          modelSettings.claude-opus-5-5.effortLevel = "high";

          cleanupPeriodDays = 90;

          statusLine = {
            type = "command";
            command = "${statusLineScript}";
          };

          autoMode = {
            # Broad allow rules below (git, gh, nix, curl) would otherwise skip
            # the classifier. They still apply in the other modes.
            classifyAllShell = true;
            hard_deny = [
              "$defaults"
              "Never activate a NixOS, nix-darwin or Home Manager configuration by any route; building and evaluating is fine."
            ];
          };

          env = {
            DISABLE_AUTOUPDATER = "1";
            DISABLE_TELEMETRY = "1";
            DISABLE_ERROR_REPORTING = "1";
          };

          attribution = {
            commit = "";
          };

          enabledPlugins = {
            "code-simplifier@claude-plugins-official" = true;
            "figma@claude-plugins-official" = true;
          };

          permissions = {
            defaultMode = "auto";
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
              "mcp__plugin_hm_figma__get_screenshot"
              "mcp__plugin_hm_figma__get_metadata"
              # containers (read-only)
              "Bash(docker ps *)"
              "Bash(docker logs *)"
              "Bash(docker inspect *)"
              "Bash(docker images *)"
              # env tools
              "Bash(direnv *)"
              "Bash(devenv *)"
              # read-only root diagnostics (storage, hardware, logs)
              "Bash(sudo zpool status *)"
              "Bash(sudo zpool list *)"
              "Bash(sudo zpool get *)"
              "Bash(sudo zpool events *)"
              "Bash(sudo zpool iostat *)"
              "Bash(sudo zpool history *)"
              "Bash(sudo zfs list *)"
              "Bash(sudo zfs get *)"
              "Bash(sudo smartctl *)"
              "Bash(sudo nvme list*)"
              "Bash(sudo nvme smart-log *)"
              "Bash(sudo ras-mc-ctl *)"
              "Bash(sudo dmesg*)"
              "Bash(sudo journalctl *)"
              "Bash(sudo systemctl status *)"
              "Bash(sudo ls /var/lib/systemd/pstore*)"
              "Bash(sudo cat /var/lib/systemd/pstore/*)"
            ];
            ask = [
              "Bash(git push --force*)"
              "Bash(git push -f *)"
              "Bash(git push *--force*)"
              "Bash(git push * -f*)"
            ];
            deny = [
              # Narrow sudo denies instead of a blanket "Bash(sudo *)": the
              # blanket rule also blocked read-only diagnostics (zpool status,
              # smartctl, pstore forensics) that genuinely need root. Deny beats
              # allow and applies even in bypass-permissions mode, so only
              # destructive or system-mutating sudo forms belong here.
              "Bash(sudo rm *)"
              "Bash(sudo chmod *)"
              "Bash(sudo chown *)"
              "Bash(sudo dd *)"
              "Bash(sudo mkfs*)"
              "Bash(sudo nixos-rebuild *)"
              "Bash(sudo darwin-rebuild *)"
              "Bash(sudo nh *)"
              "Bash(sudo zpool create *)"
              "Bash(sudo zpool destroy *)"
              "Bash(sudo zpool remove *)"
              "Bash(sudo zpool replace *)"
              "Bash(sudo zpool labelclear *)"
              "Bash(sudo zfs destroy *)"
              "Bash(sudo zfs rollback *)"
              "Bash(sudo zfs rename *)"
              "Bash(sudo zfs receive *)"
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
            PreToolUse = atuinHooks;
            PostToolUseFailure = atuinHooks;
            PostToolUse = atuinHooks ++ [
              {
                matcher = "Edit|Write";
                hooks = [
                  {
                    type = "command";
                    command = "${formatHook}";
                    timeout = 30;
                  }
                ];
              }
            ];
            Stop = [
              {
                hooks = [
                  {
                    type = "command";
                    command = "${nixParseHook}";
                    timeout = 60;
                  }
                ];
              }
            ];
            Notification = [
              {
                matcher = "permission_prompt|idle_prompt|elicitation_dialog|agent_needs_input";
                hooks = [
                  {
                    type = "command";
                    command = "${notifyHook}";
                    timeout = 10;
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

      home.packages =
        let
          llmAgentPkgs = pkgs.llmAgents or { };
        in
        lib.optionals (llmAgentPkgs ? ccusage) [ llmAgentPkgs.ccusage ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.claude-desktop ];
    };
}
