# Notifiarr - Discord/webhook notifications for arr events & health checks
# Monitors arr stack services and sends alerts via Discord/webhooks
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.notifiarr =
    _:
    let
      configPath = "/var/lib/containers/supplemental";
      inherit (constants.defaults) timezone;
    in
    {
      virtualisation.oci-containers.containers.notifiarr = {
        image = "ghcr.io/notifiarr/notifiarr:latest";
        environment = {
          TZ = timezone;
          DN_API_KEY = "CHANGE_ME";
        };
        volumes = [
          "${configPath}/notifiarr:/config"
        ];
        ports = [ "127.0.0.1:${toString constants.ports.services.notifiarr}:5454" ];
      };

      systemd.tmpfiles.rules = [
        "d ${configPath}/notifiarr 0755 root root -"
      ];
    };
}
