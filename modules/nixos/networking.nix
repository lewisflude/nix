{ pkgs, configVars, ... }: {
  environment.systemPackages = with pkgs; [
    networkmanagerapplet
  ];


  networking = {
    hostName = configVars.hostname;
    enableIPv6 = true;
    networkmanager.enable = true;
    networkmanager.dns = "systemd-resolved";

    firewall = {
      enable = true;
      allowedTCPPorts = [
        # System services
        22    # SSH
        80    # HTTP
        443   # HTTPS
        
        # Email services
        21    # FTP
        25    # SMTP
        465   # SMTPS
        587   # SMTP submission
        
        # Media and entertainment
        8096  # Jellyfin media server
        5000  # Jellyfin DLNA
        8123  # Home Assistant
        6600  # MPD (Music Player Daemon)
        
        # Gaming services
        27015 # Steam
        27036 # Steam
        
        # Development and tools
        8080  # Common dev server
        9090  # Prometheus/dev tools
        5555  # ADB
        8095  # Atlassian tools
        3030  # Development servers
        7000  # Development/Jenkins
        11434 # Ollama AI
        
        # Torrent/P2P
        6969  # Torrent tracker
        6881  # BitTorrent
        7575  # Torrent client
        
        # Media streaming/casting
        8008  # Chromecast
        8009  # Chromecast
        1900  # UPnP
        2869  # UPnP
        554   # RTSP
        3689  # DAAP (iTunes)
        5228  # Google services
        
        # Remote access
        5900  # VNC
        3283  # Apple Remote Desktop
        47990 # Logitech
        
        # Application specific
        563   # NNTPS
        5353  # mDNS/Bonjour
        3456  # ITV
        5001  # Synology
        1188  # HP network scanning
        2875  # HP network printing
        2880  # HP network printing
        7100  # X11 forwarding range start
        8191  # Roon
        9696  # Prowlarr
        5055  # Overseerr
        5690  # Sabnzbd
        7878  # Radarr
        8989  # Sonarr
        8200  # Hashicorp Vault
        8686  # Lidarr
        8787  # Readarr
        8920  # Jellyseerr
        8888  # Jupyter/development
        5656  # Media server
        3001  # Development server
      ];


      allowedUDPPorts = [
        5353  # mDNS/Bonjour
        1900  # UPnP
        8008  # Chromecast
        8009  # Chromecast
        7000  # Development/Jenkins
        7100  # X11 forwarding
        554   # RTSP
        5000  # Jellyfin DLNA
        5001  # Synology
        123   # NTP
        5900  # VNC
        3283  # Apple Remote Desktop
      ];

      allowedUDPPortRanges = [
        { from = 6000; to = 7000; }      # Development/gaming
        { from = 16384; to = 16403; }    # WebRTC/media streaming
        { from = 47998; to = 48000; }    # Steam/gaming
        { from = 49152; to = 65535; }    # Ephemeral ports
      ];

      allowedTCPPortRanges = [
        { from = 49152; to = 65535; }    # Ephemeral ports
      ];

    };

  };

  services.resolved.enable = true;



  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  };

  services.dbus.packages = [ pkgs.avahi ];
}

