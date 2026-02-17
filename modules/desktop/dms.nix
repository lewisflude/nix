# DankMaterialShell Configuration
# Full desktop shell for niri with Material You theming
# Follows: https://danklinux.com/docs/dankmaterialshell/nixos-flake
_: {
  # NixOS system services required by DMS
  flake.modules.nixos.dms =
    { pkgs, ... }:
    {
      services.accounts-daemon.enable = true;
      services.fprintd.enable = true;
      services.printing.enable = true;
      environment.systemPackages = [ pkgs.cups-pk-helper ];
    };

  flake.modules.homeManager.dms =
    { pkgs, lib, ... }:
    lib.mkIf pkgs.stdenv.isLinux {
      home.packages = [
        pkgs.danksearch
        pkgs.kdePackages.kimageformats
      ];

      # Use GStreamer media backend instead of FFmpeg to avoid SIGSEGV when
      # swresample encounters the Symphony Desktop's 10-channel layout
      # (FL+FR+FC+LFE+BL+BR+FLC+FRC+BC+SL) which it doesn't support.
      # GStreamer handles channel mapping correctly via PipeWire.
      systemd.user.services.dms.Service.Environment = [ "QT_MEDIA_BACKEND=gstreamer" ];

      programs.dank-material-shell = {
        enable = true;

        settings.soundsEnabled = true;

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
              "binds"
              "colors"
              "layout"
              "outputs"
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
