# Samba File Sharing Service
# Server: SMB shares with optimized performance settings
# Client: Auto-mount music share on macOS via launchd
{ config, ... }:
{
  # macOS client: keep music share mounted
  flake.modules.homeManager.samba =
    { pkgs, lib, ... }:
    let
      inherit (pkgs.stdenv) isDarwin;
      jupiterIp = config.constants.hosts.jupiter.ipv4;
      mountMusic = pkgs.writeShellScript "mount-music" ''
        MOUNT_POINT="/Volumes/music"
        if ! /sbin/mount | /usr/bin/grep -q "$MOUNT_POINT"; then
          /usr/bin/osascript -e "mount volume \"smb://${jupiterIp}/music\""
        fi
      '';
    in
    {
      launchd.agents.mount-music = lib.mkIf isDarwin {
        enable = true;
        config = {
          ProgramArguments = [ "${mountMusic}" ];
          StartInterval = 60;
          RunAtLoad = true;
          StandardOutPath = "/tmp/mount-music.log";
          StandardErrorPath = "/tmp/mount-music.err";
        };
      };
    };

  # NixOS server: SMB shares
  flake.modules.nixos.samba =
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
              # macOS compatibility (fruit VFS)
              "vfs objects" = "catia fruit streams_xattr";
              "fruit:aapl" = "yes";
              "fruit:metadata" = "stream";
              "fruit:model" = "MacSamba";
              "fruit:posix_rename" = "yes";
              "fruit:veto_appledouble" = "no";
              "fruit:wipe_intentionally_left_blank_rfork" = "yes";
              "fruit:delete_empty_adfiles" = "yes";
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
            music = {
              path = "/home/${config.username}/Music";
              writable = "true";
              "valid users" = config.username;
              "create mask" = "0644";
              "directory mask" = "0755";
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
