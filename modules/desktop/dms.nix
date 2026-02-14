# DankMaterialShell Configuration
# Full desktop shell for niri with Material You theming
# Follows: https://danklinux.com/docs/dankmaterialshell/home-manager
{ inputs, ... }:
let
  # Patch DMS shell.qml to use GStreamer instead of FFmpeg for Qt Multimedia.
  # The FFmpeg resampler crashes with multichannel audio interfaces (Apogee Symphony Desktop).
  # DMS hardcodes `//@ pragma Env QT_MEDIA_BACKEND=ffmpeg` in shell.qml, so we must patch it.
  patchDmsShell =
    pkg:
    pkg.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        substituteInPlace $out/share/quickshell/dms/shell.qml \
          --replace-fail 'QT_MEDIA_BACKEND=ffmpeg' 'QT_MEDIA_BACKEND=gstreamer'
      '';
    });
in
{
  # NixOS system services required by DMS
  flake.modules.nixos.dms = {
    # AccountsService - DBus service for user account information
    # https://danklinux.com/docs/dankmaterialshell/cli-doctor#optional-features
    services.accounts-daemon.enable = true;

    # Fprintd - fingerprint authentication support
    # Adds fingerprint authentication to DMS lock screen
    # https://danklinux.com/docs/dankmaterialshell/cli-doctor#optional-features
    services.fprintd.enable = true;
  };
  flake.modules.homeManager.dms =
    { pkgs, lib, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      dmsPatchedShell = patchDmsShell inputs.dms.packages.${system}.default;
    in
    lib.mkIf pkgs.stdenv.isLinux {
      home.packages = [ pkgs.danksearch ];

      systemd.user.services.dms.Service.ExecStart = lib.mkForce (
        lib.getExe dmsPatchedShell + " run --session"
      );

      programs.dank-material-shell = {
        enable = true;

        # Use quickshell-git for full feature support (Polkit, IdleMonitor, etc.)
        # https://danklinux.com/docs/dankmaterialshell/cli-doctor#quickshell
        quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;

        settings.soundsEnabled = true;

        # Systemd service management
        # https://danklinux.com/docs/dankmaterialshell/home-manager#core-options
        # NOTE: Do not use both systemd.enable and niri.enableSpawn at the same time
        systemd = {
          enable = true;
          restartIfChanged = true;
        };

        # Niri compositor integration
        # https://danklinux.com/docs/dankmaterialshell/home-manager#niri-integration
        niri = {
          enableKeybinds = false; # Using includes.enable instead (manages binds via includes)
          enableSpawn = false; # Disabled because we use systemd.enable (only use one method)
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

        # Feature flags - all enabled per DMS docs
        # https://danklinux.com/docs/dankmaterialshell/home-manager#feature-flags
        enableSystemMonitoring = true;
        enableVPN = true;
        enableDynamicTheming = true;
        enableAudioWavelength = true;
        enableCalendarEvents = true;
        enableClipboardPaste = true;
      };
    };
}
