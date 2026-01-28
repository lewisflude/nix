{
  pkgs,
  lib,
  ...
}:
let
  userSettings = import ./settings.nix { inherit pkgs lib; };
  languageSettings = import ./language-settings.nix { inherit lib; };
  extensions = import ./extensions.nix { inherit pkgs lib; };
  keybindings = import ./keybindings.nix { };
in
{
  home.sessionVariables = {
    NODE_OPTIONS = "--max-old-space-size=4096";
  };
  programs.vscode = {
    enable = true;
    package = pkgs.code-cursor;
    mutableExtensionsDir = false;
    profiles.default = {
      userSettings = lib.mkMerge [
        userSettings.userSettings
        languageSettings.userSettings
      ];
      inherit (extensions) extensions;
      inherit (keybindings) keybindings;
    };
  };
}
