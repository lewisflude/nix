{ pkgs, ... }:
{
  services = {
    samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "browseable" = "yes";
          "smb encrypt" = "required";

          # Performance optimizations for LAN transfers
          "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072";
          "read raw" = "yes";
          "write raw" = "yes";
          "max xmit" = "65535";
          "dead time" = "15";
          "getwd cache" = "yes";

          # SMB3 multi-channel for better throughput (if clients support it)
          "server multi channel support" = "yes";

          # Disable unnecessary features for pure file serving
          "dns proxy" = "no";
          "load printers" = "no";
          "printcap name" = "/dev/null";
          "disable spoolss" = "yes";

          # Async I/O for better performance
          "aio read size" = "16384";
          "aio write size" = "16384";
        };
        homes = {
          browseable = "no";
          "read only" = "no";
          "guest ok" = "no";
        };
        storage = {
          path = "/mnt/storage";
          writable = "true";
        };
      };
    };
    samba-wsdd = {
      enable = true;
      openFirewall = true;
    };
    avahi = {
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
      extraServiceFiles = {
        smb = ''
          <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
          <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
          <service-group>
            <name replace-wildcards="yes">%h</name>
            <service>
              <type>_smb._tcp</type>
              <port>445</port>
            </service>
          </service-group>
        '';
      };
    };
  };
  systemd.services.samba.path = [ pkgs.cifs-utils ];
}
