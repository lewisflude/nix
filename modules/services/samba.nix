# Samba File Sharing Service
# SMB shares with optimized performance settings
{ config, ... }:
{
  flake.modules.nixos.samba = { pkgs, lib, ... }: {
    services = {
      samba = {
        enable = true;
        openFirewall = true;
        settings = {
          global = {
            "browseable" = "yes";
            "smb encrypt" = "required";
            "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072";
            "read raw" = "yes";
            "write raw" = "yes";
            "max xmit" = "65535";
            "dead time" = "15";
            "getwd cache" = "yes";
            "server multi channel support" = "yes";
            "dns proxy" = "no";
            "load printers" = "no";
            "printcap name" = "/dev/null";
            "disable spoolss" = "yes";
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
            "valid users" = "@media";
            "force group" = "media";
            "create mask" = "0664";
            "directory mask" = "0775";
            "force create mode" = "0660";
            "force directory mode" = "0770";
            "case sensitive" = "auto";
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
  };
}
