{
  config,
  lib,
  constants,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    mkAfter
    ;
  inherit (lib.lists) optional;
  cfg = config.host.services.mediaManagement;
in
{
  options.host.services.mediaManagement.listenarr = {
    enable = mkEnableOption "Listenarr audiobook management" // {
      default = false;
    };

    publicUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Public URL for the Listenarr instance (optional, used by Discord bot)";
      example = "https://listenarr.example.com";
    };
  };

  config = mkIf (cfg.enable && cfg.listenarr.enable) {
    virtualisation.oci-containers.containers.listenarr = {
      image = "docker.io/therobbiedavis/listenarr:canary";
      environment = {
        TZ = cfg.timezone;
        PUID = toString config.users.users.${cfg.user}.uid;
        PGID = toString config.users.groups.${cfg.group}.gid;
      }
      // lib.optionalAttrs (cfg.listenarr.publicUrl != null) {
        LISTENARR_PUBLIC_URL = cfg.listenarr.publicUrl;
      };
      volumes = [ "/var/lib/listenarr:/app/config" ];
      ports = [ "${toString constants.ports.services.listenarr}:5000" ];
      extraOptions = [
        "--pull=newer"
        "--label=io.containers.autoupdate=registry"
      ];
    };

    # Ensure data directory exists with correct permissions
    systemd.tmpfiles.rules = [
      "d /var/lib/listenarr 0755 ${cfg.user} ${cfg.group} -"
    ];

    # Ensure Listenarr starts after Prowlarr
    systemd.services."podman-listenarr" = {
      after = mkAfter (optional cfg.prowlarr.enable "prowlarr.service");
      wantedBy = [ "multi-user.target" ];
    };

    # Open firewall port
    networking.firewall.allowedTCPPorts = [ constants.ports.services.listenarr ];
  };
}
