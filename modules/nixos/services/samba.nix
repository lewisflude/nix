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
