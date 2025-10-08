{ pkgs
, lib
, ...
}:
let
  constants = import ./constants.nix { };
  userSettings = import ./settings.nix { inherit pkgs constants; };
  languageSettings = import ./language-settings.nix { inherit lib; };
  aiSettings = import ./ai-settings.nix { };
  extensions = import ./extensions.nix { inherit pkgs lib; };
in
{
  # Essential crash prevention through environment
  home.sessionVariables = {
    NODE_OPTIONS = "--max-old-space-size=4096"; # Prevent JS memory crashes
  };

  programs.vscode = {
    enable = true;
    package = pkgs.cursor.cursor or pkgs.vscode;
    mutableExtensionsDir = false;
    profiles.default = {
      userSettings = lib.mkMerge [
        userSettings.userSettings
        languageSettings.userSettings
        aiSettings.userSettings
      ];
      inherit (extensions) extensions;
    };
  };
}
