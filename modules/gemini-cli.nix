# Antigravity CLI - Dendritic Pattern
# AI coding assistant via Google Antigravity
{
  config,
  inputs,
  ...
}:
let
  inherit (config) trustedDirs aiCli;
in
{
  # LLM agents (numtide/llm-agents.nix) - provides antigravity-cli + sibling agents.
  overlays.llm-agents =
    _final: prev:
    let
      llmAgentPkgs = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system} or { };
    in
    {
      llmAgents = llmAgentPkgs;
    }
    // (if llmAgentPkgs ? antigravity-cli then { inherit (llmAgentPkgs) antigravity-cli; } else { });

  flake.modules.homeManager.antigravityCli =
    {
      lib,
      pkgs,
      config,
      osConfig ? { },
      ...
    }:
    {
      programs.antigravity-cli = {
        enable = true;
        package = pkgs.antigravity-cli;
        enableMcpIntegration = true;
        defaultModel = "gemini-2.5-flash";
        settings = {
          model = "gemini-2.5-flash";
          temperature = 0.7;
          streaming = true;
        };
        commands = {
          commit = {
            description = "Generate a conventional commit message for the staged changes.";
            prompt = "Generate a conventional commit message for the staged changes.";
          };
          explain = {
            description = "Explain code clearly and concisely.";
            prompt = "Explain the following code clearly and concisely.";
          };
          review = {
            description = "Review code for bugs, best practices, and improvements.";
            prompt = "Review this code for bugs, best practices, and improvements.";
          };
          refactor = {
            description = "Suggest refactoring to improve clarity and maintainability.";
            prompt = "Suggest refactoring to improve clarity and maintainability.";
          };
          debug = {
            description = "Help debug code and suggest fixes.";
            prompt = "Help debug this code and suggest fixes.";
          };
          test = {
            description = "Generate test cases for code.";
            prompt = "Generate test cases for this code.";
          };
          nix-review = {
            description = "Review Nix code for best practices.";
            prompt = "Review this Nix code for best practices and improvements.";
          };
        };
      };

      programs.mcp = {
        enable = true;
        servers = aiCli.mcpServers pkgs osConfig;
      };

      # Environment variable for API key (loaded from SOPS)
      home.sessionVariables = lib.mkIf (aiCli.secretAvailable osConfig "GEMINI_API_KEY") {
        GEMINI_API_KEY_FILE = aiCli.secretPath osConfig "GEMINI_API_KEY";
      };

      programs.zsh.initContent = lib.mkIf config.programs.zsh.enable (
        lib.mkAfter (
          aiCli.mkTrustedWrapper {
            cmd = "antigravity";
            trustedFlag = "--dangerously-skip-permissions";
            inherit trustedDirs;
          }
        )
      );
    };
}
