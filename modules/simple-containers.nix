# Simple OCI container services (single container, config dir, localhost port)
# Each entry: one container, one /var/lib/containers/supplemental/<name> volume
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.simpleContainers =
    _:
    let
      configPath = "/var/lib/containers/supplemental";
      inherit (constants.defaults) timezone;

      mkContainer =
        {
          name,
          image,
          port,
          containerPort,
          extraEnv ? { },
        }:
        {
          virtualisation.oci-containers.containers.${name} = {
            inherit image;
            environment = {
              TZ = timezone;
            }
            // extraEnv;
            volumes = [ "${configPath}/${name}:/config" ];
            ports = [ "127.0.0.1:${toString port}:${toString containerPort}" ];
          };
          systemd.tmpfiles.rules = [
            "d ${configPath}/${name} 0755 root root -"
          ];
        };
    in
    {
      imports = [
        # Pinned to digest of :latest as of 2026-04-30
        (mkContainer {
          name = "autopulse";
          image = "ghcr.io/dan-online/autopulse@sha256:383b63d25a30ea3945b23462aba0864094c3f76614854bce19edaca26a34b160";
          port = constants.ports.services.autopulse;
          containerPort = 2875;
          extraEnv = {
            AUTOPULSE__APP__DATABASE_URL = "sqlite:///app/config/autopulse.db?mode=rwc";
            AUTOPULSE__APP__LOG_LEVEL = "info";
          };
        })
      ];
    };
}
