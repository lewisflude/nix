_: let
  musicAssistantPort = 8095;
  musicAssistantStreamPort = 8097;
  dlnaPort = 8200;
  airplayPort = 7000;
  dlnaDiscoveryPort = 1900;
  upnpEventsPort = 2869;
  multicastDnsPort = 5353;
in {
  virtualisation.oci-containers = {
    containers = {
      music-assistant-server = {
        # Pinned version for reproducibility (update manually when needed)
        image = "ghcr.io/music-assistant/server:2.3.7";

        environment = {
          LOG_LEVEL = "info";
          PUID = "1000";
          PGID = "100";
          UMASK = "022";
        };

        volumes = [
          "/var/lib/music-assistant:/data"
          "/mnt/storage/media/music:/mnt/storage/media/music"
        ];

        # Explicit port mappings instead of host network for better isolation
        ports = [
          "${toString musicAssistantPort}:${toString musicAssistantPort}" # Web UI
          "${toString musicAssistantStreamPort}:${toString musicAssistantStreamPort}" # Streaming
          "${toString dlnaPort}:${toString dlnaPort}" # DLNA
          "${toString airplayPort}:${toString airplayPort}" # AirPlay
          "${toString upnpEventsPort}:${toString upnpEventsPort}" # UPnP Events
        ];

        extraOptions = [
          # Use specific capabilities instead of --privileged for security
          "--cap-add=NET_ADMIN" # Required for network audio streaming
          "--cap-add=NET_RAW" # Required for multicast/DLNA discovery
          "--cap-add=NET_BIND_SERVICE" # Bind to privileged ports if needed

          # Allow access to audio devices if needed
          # Note: Uncomment if direct audio device access is required
          # "--device=/dev/snd:/dev/snd"
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
