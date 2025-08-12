{
  pkgs,
  lib,
  cursor,
  config,
  system,
  ...
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
    # Use cursor flake on Linux for proper Wayland/Niri support, nixpkgs on Darwin
    package = if pkgs.stdenv.isLinux 
      then cursor.packages.${pkgs.system}.default  # Cursor flake with Wayland support
      else pkgs.code-cursor;  # Standard nixpkgs cursor for macOS
    mutableExtensionsDir = false;
    profiles.default = {
      userSettings = lib.mkMerge [
        userSettings.userSettings
        languageSettings.userSettings
        aiSettings.userSettings
      ];
      extensions = extensions.extensions;
    };
  };
}