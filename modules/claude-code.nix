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
          permissions = {
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
              "Bash(nh *)"
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
            deny = [
              "Bash(sudo *)"
              "Bash(rm -rf *)"
              "Bash(chmod *)"
              "Bash(chown *)"
              "Bash(nixos-rebuild *)"
              "Bash(darwin-rebuild *)"
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
        };

        skills = {
          dendritic-pattern = ''
            ---
            description: Dendritic pattern guide for writing and modifying .nix flake-parts modules in this repository.
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
        '';
      };
    };
}
