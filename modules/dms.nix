# DankMaterialShell Configuration
# Full desktop shell for niri with Material You theming
# Follows: https://danklinux.com/docs/dankmaterialshell/nixos-flake
{ inputs, ... }:
let
  # Bridge signal-nix -> DMS so the desktop shell (bar/launcher/notifications)
  # and niri colours match the signal-themed apps. We feed DMS a static custom
  # theme built from signal's resolved *dark* UI palette instead of letting it
  # generate its own Material You scheme from the wallpaper. Single scheme (no
  # light/dark split) locks DMS to the apps' dark build, so the Mod+Shift+T
  # toggle can't desync the desktop from the apps.
  sig = inputs.signal-nix.lib;
  ui = sig.makeUIColors (sig.getColors "dark");
  # Map signal UI roles -> the Material You keys DMS requires. Surface levels
  # ascend base(.15) < subtle(.20) < hover(.25) < divider(.30); primaryText is
  # dark for contrast against the light-ish accents (accent l~0.71).
  signalDmsTheme = {
    name = "Signal Dark";
    primary = ui."accent-primary".hex;
    primaryText = ui."surface-base".hex;
    primaryContainer = ui."accent-primary".hex;
    secondary = ui."accent-secondary".hex;
    surface = ui."surface-base".hex;
    surfaceText = ui."text-primary".hex;
    surfaceVariant = ui."surface-subtle".hex;
    surfaceVariantText = ui."text-secondary".hex;
    surfaceTint = ui."accent-primary".hex;
    background = ui."surface-base".hex;
    backgroundText = ui."text-primary".hex;
    outline = ui."divider-primary".hex;
    surfaceContainer = ui."surface-subtle".hex;
    surfaceContainerHigh = ui."surface-hover".hex;
    surfaceContainerHighest = ui."divider-primary".hex;
    error = ui.danger.hex;
    warning = ui.warning.hex;
    info = ui.info.hex;
    matugen_type = "scheme-tonal-spot";
  };
  signalDmsThemeJson = builtins.toJSON signalDmsTheme;
in
{
  # DankSearch — used by the home-manager DMS module below.
  overlays.danksearch =
    _final: prev:
    let
      pkgs = inputs.danksearch.packages.${prev.stdenv.hostPlatform.system} or null;
    in
    if pkgs != null then { danksearch = pkgs.default; } else { };

  flake.modules.homeManager.dms =
    { pkgs, lib, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      home.packages = [
        pkgs.danksearch
        pkgs.kdePackages.kimageformats
      ];

      programs.dank-material-shell = {
        enable = true;

        settings = {
          soundsEnabled = false;
          # Use the static signal-derived theme instead of wallpaper matugen.
          currentThemeName = "custom";
          customThemeFile = "${pkgs.writeText "signal-dms-theme.json" signalDmsThemeJson}";
        };

        systemd = {
          enable = true;
          restartIfChanged = true;
        };

        niri = {
          enableKeybinds = false;
          enableSpawn = false;
          includes = {
            enable = true;
            override = true;
            filesToInclude = [
              "alttab"
              "colors"
              "layout"
              "wpblur"
            ];
          };
        };

        enableSystemMonitoring = true;
        enableVPN = true;
        # Static theme (customThemeFile above) owns colours; no wallpaper matugen.
        enableDynamicTheming = false;
        enableAudioWavelength = true;
        enableCalendarEvents = true;
        enableClipboardPaste = true;

        plugins = {
          calculator.enable = true;
          emojiLauncher.enable = true;
          niriWindows.enable = true;
          screenshotToggle.enable = true;
          displayManager.enable = true;
          homeAssistantMonitor.enable = true;
          nixMonitor.enable = true;
          dankHooks.enable = true;
          dankLauncherKeys.enable = true;
          dankNotepadModule.enable = true;
          dankActions.enable = true;
        };
      };
    };
}
