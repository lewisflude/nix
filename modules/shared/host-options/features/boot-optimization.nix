# Boot Optimization Feature Options
{
  lib,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  bootOptimization = {
    enable = mkEnableOption "boot optimization with delayed service startup" // {
      default = false;
    };

    delayedServices = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        List of systemd services to delay starting until after boot completes.
        Services will have their wantedBy cleared and will be started by a timer.
        Useful for speeding up boot by deferring non-essential services.
      '';
      example = [
        "ollama"
        "open-webui"
      ];
    };

    delaySeconds = mkOption {
      type = types.int;
      default = 30;
      description = ''
        Number of seconds to wait after boot before starting delayed services.
      '';
      example = 60;
    };
  };
}
