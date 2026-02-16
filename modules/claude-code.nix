# Claude Code CLI configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.claudeCode
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.homeManager.claudeCode =
    { pkgs, ... }:
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
        };
      };

      programs.claude-code = {
        enable = true;
        package = pkgs.claude-code;
        enableMcpIntegration = true;

        commands = {
          review = ''
            Review code for bugs, best practices, performance, security, and maintainability.
            For Nix: check pkgs scope usage, module placement, constants usage, and commit format.
          '';
          commit = ''
            Generate conventional commit: <type>(<scope>): <description>
            Types: feat, fix, refactor, docs, test, chore, style, perf
            Use imperative mood, 50 chars max, focus on why not what.
          '';
          nix = ''
            Help with Nix following repo conventions:
            - Never use pkgs scope, use explicit pkgs.package
            - Follow dendritic pattern: all modules are flake-parts modules
            - Access constants via config.constants (not direct imports)
            - Format with nix fmt
          '';
          debug = ''
            Debug issues step-by-step: understand problem, gather info, identify cause, suggest fixes.
            For Nix: use nix flake check, nix eval --show-trace, nix build --dry-run
            For system: check journalctl -xe, home-manager logs, diagnostic scripts
          '';
          refactor = ''
            Suggest refactoring for clarity, maintainability, performance, and simplicity.
            For Nix: extract patterns, use feature flags, consolidate config, improve structure.
          '';
          doc = ''
            Generate documentation: overview, purpose, usage, parameters, examples, notes.
            For Nix modules: use mkOption with clear descriptions, types, defaults, examples.
          '';
          test = ''
            Generate test cases: happy path, edge cases, error handling, integration.
            For Nix: test with nix eval, nix build, integration tests, VM tests.
          '';
          explain = ''
            Explain code clearly: purpose, how it works, key concepts, dependencies, gotchas.
            Use plain language, provide analogies, break down complex logic.
          '';
        };

        settings = {
          editor.preferredEditor = "hx";
          fileFiltering = {
            respectGitIgnore = true;
            enableRecursiveFileSearch = true;
          };
          permissions = {
            allow = [
              "Read"
              "Edit"
              "Write"
              "WebFetch"
              "WebSearch"
              "Bash(git:*)"
              "Bash(gh:*)"
              "Bash(nix:*)"
              "Bash(nh:*)"
              "Bash(nix-env:*)"
              "Bash(npm:*)"
              "Bash(npx:*)"
              "Bash(node:*)"
              "Bash(cargo:*)"
              "Bash(rustc:*)"
              "Bash(rustup:*)"
              "Bash(go:*)"
              "Bash(python:*)"
              "Bash(python3:*)"
              "Bash(uv:*)"
              "Bash(pip:*)"
              "Bash(treefmt:*)"
              "Bash(nixfmt:*)"
              "Bash(biome:*)"
              "Bash(prettier:*)"
              "Bash(rg:*)"
              "Bash(fd:*)"
              "Bash(jq:*)"
              "Bash(bat:*)"
              "Bash(eza:*)"
              "Bash(ls:*)"
              "Bash(cat:*)"
              "Bash(head:*)"
              "Bash(tail:*)"
              "Bash(wc:*)"
              "Bash(mkdir:*)"
              "Bash(cp:*)"
              "Bash(mv:*)"
              "Bash(touch:*)"
              "Bash(curl:*)"
              "Bash(wget:*)"
              "Bash(make:*)"
              "Bash(cmake:*)"
              "Bash(docker ps:*)"
              "Bash(docker logs:*)"
              "Bash(docker inspect:*)"
              "Bash(docker images:*)"
              "Bash(podman ps:*)"
              "Bash(podman logs:*)"
              "Bash(podman inspect:*)"
              "Bash(podman images:*)"
              "Bash(hx:*)"
              "Bash(which:*)"
              "Bash(echo:*)"
              "Bash(printf:*)"
              "Bash(test:*)"
              "Bash([:*)"
              "Bash(direnv:*)"
              "Bash(devenv:*)"
              "Bash(stat:*)"
              "Bash(file:*)"
              "Bash(du:*)"
              "Bash(df:*)"
              "Bash(mdfind:*)"
            ];
            deny = [
              "Bash(sudo:*)"
              "Bash(rm:*)"
              "Bash(chmod:*)"
              "Bash(chown:*)"
              "Bash(nixos-rebuild:*)"
              "Bash(darwin-rebuild:*)"
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
            Stop = [
              {
                hooks = [
                  {
                    type = "command";
                    command = ''
                      INPUT=$(cat)
                      STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active')
                      if [ "$STOP_ACTIVE" = "true" ]; then
                        exit 0
                      fi
                      if [ -f flake.nix ]; then
                        if ! RESULT=$(nix flake check 2>&1); then
                          jq -n --arg reason "nix flake check failed: $RESULT" \
                            '{"decision": "block", "reason": $reason}'
                          exit 0
                        fi
                      fi
                      echo '{"decision": "allow"}'
                    '';
                    timeout = 120;
                  }
                ];
              }
            ];
          };
          session = {
            maxTurns = -1;
            saveHistory = true;
          };
          context = {
            loadProjectContext = true;
            contextFiles = [
              "CLAUDE.md"
              "CONVENTIONS.md"
              "README.md"
            ];
          };
          telemetry.enabled = false;
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

        memory.text = ''
          # Lewis Flude - Development Environment

          ## Machines
          - **Jupiter**: NixOS desktop workstation (x86_64-linux). NVIDIA RTX 4090, ZFS storage. Used for development, gaming, VR, audio production.
          - **Mercury**: macOS laptop (aarch64-darwin). Used for mobile development.

          ## Primary Tools
          - **Editor**: Helix (hx)
          - **Shell**: ZSH with Atuin history, Powerlevel10k prompt
          - **Terminal multiplexer**: Zellij
          - **Git**: GPG-signed commits, lazygit TUI, gh CLI
          - **Environments**: Nix flakes, devenv, direnv

          ## Languages (by frequency)
          - Nix (primary - this config repo)
          - TypeScript / JavaScript (biome formatter)
          - Python (ruff formatter, uv package manager)
          - Go (gofumpt formatter)
          - Rust (rustfmt formatter)

          ## Coding Style
          - Concise and minimal. No unnecessary abstraction.
          - Functional patterns over imperative loops.
          - Strong, explicit types. No any/unknown.
          - Self-documenting code. Only comment non-obvious logic.
          - Conventional commits: <type>(<scope>): <description>

          ## Nix Repository
          - Dendritic pattern: every .nix file is a flake-parts module
          - Never run system rebuild commands (no sudo, no nixos-rebuild, no darwin-rebuild)
          - Format with `nix fmt` (treefmt-nix with nixfmt, statix, deadnix, shfmt, prettier)
        '';
      };
    };
}
