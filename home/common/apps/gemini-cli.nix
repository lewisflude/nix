{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.gemini-cli;
in
{
  programs.gemini-cli = {
    enable = true;
    # Use the fixed version from overlay that has makeCacheWritable = true
    package = pkgs.gemini-cli;

    # Use "auto" model selection - gemini-cli will choose the best available model
    # You can override this with GEMINI_MODEL environment variable or --model flag
    defaultModel = "auto";

    # Custom commands for common workflows
    # Usage: Type the command name in the gemini-cli prompt (e.g., /review)
    commands = {
      # Code review command
      review = {
        description = "Review code for best practices, bugs, and improvements";
        prompt = ''
          Review the following code:

          {{args}}

          Provide:
          1. Potential bugs or issues
          2. Best practices violations
          3. Suggestions for improvement
          4. Performance considerations
          5. Security concerns
        '';
      };

      # Conventional commit message generator
      commit = {
        description = "Generate a conventional commit message";
        prompt = ''
          Generate a conventional commit message for these changes:

          {{args}}

          Follow the format: <type>(<scope>): <description>
          Types: feat, fix, refactor, docs, test, chore, style, perf
          Keep the message concise and descriptive.
          Focus on the "why" rather than the "what".
        '';
      };

      # Nix expression helper
      nix = {
        description = "Help with Nix expressions and configuration";
        prompt = ''
          Help with this Nix configuration:

          {{args}}

          Provide clear explanations and suggest improvements following Nix best practices.
          Consider:
          1. Correct module placement (system vs home-manager)
          2. Avoiding antipatterns (like using 'with' for package imports)
          3. Using constants where appropriate
          4. Following the repository's conventions
        '';
      };

      # Code explanation
      explain = {
        description = "Explain code in simple terms";
        prompt = ''
          Explain this code clearly and concisely:

          {{args}}

          Break down:
          1. What it does (high-level purpose)
          2. How it works (implementation details)
          3. Key concepts involved
          4. Any important gotchas or edge cases
        '';
      };

      # Refactoring suggestions
      refactor = {
        description = "Suggest refactoring improvements";
        prompt = ''
          Suggest refactoring improvements for:

          {{args}}

          Focus on:
          1. Code clarity and readability
          2. Maintainability
          3. Performance optimizations
          4. Best practices and patterns
          5. Potential simplifications
        '';
      };

      # Documentation generator
      doc = {
        description = "Generate documentation from code";
        prompt = ''
          Generate clear, comprehensive documentation for:

          {{args}}

          Include:
          1. Purpose and overview
          2. Parameters and return values
          3. Usage examples
          4. Important notes or warnings
        '';
      };

      # Debug helper
      debug = {
        description = "Help debug an issue";
        prompt = ''
          Help me debug this issue:

          {{args}}

          Provide:
          1. Potential root causes
          2. Debugging strategies
          3. Common pitfalls to check
          4. Suggested fixes with explanations
        '';
      };

      # Test generation
      test = {
        description = "Generate test cases for code";
        prompt = ''
          Generate comprehensive test cases for:

          {{args}}

          Include:
          1. Happy path tests
          2. Edge cases
          3. Error conditions
          4. Mock/fixture requirements
        '';
      };
    };

    # JSON settings for gemini-cli behavior
    # See: https://github.com/google-gemini/gemini-cli/blob/main/docs/user/configuration.md
    settings = {
      # Context file configuration
      # gemini-cli automatically loads GEMINI.md files hierarchically:
      # 1. ~/.gemini/GEMINI.md (global)
      # 2. Project root and ancestor directories
      # 3. Subdirectories (up to 200 dirs)
      # This means your project's GEMINI.md, CLAUDE.md, etc. are automatically
      # discovered without manual configuration!
      contextFileName = "GEMINI.md";

      # File filtering - respect .gitignore patterns
      # When true, git-ignored files (node_modules/, dist/, .env) are excluded
      # from @ commands and file discovery
      fileFiltering = {
        respectGitIgnore = true;
        enableRecursiveFileSearch = true;
      };

      # Tool configuration
      # Exclude dangerous commands for safety
      # Note: This is NOT a security mechanism - use sandbox for security
      excludeTools = [
        # Block dangerous shell commands
        "ShellTool(rm -rf)"
        "ShellTool(sudo rm)"
        "ShellTool(dd)"
        "ShellTool(mkfs)"
        # Block system rebuild commands (per repository rules)
        "ShellTool(nh os switch)"
        "ShellTool(nh os boot)"
        "ShellTool(sudo nixos-rebuild)"
        "ShellTool(sudo darwin-rebuild)"
      ];

      # Auto-accept safe read-only operations without confirmation
      # This speeds up workflow by not prompting for file reads, ls, etc.
      autoAccept = true;

      # UI Configuration
      theme = "Default"; # Options: "Default", "GitHub", etc.
      vimMode = false; # Set to true if you want vim keybindings
      hideTips = false; # Show helpful tips
      hideBanner = false; # Show ASCII art logo on startup

      # Editor for viewing diffs
      preferredEditor = "hx"; # Helix - terminal-native, fast, works everywhere

      # Sandbox configuration
      # IMPORTANT: Sandboxing is disabled by default
      # Enable with --sandbox flag or GEMINI_SANDBOX env var for dangerous operations
      # Uses Docker to isolate potentially unsafe operations
      sandbox = false; # Can be true, false, "docker", "podman", or custom command

      # Session limits
      # -1 means unlimited turns per session
      maxSessionTurns = -1;

      # Summarize long tool output to save tokens
      # This is useful for commands that produce verbose output
      summarizeToolOutput = {
        run_shell_command = {
          tokenBudget = 2000; # Max tokens for summarized output
        };
      };

      # Environment variable exclusion
      # Prevents project .env files from interfering with gemini-cli
      # Variables from .gemini/.env are never excluded
      excludedProjectEnvVars = [
        "DEBUG"
        "DEBUG_MODE"
        "NODE_ENV"
      ];

      # Telemetry configuration
      # Collects tool call names, API request metadata (no content/PII)
      # Helps improve the CLI
      telemetry = {
        enabled = false; # Set to true if you want to help improve gemini-cli
        target = "local"; # Options: "local", "gcp"
        otlpEndpoint = "http://localhost:4317";
        logPrompts = false; # Don't log prompt content for privacy
      };

      # Usage statistics (anonymized)
      # Collects tool names, API metadata - NO prompts, responses, or PII
      usageStatisticsEnabled = true; # Set to false to opt out

      # Checkpointing - save/restore conversation and file states
      # Useful for resuming complex sessions
      checkpointing = {
        enabled = true;
      };

      # Multi-directory support
      # Load GEMINI.md context files from all included directories
      # Useful if you work across multiple related projects
      loadMemoryFromIncludeDirectories = false;

      # Bug report URL (can customize if you have internal issue tracker)
      bugCommand = {
        urlTemplate = "https://github.com/google-gemini/gemini-cli/issues/new?template=bug_report.yml&title={title}&info={info}";
      };
    };

    # Note: Context files are automatically loaded by gemini-cli!
    # Your GEMINI.md, CLAUDE.md files in this repo will be automatically
    # discovered and loaded when you run gemini-cli from this directory.
    #
    # The hierarchical loading means:
    # - ~/.gemini/GEMINI.md provides global context
    # - This repo's GEMINI.md provides project-specific context
    # - Subdirectory GEMINI.md files provide component-specific context
    #
    # Use /memory show to see loaded context
    # Use /memory refresh to reload context files
  };

  # Force overwrite settings.json to handle backup file conflicts
  # Home Manager tries to back up settings.json to settings.json.backup,
  # but if that file already exists, it causes an error.
  # By managing settings.json manually with force=true, we allow Home Manager
  # to overwrite the existing backup file.
  home.file.".gemini/settings.json" = lib.mkIf cfg.enable {
    force = true; # Overwrite existing backup file if needed
    text = builtins.toJSON cfg.settings;
  };

  # Declaratively create the checkpoint directory to ensure it persists
  # across reboots. gemini-cli stores session data here.
  home.file.".gemini/tmp".source = pkgs.runCommand "gemini-tmp-dir" { } ''
    mkdir -p $out
  '';
}
