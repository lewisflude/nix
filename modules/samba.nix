# Samba File Sharing Service
# Server: SMB shares with optimized performance settings.
{ config, ... }:
let
  inherit (config) username;
  musicPath = "/home/${username}/Music";
in
{
  # NixOS server: SMB shares
  flake.modules.nixos.samba =
    { config, pkgs, ... }:
    {
      services = {
        samba = {
          enable = true;
          openFirewall = true;
          nmbd.enable = false;
          settings = {
            global = {
              "security" = "user";
              "smb encrypt" = "required";
              "server min protocol" = "SMB3_00";
              "server multi channel support" = "yes";
              "dns proxy" = "no";
              "load printers" = "no";
              "printcap name" = "/dev/null";
              "disable spoolss" = "yes";
              "aio read size" = "16384";
              "aio write size" = "16384";
              # macOS compatibility (fruit VFS). fruit:aapl enables the AAPL
              # SMB2 create context which collapses stat-per-file into the
              # directory listing for macOS clients (supersedes readdir_attr).
              "vfs objects" = "catia fruit streams_xattr";
              "fruit:aapl" = "yes";
              "fruit:nfs_aces" = "no";
              "fruit:copyfile" = "yes";
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
              path = musicPath;
              browseable = "yes";
              writable = "true";
              "valid users" = username;
              "force user" = username;
              "create mask" = "0664";
              "directory mask" = "0775";
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
      system.activationScripts.init-smbpasswd.text = ''
        set -euo pipefail

        secret=${config.sops.secrets."samba/lewisflude-password".path}
        if [ ! -f "$secret" ]; then
          echo "init-smbpasswd: secret $secret not present" >&2
          exit 1
        fi

        password=$(${pkgs.coreutils}/bin/tr -d '\r\n' < "$secret")
        if ${pkgs.samba}/bin/pdbedit -L \
            | ${pkgs.gnugrep}/bin/grep -q "^${username}:"; then
          printf '%s\n%s\n' "$password" "$password" \
            | ${pkgs.samba}/bin/smbpasswd -s ${username}
        else
          printf '%s\n%s\n' "$password" "$password" \
            | ${pkgs.samba}/bin/smbpasswd -sa ${username}
        fi
      '';
    };
}
