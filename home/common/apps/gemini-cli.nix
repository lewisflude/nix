{ inputs, system, ... }:

{
  programs.gemini-cli = {
    enable = true;

    # Use the daily-updated package from the Numtide flake
    package = inputs.llm-agents.packages.${system}.gemini-cli;

    # Set the default model (Pro is best for complex coding/Nix logic)
    defaultModel = "gemini-1.5-pro";

    # 1. Global Context Management
    # These files are created in ~/.gemini/ and provided to the AI every session.
    context = {
      GEMINI = ''
        # Identity & Environment
        You are an expert software engineer specializing in NixOS and functional programming.
        Terminal Editor: Helix (hx)
        OS: NixOS

        # Style Guidelines
        - Provide concise, modular code.
        - Prefer declarative Nix expressions over imperative scripts.
        - Use Conventional Commits format for git messages.
      '';

      HELIX = ''
        # Helix Editor Context
        When I ask for code edits:
        - Provide the full file content or clearly marked blocks I can copy.
        - Since I use Helix, I don't have a GUI 'Apply' button; clear diffs are appreciated.
      '';
    };

    # 2. Custom Command Suite
    # Accessible via /command_name in the CLI
    commands = {
      # Nix-specific workflow
      "nix/review" = {
        description = "Review Nix code for antipatterns";
        prompt = "Analyze this Nix expression for best practices, safety, and 'Nix-y' patterns: {{args}}";
      };

      # Development workflow
      commit = {
        description = "Generate a conventional commit message";
        prompt = "Generate a concise conventional commit message (<type>: <description>) based on these changes: {{args}}";
      };
      review = {
        description = "Code review for bugs and performance";
        prompt = "Review this code for bugs, logic errors, and performance bottlenecks: {{args}}";
      };
      explain = {
        description = "Simple explanation of complex code";
        prompt = "Explain how this code works to a senior engineer, focusing on the 'why' and architectural impact: {{args}}";
      };
      refactor = {
        description = "Suggest maintainability improvements";
        prompt = "Suggest refactors to make this code more readable and maintainable without changing behavior: {{args}}";
      };
      test = {
        description = "Generate unit tests and edge cases";
        prompt = "Write comprehensive test cases including 'happy path' and edge cases for: {{args}}";
      };
      debug = {
        description = "Root cause analysis for errors";
        prompt = "I am seeing this error. Analyze the code and the error to suggest a root cause and a fix: {{args}}";
      };
    };

    # 3. Settings (Structured for the latest JSON schema)
    settings = {
      # Authentication for Company Accounts
      security.auth = {
        selectedType = "oauth-personal";
      };

      general = {
        preferredEditor = "hx";
        vimMode = true; # Enables vim-style navigation in the prompt
        checkpointing.enabled = true; # Allows /restore to recover sessions
        previewFeatures = true;
      };

      ui = {
        theme = "Default"; # Or "GitHub", "Terminal", "Monokai"
        showLineNumbers = true;
        showCitations = true;
        hideFooter = false;
        useFullWidth = true;
      };

      tools = {
        autoAccept = true; # Automatically run 'safe' tools like file-reads
        summarizeToolOutput.run_shell_command.tokenBudget = 2500;
      };

      fileFiltering = {
        respectGitIgnore = true;
        enableRecursiveFileSearch = true;
      };

      # Privacy & Telemetry
      privacy = {
        usageStatisticsEnabled = false;
        telemetry.enabled = false;
      };

      excludedProjectEnvVars = [
        "DEBUG"
        "DEBUG_MODE"
        "NODE_ENV"
        "SECRET_KEY"
      ];
    };
  };
}
