{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.lists) optional optionals;
  cfg = config.host.features.media.audio;
  audioNixCfg = cfg.audioNix;
in
{
  config = mkIf cfg.enable {

    musnix = {
      enable = true;

      kernel = mkIf cfg.realtime {
        realtime = true;
        packages = pkgs.linuxPackages-rt_latest;
      };
      rtirq.enable = cfg.realtime;
    };

    security.rtkit.enable = true;

    environment.systemPackages =
      (optionals cfg.production [
        pkgs.audacity
        pkgs.helm
        pkgs.lsp-plugins
      ])

      ++ (optionals audioNixCfg.enable (
        (optional audioNixCfg.bitwig pkgs.bitwig-studio-stable-latest)

        ++ (optionals audioNixCfg.plugins [
          pkgs.neuralnote
          pkgs.paulxstretch
        ])
      ));

    # Note: PipeWire uses a Polkit-like security model and does not require
    # users to be in the 'audio' group. This is only needed for legacy ALSA applications.
    # users.users.${config.host.username}.extraGroups = optional cfg.enable "audio";
  };
}
