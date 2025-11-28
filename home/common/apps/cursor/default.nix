{
  pkgs,
  lib,
  ...
}:
let
  constants = import ./constants.nix { };
  userSettings = import ./settings.nix { inherit pkgs lib constants; };
  languageSettings = import ./language-settings.nix { inherit lib; };
  aiSettings = import ./ai-settings.nix { };
  extensions = import ./extensions.nix { inherit pkgs lib; };
in
{
  home.sessionVariables = {
    NODE_OPTIONS = "--max-old-space-size=4096";
  };
  programs.vscode = {
    enable = true;
    # Use cursor from nixpkgs (cross-platform)
    package = pkgs.cursor or pkgs.vscode;
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
