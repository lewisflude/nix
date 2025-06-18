{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.programs.cursor;

  # Import component modules relative to this directory
  extensionsMod = import ./extensions.nix { inherit pkgs lib; };
  settingsMod = import ./settings.nix { };
  aiMod = import ./ai-settings.nix { };
  langMod = import ./language-settings.nix { };

  mergedSettings = lib.recursiveUpdate (lib.recursiveUpdate settingsMod.userSettings aiMod.userSettings) langMod.userSettings;

in
{
  options.programs.cursor = {
    enable = mkEnableOption "Enable the Cursor (VSCode fork) editor";
  };

  config = mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.code-cursor;
      userSettings = mergedSettings;
      extensions = extensionsMod.extensions;
      # default keybindings can remain in settingsMod
    };
  };
}
