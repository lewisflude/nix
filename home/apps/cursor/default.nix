{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkIf
    mkMerge
    optional
    pathExists
    ;

  constants = import ./constants.nix { };
  coreSettings = import ./settings.nix { inherit pkgs constants; };
  languageSettings = import ./language-settings.nix { };
  aiSettings = import ./ai-settings.nix { };
  extensions = import ./extensions.nix { inherit pkgs lib; };

  userConfigPath = ./user-config.nix;
  userConfig =
    if pathExists userConfigPath then import userConfigPath { } else { userSettings = { }; };

  allUserSettings = mkMerge (
    [
      coreSettings.userSettings
      languageSettings.userSettings
      aiSettings.userSettings
    ]
    ++ optional (userConfig.userSettings != { }) userConfig.userSettings
  );
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
