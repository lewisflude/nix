# DankMaterialShell Configuration
# Full desktop shell for niri with Material You theming
# Follows: https://danklinux.com/docs/dankmaterialshell/nixos-flake
_: {
  flake.modules.homeManager.dms =
    { pkgs, lib, ... }:
    lib.mkIf pkgs.stdenv.isLinux {
      home.packages = [
        pkgs.danksearch
        pkgs.kdePackages.kimageformats
      ];

      programs.dank-material-shell = {
        enable = true;

        settings.soundsEnabled = false;

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
        enableDynamicTheming = true;
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
