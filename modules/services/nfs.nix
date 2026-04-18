# NFS File Sharing
# Server: Export ~/Music from Jupiter for Ableton on Mercury
# Client: macOS launchd-managed NFS mount at /mnt/music
{ config, ... }:
let
  jupiterIp = config.constants.hosts.jupiter.ipv4;
  mercuryIp = config.constants.hosts.mercury.ipv4;
  musicPath = "/home/${config.username}/Music";
  # Direct mount target. macOS has a read-only root since Catalina, so physical
  # mount points must live under /System/Volumes/Data.
  mountPoint = "/System/Volumes/Data/mnt/music";
  mountOpts = "resvport,soft,bg,rsize=32768,wsize=32768,timeo=10,retrans=3";
in
{
  # NixOS server: NFS export
  flake.modules.nixos.nfs = _: {
    services.nfs.server = {
      enable = true;
      lockdPort = 4001;
      statdPort = 4002;
      exports = ''
        ${musicPath} ${mercuryIp}(rw,no_subtree_check,all_squash,anonuid=1001,anongid=100)
      '';
    };

    networking.firewall.allowedTCPPorts = [
      111
      2049
      4001
      4002
      20048
    ];
    networking.firewall.allowedUDPPorts = [
      111
      2049
      4001
      4002
      20048
    ];
  };

  # macOS client: direct NFS mount via launchd.
  # Avoids nix-darwin's inability to overwrite the OS-shipped /etc/auto_master
  # (environment.etc refuses to clobber pre-existing files), which previously
  # left autofs unarmed and the share unmounted.
  flake.modules.darwin.nfs =
    { pkgs, ... }:
    {
      launchd.daemons.mount-jupiter-music = {
        serviceConfig = {
          Label = "com.lewisflude.mount-jupiter-music";
          RunAtLoad = true;
          KeepAlive = {
            NetworkState = true;
          };
          StandardOutPath = "/var/log/mount-jupiter-music.log";
          StandardErrorPath = "/var/log/mount-jupiter-music.log";
        };
        script = ''
          set -eu
          ${pkgs.coreutils}/bin/mkdir -p ${mountPoint}
          if /sbin/mount | ${pkgs.gnugrep}/bin/grep -q " on ${mountPoint} "; then
            exit 0
          fi
          exec /sbin/mount_nfs -o ${mountOpts} ${jupiterIp}:${musicPath} ${mountPoint}
        '';
      };
    };

  # User-facing symlink so the share is reachable as ~/Music-Jupiter.
  flake.modules.homeManager.nfs =
    { config, ... }:
    {
      home.file."Music-Jupiter".source = config.lib.file.mkOutOfStoreSymlink mountPoint;
    };
}
