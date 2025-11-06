{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.lists) optional optionals;
  cfg = config.host.features.audio;
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
      with pkgs;

      (optionals cfg.production [

        audacity
        helm
        lsp-plugins

      ])

      ++ (optionals audioNixCfg.enable (

        (optional audioNixCfg.bitwig bitwig-studio-stable-latest)

        ++ (optionals audioNixCfg.plugins [

          neuralnote
          paulxstretch

        ])
      ));

    users.users.${config.host.username}.extraGroups = optional cfg.enable "audio";
  };
}
