{
  pkgs,
  config,
  username,
  ...
}:
let
  musicAssistantPort = 8095;
  musicAssistantStreamPort = 8097;
  sonosAppCtrlPort = 1400;
  dlnaPort = 8200;
  airplayPort = 7000;
in
{

  virtualisation.oci-containers = {
    containers = {
      music-assistant-server = {
        image = "ghcr.io/music-assistant/server:latest";

        environment = {
          LOG_LEVEL = "info";
        };

        volumes = [
          "/var/lib/music-assistant:/data"
          "/mnt/storage/media/music:/mnt/storage/media/music"
        ];

        extraOptions = [
          "--network=host"
          "--privileged"

        ];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/music-assistant 0755 root root -"
  ];

  networking.firewall.allowedTCPPorts = [
    musicAssistantPort
    musicAssistantStreamPort
    sonosAppCtrlPort
    dlnaPort
    airplayPort
  ];
}
