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
  inherit (containersLib) mkResourceOptions mkResourceFlags mkHealthFlags;
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
      user = "${toString cfg.uid}:${toString cfg.gid}";
      environment = {
        TZ = cfg.timezone;
        PORT = toString termixCfg.port;
      };
      volumes = [
        "${cfg.configPath}/termix:/app/data"
      ];
      ports = [ "${toString termixCfg.port}:${toString termixCfg.port}" ];
      extraOptions =
        mkHealthFlags {
          cmd = "wget --no-verbose --tries=1 --spider http://localhost:${toString termixCfg.port}/ || exit 1";
          interval = "30s";
          timeout = "10s";
          retries = "3";
          startPeriod = "60s";
        }
        ++ mkResourceFlags termixCfg.resources;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.configPath}/termix 0755 ${toString cfg.uid} ${toString cfg.gid} -"
    ];
  };
}
