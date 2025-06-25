{ pkgs, lib, ... }:

let
  constants = import ./constants.nix { };
  userSettings = import ./settings.nix { inherit pkgs constants; };
  languageSettings = import ./language-settings.nix { inherit lib; };
  aiSettings = import ./ai-settings.nix { };
  extensions = import ./extensions.nix { inherit pkgs lib; };
  mcpConfig = import ./mcp-config.nix { };
in
{
  programs.vscode = {
    enable = true;
    package = pkgs.code-cursor;

    profiles.default = {
      userSettings = lib.mkMerge [
        userSettings.userSettings
        languageSettings.userSettings
        aiSettings.userSettings
      ];
      extensions = extensions.extensions;
    };
  };

  # Manage the MCP configuration file
  home.file.".cursor/mcp.json" = {
    text = builtins.toJSON {
      servers = mcpConfig.mcpServers;
    };
  };
}
