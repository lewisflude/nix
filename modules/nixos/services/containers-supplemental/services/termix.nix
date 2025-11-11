{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  containersLib = import ../lib.nix { inherit lib; };
  inherit (containersLib) mkResourceOptions mkResourceFlags;
  cfg = config.host.services.containersSupplemental;
  termixCfg = cfg.termix;
in
{
  options.host.services.containersSupplemental.termix = {
    enable = mkEnableOption "Termix SSH server management platform" // {
      default = false;
    };

    port = mkOption {
      type = types.int;
      default = 8080;
      description = "Port to expose Termix on";
    };

    resources = mkResourceOptions {
      memory = "512m";
      cpus = "0.5";
    };
  };

  config = mkIf (cfg.enable && termixCfg.enable) {
    virtualisation.oci-containers.containers.termix = {
      image = "ghcr.io/lukegus/termix:latest";
      # Run as root - container needs to write to /etc/nginx/nginx.conf.tmp
      environment = {
        TZ = cfg.timezone;
        PORT = toString termixCfg.port;
      };
      volumes = [
        "${cfg.configPath}/termix:/app/data"
      ];
      ports = [ "${toString termixCfg.port}:${toString termixCfg.port}" ];
      extraOptions =
        # Removed healthcheck - causes false positives during startup, service works without it
        mkResourceFlags termixCfg.resources;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.configPath}/termix 0755 ${toString cfg.uid} ${toString cfg.gid} -"
    ];
  };
}
