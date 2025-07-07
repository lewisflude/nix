{
  pkgs,
  config,
  username,
  ...
}:
let
  musicAssistantPort = 8095;
  musicAssistantStreamPort = 8097;
  dlnaPort = 8200;
  airplayPort = 7000;
  dlnaDiscoveryPort = 1900;
  upnpEventsPort = 2869;
  multicastDnsPort = 5353;
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
    dlnaPort
    upnpEventsPort
    dlnaDiscoveryPort
    multicastDnsPort
    airplayPort
  ];

  networking.firewall.allowedUDPPorts = [
    dlnaDiscoveryPort
    multicastDnsPort
    airplayPort
  ];
}
