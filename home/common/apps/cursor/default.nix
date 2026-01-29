{
  pkgs,
  lib,
  ...
}:
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
        (import ./settings.nix { inherit pkgs lib; }).userSettings
        (import ./language-settings.nix { inherit lib; }).userSettings
      ];
      extensions = (import ./extensions.nix { inherit pkgs lib; }).extensions;
      keybindings = (import ./keybindings.nix { }).keybindings;
    };
  };
}
