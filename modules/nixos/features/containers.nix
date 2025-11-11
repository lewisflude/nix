{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    mkDefault
    types
    ;
  cfg = config.host.features.containers;
in
{
  options.host.features.containers = {
    enable = mkEnableOption "container services";

    productivity = {
      enable = mkEnableOption "productivity stack";
      configPath = mkOption {
        type = types.str;
        default = "/var/lib/containers/productivity";
        description = "Path to store container configurations";
      };
    };
  };

  config = mkIf cfg.enable {

    host.services.containers = {
      enable = true;

      productivity = mkIf cfg.productivity.enable {
        enable = true;
        inherit (cfg.productivity) configPath;
      };

      timezone = mkDefault (config.time.timeZone or "Europe/London");
      uid = mkDefault 1000;
      gid = mkDefault 100;
    };

    host.features.virtualisation = {
      enable = true;
      podman = true;
    };
  };
}
