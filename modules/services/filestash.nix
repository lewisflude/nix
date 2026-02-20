# Filestash - Web-based file manager with SMB backend
# Provides public web access to Samba shares for friends
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.filestash =
    _:
    let
      configPath = "/var/lib/containers/supplemental";
      inherit (constants.defaults) timezone;
    in
    {
      virtualisation.oci-containers.containers.filestash = {
        image = "docker.io/machines/filestash:latest";
        environment = {
          TZ = timezone;
          APPLICATION_URL = "https://files.${constants.baseDomain}";
        };
        volumes = [
          "${configPath}/filestash:/app/data/state"
        ];
        ports = [ "127.0.0.1:${toString constants.ports.services.filestash}:8334" ];
      };

      systemd.tmpfiles.rules = [
        "d ${configPath}/filestash 0755 root root -"
        "d ${configPath}/filestash/log 0755 root root -"
        "f ${configPath}/filestash/log/access.log 0644 root root -"
      ];
    };
}
