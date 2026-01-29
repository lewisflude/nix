{
  pkgs,
  inputs,
  config,
  ...
}:
{
  # Claude Code CLI - agentic coding assistant
  # Uses llm-agents.nix for daily updates and pre-built binaries
  # MCP servers configured in home/{nixos,darwin}/mcp.nix
  #
  # TEMPORARILY DISABLED: Waiting for upstream fix for apple_sdk_11_0 deprecation
  # See: https://github.com/NixOS/nixpkgs/issues/

  programs.claude-code = {
    enable = true;

    # Use llm-agents.nix for daily updates and pre-built binaries from Numtide cache
    # This provides better maintenance and faster builds than claude-code-nix
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;

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
        - System modules in modules/nixos/, home-manager in home/common/apps/
        - Use constants from lib/constants.nix
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


    # JSON settings for Claude Code
    # See: https://docs.anthropic.com/claude-code/reference/settings
    settings = {
      # Editor configuration
      editor = {
        preferredEditor = "hx"; # Helix - terminal-native, fast
      };

      # File filtering
      fileFiltering = {
        respectGitIgnore = true; # Exclude git-ignored files
        enableRecursiveFileSearch = true; # Search subdirectories
      };

      # Auto-approve safe read-only operations
      autoApprove = {
        readOperations = true; # Auto-approve file reads, ls, grep
        writeOperations = false; # Always prompt for writes
      };

      # Session configuration
      session = {
        maxTurns = -1; # Unlimited turns (-1)
        saveHistory = true; # Save conversation history
      };

      # Memory/Context configuration
      # Claude Code automatically loads CLAUDE.md from the repository
      # You can create .claude/ directory for additional context
      context = {
        loadProjectContext = true; # Load CLAUDE.md automatically
        contextFiles = [
          "CLAUDE.md"
          "CONVENTIONS.md"
          "README.md"
        ]; # Files to load as context
      };

      # Telemetry (optional)
      telemetry = {
        enabled = false; # Disable telemetry for privacy
      };
    };

    # MCP servers configuration
    # This will be populated by the mcp.nix module via the services.mcp interface
    # Servers are enabled/disabled in home/{nixos,darwin}/mcp.nix
    mcpServers =
      if config.services.mcp.enable or false then config.services.mcp._generatedServers or { } else { };
  };
}
