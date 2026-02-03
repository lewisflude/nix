# Claude Code CLI configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.claudeCode
{ config, ... }:
{
  flake.modules.homeManager.claudeCode =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.claude-code = {
        enable = true;
        package = pkgs.claude-code;

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
          autoApprove = {
            readOperations = true;
            writeOperations = false;
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

        mcpServers =
          if config.services.mcp.enable or false then config.services.mcp._generatedServers or { } else { };
      };
    };
}
