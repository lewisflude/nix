# Gemini CLI - Dendritic Pattern
# AI coding assistant via Google Gemini
{ inputs, ... }:
{
  # LLM agents (numtide/llm-agents.nix) — provides gemini-cli + sibling agents.
  overlays.llm-agents =
    _final: prev:
    let
      llmAgentPkgs = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system} or { };
    in
    {
      llmAgents = llmAgentPkgs;
    }
    // (if llmAgentPkgs ? gemini-cli then { inherit (llmAgentPkgs) gemini-cli; } else { });

  flake.modules.homeManager.geminiCli =
    {
      lib,
      pkgs,
      osConfig ? { },
      ...
    }:
    let
      # Secret helper
      secretAvailable =
        name: osConfig ? sops && osConfig.sops ? secrets && osConfig.sops.secrets ? ${name};
      secretPath = name: if secretAvailable name then osConfig.sops.secrets.${name}.path else "";

      # Command configurations
      commands = {
        commit = {
          model = "gemini-2.0-flash-exp";
          prompt = "Generate a conventional commit message for the staged changes.";
        };
        explain = {
          model = "gemini-2.0-flash-exp";
          prompt = "Explain the following code clearly and concisely.";
        };
        review = {
          model = "gemini-2.0-flash-exp";
          prompt = "Review this code for bugs, best practices, and improvements.";
        };
        refactor = {
          model = "gemini-2.0-flash-exp";
          prompt = "Suggest refactoring to improve clarity and maintainability.";
        };
        debug = {
          model = "gemini-2.0-flash-exp";
          prompt = "Help debug this code and suggest fixes.";
        };
        test = {
          model = "gemini-2.0-flash-exp";
          prompt = "Generate test cases for this code.";
        };
        "nix-review" = {
          model = "gemini-2.0-flash-exp";
          prompt = "Review this Nix code for best practices and improvements.";
        };
      };

      # Generate command config files
      mkCommandConfig = name: cmdConfig: {
        name = ".gemini/command-${name}.toml";
        value = {
          text = ''
            model = "${cmdConfig.model}"
            prompt = """
            ${cmdConfig.prompt}
            """
          '';
        };
      };
    in
    {
      programs.gemini-cli = {
        enable = true;
        package = pkgs.gemini-cli;
        settings = {
          model = "gemini-2.0-flash-exp";
          temperature = 0.7;
          streaming = true;
        };
      };

      # Command configurations
      home.file = lib.listToAttrs (lib.mapAttrsToList mkCommandConfig commands);

      # Environment variable for API key (loaded from SOPS)
      home.sessionVariables = lib.mkIf (secretAvailable "GEMINI_API_KEY") {
        GEMINI_API_KEY_FILE = secretPath "GEMINI_API_KEY";
      };
    };
}
