{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf;

  settings = import ./settings.nix { inherit pkgs; };
  extensions = import ./extensions.nix { inherit pkgs lib; };
  languageSettings = import ./language-settings.nix { };
  aiSettings = import ./ai-settings.nix { };

  allUserSettings = settings.userSettings // languageSettings.userSettings // aiSettings.userSettings;
in
{

  programs.vscode = {
    enable = true;
    package = pkgs.code-cursor;
    profiles.default = {
      userSettings = allUserSettings;
      extensions = extensions.extensions;
    };
  };
}
