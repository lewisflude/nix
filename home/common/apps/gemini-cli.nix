{ config, inputs, system, ... }:

{
  programs.gemini-cli = {
    enable = true;
    
    # Use specific package to avoid broken nixpkgs build
    package = inputs.llm-agents.packages.${system}.gemini-cli;

    commands = {
      review = {
        description = "Code review for bugs and best practices";
        prompt = "Review this code for bugs, best practices, and performance: {{args}}";
      };
      commit = {
        description = "Generate conventional commit message";
        prompt = "Generate a concise conventional commit (<type>: <desc>) for: {{args}}";
      };
      nix = {
        description = "Nix expression helper";
        prompt = "Review this Nix config for antipatterns and best practices: {{args}}";
      };
      explain = {
        description = "Explain code simply";
        prompt = "Explain what this code does and how it works: {{args}}";
      };
      refactor = {
        description = "Suggest refactoring";
        prompt = "Suggest refactorings for clarity and maintainability: {{args}}";
      };
      doc = {
        description = "Generate documentation";
        prompt = "Generate documentation (purpose, params, examples) for: {{args}}";
      };
      debug = {
        description = "Help debugging";
        prompt = "Analyze this issue and suggest root causes and fixes: {{args}}";
      };
      test = {
        description = "Generate test cases";
        prompt = "Generate happy path and edge case tests for: {{args}}";
      };
    };

    settings = {
      contextFileName = "GEMINI.md";
      autoAccept = true;
      preferredEditor = "hx";
      checkpointing.enabled = true;
      usageStatisticsEnabled = true;
      
      fileFiltering = {
        respectGitIgnore = true;
        enableRecursiveFileSearch = true;
      };

      summarizeToolOutput.run_shell_command.tokenBudget = 2000;

      # Privacy & Telemetry
      telemetry.enabled = false;
      excludedProjectEnvVars = [ "DEBUG" "DEBUG_MODE" "NODE_ENV" ];
    };
  };
}