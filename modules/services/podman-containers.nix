# Podman Containers Module - Dendritic Pattern
# OCI container services using Podman
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.podmanContainers =
    _:
    let
      configPath = "/var/lib/containers/supplemental";
      inherit (constants.defaults) timezone;
      uid = 1000;
      gid = 100;
    in
    {
      # Enable Podman
      virtualisation.podman = {
        enable = true;
        dockerSocket.enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };

      virtualisation.oci-containers.backend = "podman";

      # Homarr Dashboard
      virtualisation.oci-containers.containers.homarr = {
        image = "ghcr.io/ajnart/homarr:0.15.3";
        environment = {
          TZ = timezone;
        };
        volumes = [
          "${configPath}/homarr/configs:/app/data/configs"
          "${configPath}/homarr/icons:/app/public/icons"
          "${configPath}/homarr/data:/data"
        ];
        ports = [ "${toString constants.ports.services.homarr}:7575" ];
        extraOptions = [
          "--health-cmd=wget --no-verbose --tries=1 --spider http://localhost:7575/ || exit 1"
          "--health-interval=30s"
          "--health-timeout=10s"
          "--health-retries=3"
        ];
      };

      # Wizarr - Invitation management
      virtualisation.oci-containers.containers.wizarr = {
        image = "ghcr.io/wizarrrr/wizarr:4.1.1";
        environment = {
          TZ = timezone;
        };
        volumes = [
          "${configPath}/wizarr:/data/database"
        ];
        ports = [ "${toString constants.ports.services.wizarr}:5690" ];
      };

      # Termix - Terminal web UI
      virtualisation.oci-containers.containers.termix = {
        image = "ghcr.io/lukegus/termix:latest";
        environment = {
          TZ = timezone;
        };
        ports = [ "${toString constants.ports.services.termix}:8080" ];
      };

      # Janitorr - Media cleanup
      virtualisation.oci-containers.containers.janitorr = {
        image = "ghcr.io/schaka/janitorr:v1.3.0";
        environment = {
          TZ = timezone;
        };
        volumes = [
          "${configPath}/janitorr:/app/config"
        ];
        ports = [ "${toString constants.ports.services.janitorr}:8978" ];
      };

      # Profilarr - Profile management
      virtualisation.oci-containers.containers.profilarr = {
        image = "docker.io/santiagosayshey/profilarr:latest";
        environment = {
          TZ = timezone;
          PUID = toString uid;
          PGID = toString gid;
        };
        volumes = [
          "${configPath}/profilarr:/config"
        ];
        ports = [ "${toString constants.ports.services.profilarr}:6868" ];
      };

      # Listenarr - Music tracker
      virtualisation.oci-containers.containers.listenarr = {
        image = "ghcr.io/therobbiedavis/listenarr:canary";
        environment = {
          TZ = timezone;
          PUID = toString uid;
          PGID = toString gid;
        };
        volumes = [
          "${configPath}/listenarr:/config"
        ];
        ports = [ "${toString constants.ports.services.listenarr}:8686" ];
      };

      # Create config directories
      systemd.tmpfiles.rules = [
        "d ${configPath} 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/homarr 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/homarr/configs 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/homarr/icons 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/homarr/data 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/wizarr 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/janitorr 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/profilarr 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/listenarr 0755 ${toString uid} ${toString gid} -"
      ];

      # Firewall ports
      networking.firewall.allowedTCPPorts = [
        constants.ports.services.homarr
        constants.ports.services.wizarr
        constants.ports.services.termix
        constants.ports.services.janitorr
        constants.ports.services.profilarr
        constants.ports.services.listenarr
      ];

      # Enable automatic image pruning (nixpkgs provides podman-prune service)
      virtualisation.podman.autoPrune.enable = true;
    };
}
