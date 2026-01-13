{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf optionalString concatMapStringsSep;
  cfg = config.host.features.bootOptimization;
in
{
  config = mkIf cfg.enable {
    systemd = {
      # Combine all systemd service definitions
      services =
        # Clear wantedBy for all delayed services so they don't start automatically
        (lib.listToAttrs (
          map (serviceName: {
            name = serviceName;
            value = {
              wantedBy = lib.mkForce [ ];
            };
          }) cfg.delayedServices
        ))
        // {
          # Create service to start delayed services after boot
          delayed-services = {
            description = "Start non-essential services after boot";
            script =
              let
                # Generate systemctl start commands only for services that are enabled
                startCommands = concatMapStringsSep "\n" (
                  serviceName:
                  optionalString config.systemd.services.${serviceName}.enable or false
                    "${pkgs.systemd}/bin/systemctl start ${serviceName}.service"
                ) cfg.delayedServices;
              in
              startCommands;
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
          };
        };

      # Timer to trigger delayed service startup
      timers.delayed-services = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "${toString cfg.delaySeconds}s";
          Unit = "delayed-services.service";
        };
      };
    };
  };
}
