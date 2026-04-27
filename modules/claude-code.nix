# Claude Code CLI configuration
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.claudeCode = _: {
    networking.firewall.allowedTCPPorts = [ constants.ports.mcp.docs ];
  };

  flake.modules.homeManager.claudeCode =
    { lib, pkgs, ... }:
    let
      abletonRemoteScript = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/ahujasid/ableton-mcp/e0083285426dedb5c93ce8a532ecfbb25ae9a3ca/AbletonMCP_Remote_Script/__init__.py";
        hash = "sha256-dYyQES4n88JQAT6yDkRXVfsD9VPA4S9RKlVtgi7XhTs=";
      };
    in
    {
      programs.mcp = {
        enable = true;
        servers = {
          context7 = {
            url = "https://mcp.context7.com/mcp";
          };
          github = {
            url = "https://api.githubcopilot.com/mcp/";
            headers = {
              Authorization = "Bearer \${GITHUB_TOKEN}";
            };
          };
          figma-desktop = {
            url = "http://127.0.0.1:${toString constants.ports.mcp.figma}/mcp";
          };
          git = {
            command = "uvx";
            args = [ "mcp-server-git" ];
          };
          time = {
            command = "uvx";
            args = [ "mcp-server-time" ];
          };
          sqlite = {
            command = "${pkgs.writeShellScript "mcp-sqlite" ''
              exec uvx mcp-server-sqlite --db-path "$HOME/.local/share/mcp/data.db" "$@"
            ''}";
          };
          playwright = {
            command = "${pkgs.writeShellScript "mcp-playwright" ''
              export PATH="${pkgs.nodejs}/bin:$PATH"
              exec npx -y @playwright/mcp@0.0.68 "$@"
            ''}";
          };
          sequential-thinking = {
            command = "${pkgs.writeShellScript "mcp-sequential-thinking" ''
              export PATH="${pkgs.nodejs}/bin:$PATH"
              exec npx -y @modelcontextprotocol/server-sequential-thinking@2025.12.18 "$@"
            ''}";
          };
          nixos = {
            command = "uvx";
            args = [ "mcp-nixos" ];
          };
          obsidian = {
            command = "${pkgs.writeShellScript "mcp-obsidian" ''
              export PATH="${pkgs.nodejs}/bin:$PATH"
              exec npx -y @bitbonsai/mcpvault@0.11.0 "$HOME/Obsidian Vault" "$@"
            ''}";
          };
        }
        // lib.optionalAttrs pkgs.stdenv.isDarwin {
          ableton = {
            command = "${pkgs.uv}/bin/uvx";
            args = [ "ableton-mcp" ];
          };
        };
      };

      # Claude Desktop (macOS app) MCP config. Claude Desktop writes its own
      # preferences to this file, so we merge rather than overwrite.
      home.activation = lib.optionalAttrs pkgs.stdenv.isDarwin {
        claudeDesktopMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          CONFIG_DIR="$HOME/Library/Application Support/Claude"
          CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"
          $DRY_RUN_CMD mkdir -p "$CONFIG_DIR"
          if [ ! -s "$CONFIG_FILE" ]; then
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/tee "$CONFIG_FILE" <<<'{}' > /dev/null
          fi
          MCP_SERVERS=$(${pkgs.jq}/bin/jq -n \
            --arg uvx "${pkgs.uv}/bin/uvx" \
            '{ AbletonMCP: { command: $uvx, args: ["ableton-mcp"] } }')
          TMP=$(${pkgs.coreutils}/bin/mktemp)
          ${pkgs.jq}/bin/jq --argjson servers "$MCP_SERVERS" \
            '.mcpServers = $servers' "$CONFIG_FILE" > "$TMP"
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$TMP" "$CONFIG_FILE"
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
          env = {
            DISABLE_AUTOUPDATER = "1";
            FORCE_AUTOUPDATE_PLUGINS = "1";
          };

          attribution = {
            commit = "Co-Authored-By: Claude <noreply@anthropic.com>";
          };

          enabledPlugins = {
            "code-simplifier@claude-plugins-official" = true;
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
              "Bash(ls *)"
              "Bash(wc *)"
              "Bash(mkdir *)"
              "Bash(cp *)"
              "Bash(mv *)"
              "Bash(touch *)"
              "Bash(which *)"
              "Bash(mdfind *)"
              # network
              "Bash(curl *)"
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

        rules = {
          code-style = ''
            # Code Style

            - Write concise, minimal code. Prefer terse patterns over verbose/defensive ones.
            - Use functional patterns (map, filter, reduce, pipe) over imperative loops.
            - Use strong, explicit types. Avoid any/unknown. Prefer type annotations.
            - Only comment non-obvious logic. Code should be self-documenting.
            - Delete dead code rather than commenting it out.
          '';
          research-first = ''
            # Research-First Protocol

            ## Before Answering Technical Questions

            - **Verify before stating.** Never fabricate package names, option names, API signatures, CLI flags, menu paths, or version numbers. If unsure, look it up or say so.
            - **Use available tools.** Prefer Context7, WebSearch, WebFetch, and mcp-nixos over training data for anything version-specific, recently changed, or niche.
            - **Admit uncertainty explicitly.** Say "I'm not sure" or "Let me check" rather than guessing. Confidence without verification is harmful.
            - **Cite sources.** When referencing documentation, include where you found it.
            - **Specify versions.** Always mention which version of software, library, or API your advice applies to.

            ## Tool Priority for Verification

            1. **Context7** — library/framework docs (React, Django, Prisma, etc.)
            2. **mcp-nixos** — NixOS packages, options, Home Manager options, nix-darwin settings
            3. **WebSearch** — recent changes, changelogs, niche tools, community solutions
            4. **WebFetch** — read specific documentation pages, wikis, READMEs
            5. **Grep/Glob** — verify claims against the actual codebase

            ## Especially Important For

            - NixOS/Home Manager option names and types
            - Blender plugin UIs, menus, and settings (these change between versions)
            - CLI tool flags and subcommands
            - Hardware-specific configuration
            - Any domain where your training data may be sparse or outdated
          '';
        };

        skills = {
          dendritic-pattern = ''
            ---
            description: Dendritic pattern guide for writing and modifying .nix flake-parts modules in this repository. Use whenever editing, creating, or refactoring .nix files in this repo.
            ---

            # Dendritic Pattern

            Every .nix file (except flake.nix) is a flake-parts module.

            ## Module Template

            ```nix
            { config, ... }:
            let
              constants = config.constants;
            in
            {
              flake.modules.nixos.featureName = { pkgs, lib, ... }: {
                # NixOS system config (services, kernel, hardware, daemons)
              };

              flake.modules.homeManager.featureName = { pkgs, ... }: {
                # Home-manager config (user apps, dotfiles, dev tools, shell)
              };
            }
            ```

            ## Two Scopes — Avoiding Config Shadowing

            Use a named parameter to access platform config without shadowing outer (flake-parts) config:

            ```nix
            { config, ... }:
            {
              flake.modules.nixos.shell = nixosArgs: {
                # config = flake-parts top-level (outer scope)
                # nixosArgs.config = NixOS platform config
                users.users.''${config.username}.shell = nixosArgs.config.programs.fish.package;
              };
            }
            ```

            If you don't need platform config, destructure normally:

            ```nix
            { config, ... }:
            {
              flake.modules.nixos.shell = { pkgs, ... }: {
                users.users.''${config.username}.shell = pkgs.fish;
              };
            }
            ```

            ## Anti-Patterns

            - `{ config, pkgs, ... }:` inside module body — **shadows outer config**
            - `with pkgs;` — use explicit `pkgs.package`
            - `specialArgs = { inherit inputs; }` — access `inputs` from outer scope
            - `import ../lib/constants.nix` — use `config.constants`
            - Importing modules in infrastructure — hosts compose features, infrastructure only transforms

            ## Placement Rules

            - System services, kernel, hardware, daemons, boot, networking → `flake.modules.nixos.*`
            - User apps, dotfiles, dev tools, tray applets, shell, editor → `flake.modules.homeManager.*`

            ## Workflow Commands

            - Scaffold new module: `nix run .#new-module`
            - Update deps: `nix run .#update-all`
            - Format: `nix fmt` (treefmt)
            - Validate: `nix flake check`
            - Never rebuild systems from within Claude — suggest `nh os switch` / `nh home switch` for the user to run.
          '';
          blender-help = ''
            ---
            description: Help with Blender plugins, addons, and 3D workflows. Use when discussing Hair Tool, CharMorph, bpy API, or any Blender-related topic.
            ---

            # Blender Plugin & Workflow Assistant

            You are helping a user learn and use Blender plugins. The user may be working with Hair Tool, CharMorph, or other addons.

            ## Research Protocol

            **Always verify before answering.** Blender plugin UIs, settings, and workflows change between versions. Never guess at menu locations, panel names, parameter names, or keyboard shortcuts.

            1. **Ask which Blender version** the user is running (4.x vs 3.x matters significantly)
            2. **Ask which plugin version** they have installed
            3. **WebSearch** for the plugin's current documentation, changelog, or wiki
            4. **WebFetch** the plugin's official docs page if available
            5. **Search for video tutorial transcripts** or forum posts for step-by-step workflows

            ## Hair Tool Specifics

            - Hair Tool is a paid Blender addon for hair/fur creation and grooming
            - UI and workflow changed significantly between Blender 3.x and 4.x
            - Key concepts: hair curves, guide curves, interpolation, clumping, braiding
            - Always verify panel locations — they move between versions

            ## CharMorph Specifics

            - CharMorph is an open-source character creation addon for Blender
            - Uses morphing/shape keys for character customization
            - Key concepts: morphs, materials, presets, fitting, asset library
            - Documentation may be sparse — search GitHub issues and wiki

            ## General Approach

            - Walk through steps one at a time, confirming the user can see each UI element
            - Include screenshots references when possible (suggest the user share screenshots)
            - If a step doesn't match what the user sees, troubleshoot version differences
            - Suggest the user check Preferences > Add-ons to confirm the addon is enabled and its version
          '';
          deep-research = ''
            ---
            description: Research a topic thoroughly before answering. Use when investigating unfamiliar libraries, APIs, tools, or workflows where accuracy matters more than speed.
            ---

            # Deep Research Mode

            Research the given topic thoroughly before providing any answer.

            ## Process

            1. **Identify what needs verification.** Break the question into specific factual claims that need checking.
            2. **Search broadly first.** Use WebSearch to find current, authoritative sources. Look for:
               - Official documentation
               - Recent changelog entries or release notes
               - GitHub issues or discussions
               - Community forums (Reddit, Discourse, Stack Overflow)
            3. **Read primary sources.** Use WebFetch to read the actual documentation pages, not just search snippets.
            4. **Use specialized tools.** Context7 for library docs, mcp-nixos for Nix options.
            5. **Cross-reference.** Verify claims against multiple sources when possible.
            6. **Synthesize with citations.** Present findings with source links.

            ## Output Format

            Structure your response as:
            - **Answer** — the verified information
            - **Sources** — links to documentation or references used
            - **Caveats** — what you couldn't verify, version-specific notes, or known gaps
            - **Version info** — which versions this applies to

            ## Rules

            - Never state something as fact without a source
            - If you find conflicting information, present both sides
            - If documentation is sparse, say so explicitly
            - Prefer official docs over blog posts over forum answers
          '';
        };

        commands = {
          organize-samples = ''
            ---
            description: Organise ~/Music/samples after new music-production torrents have landed. Surveys, proposes a taxonomy, and moves items with confirmation.
            allowed-tools: Bash(ls:*), Bash(find:*), Bash(file:*), Bash(du:*), Bash(mv:*), Bash(mkdir:*), Bash(rmdir:*), Read, Glob, Grep
            argument-hint: [optional focus: drums|synths|loops|...]
            ---

            You are tidying the user's sample library at `~/Music/samples`. This folder is NFS-exported to Mercury (macOS) and consumed by Ableton Live, so the layout must stay stable and human-browsable.

            New content lands here automatically via qBittorrent's `music-production` category. Each completed torrent arrives as `~/Music/samples/<torrent-name>/`.

            ## Workflow

            1. **Survey.** List the top level of `~/Music/samples`. For each unorganised entry, note: name, size (`du -sh`), and a one-line guess at its type (drum kit, synth preset pack, loop pack, stems, multisample, etc.). Use `file` / extensions to inform the guess.
            2. **Propose a taxonomy.** Use or extend the user's existing folders. Prefer this baseline unless the user has diverged:
               - `drums/` — oneshots, kits, breaks
               - `loops/` — melodic/rhythmic loops
               - `synths/` — presets, patches, multisamples
               - `stems/` — song stems, acapellas
               - `fx/` — risers, impacts, foley, textures
               - `packs/` — commercial sample packs kept whole
            3. **Confirm before moving.** Present the proposed moves in a table (source → destination) and wait for approval. Never move without confirmation.
            4. **Preserve structure.** If a torrent arrives as a well-structured sample pack (e.g. nested `Kicks/`, `Snares/`, `Presets/`), keep it whole under `packs/<pack-name>/`. Do not flatten commercial packs.
            5. **Move, never copy or delete.** Use `mv`. If a destination already exists, ask the user — do not overwrite.
            6. **Clean up empties.** After moves, `rmdir` empty source dirs (but never `rm -rf`).

            ## Guardrails

            - Treat anything ambiguous as a question for the user rather than a guess.
            - If `$ARGUMENTS` is set (e.g. `drums`), restrict the pass to items that look like that category.
            - Never touch files outside `~/Music/samples`.
            - Never delete. If something looks like junk (thumbnails, `.DS_Store`, torrent metadata), surface it and let the user decide.
            - Ableton references samples by absolute path — warn the user before moving anything that's already been dragged into a live project.
          '';
        };

        agents = {
          nix-module = ''
            ---
            name: nix-module
            description: Creates and modifies Nix modules following the dendritic pattern. Use when writing or refactoring .nix files.
            tools: Read, Write, Edit, Glob, Grep, Bash
            model: inherit
            ---

            You are a Nix module specialist for a repository using the dendritic pattern with flake-parts.

            ## Architecture Rules

            - Every .nix file (except flake.nix) is a flake-parts module
            - Two levels: top-level (flake-parts) and platform-level (NixOS/Darwin/home-manager)
            - Access shared values via top-level `config.*`, never use `specialArgs`
            - Access constants via `config.constants`, never import directly
            - Use named parameters (e.g., `nixosArgs`) to avoid shadowing outer `config`
            - Never use `with pkgs;`, always use explicit `pkgs.package`
            - Hosts compose features via imports; infrastructure only transforms

            ## Module Template

            ```nix
            { config, ... }:
            {
              flake.modules.homeManager.featureName = { pkgs, ... }: {
                # home-manager config here
              };

              flake.modules.nixos.featureName = { pkgs, lib, ... }: {
                # NixOS system config here
              };
            }
            ```

            ## Placement Rules

            - System services, kernel, hardware, daemons -> flake.modules.nixos.*
            - User apps, dotfiles, dev tools, tray applets -> flake.modules.homeManager.*
            - Format all output with nixfmt
          '';

          code-reviewer = ''
            ---
            name: code-reviewer
            description: Reviews code for quality, security, and correctness. Use proactively after writing or modifying code.
            tools: Read, Grep, Glob, Bash
            model: inherit
            ---

            You are a senior code reviewer. Review all changes for:

            ## Checklist

            1. **Correctness** - Logic errors, off-by-ones, null/undefined access, race conditions
            2. **Security** - Injection, XSS, secrets in code, unsafe deserialization, path traversal
            3. **Performance** - N+1 queries, unnecessary allocations, missing indexes, blocking I/O
            4. **Style** - Consistent naming, no dead code, minimal comments, functional patterns
            5. **Nix-specific** - No `with pkgs;`, correct module placement, constants via config, no specialArgs

            ## Process

            1. Run `git diff` to see changes
            2. Read each modified file
            3. Report issues by priority: Critical > Warning > Suggestion
            4. Be specific: include file path and line number for each issue
          '';
        };

        context = ''
          # Lewis Flude

          ## Machines
          - Jupiter: NixOS desktop (x86_64-linux), RTX 4090, ZFS
          - Mercury: macOS laptop (aarch64-darwin)

          ## Primary Tools
          - Editor: Helix (hx)
          - Shell: ZSH (Atuin, Powerlevel10k)
          - Terminal: Zellij
          - Git: GPG-signed, lazygit, gh CLI
          - Envs: Nix flakes, devenv, direnv

          ## Languages
          Nix, TypeScript, Python, Go, Rust

          ## Conventions
          - Conventional commits: <type>(<scope>): <description>

          ## Interests
          - 3D art: Blender (Hair Tool, CharMorph plugins), character creation
          - NixOS configuration and system administration
        '';
      };

      home.packages =
        let
          llmAgentPkgs = pkgs.llmAgents or { };
        in
        lib.optionals (llmAgentPkgs ? ccusage) [ llmAgentPkgs.ccusage ]
        ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.claude-desktop ];
    };
}
