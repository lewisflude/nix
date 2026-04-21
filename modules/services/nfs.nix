# NFS File Sharing
# Server: Export ~/Music from Jupiter for Ableton on Mercury
# Client: macOS launchd-managed NFS mount at /mnt/music
#
# Addressing: Both sides use Tailscale IPs so the mount is tied to the device
# identity rather than whichever physical NIC is primary on Mercury (Wi-Fi vs
# USB-C Ethernet dock give different LAN IPs, which caused mountd to refuse
# with "unmatched host").
{ config, ... }:
let
  jupiterIp = config.constants.hosts.jupiter.tailscaleIpv4;
  mercuryIp = config.constants.hosts.mercury.tailscaleIpv4;
  musicPath = "/home/${config.username}/Music";
  samplesPath = "${musicPath}/samples";
  # Direct mount targets. macOS has a read-only root since Catalina, so physical
  # mount points must live under /System/Volumes/Data.
  musicMount = "/System/Volumes/Data/mnt/music";
  samplesMount = "/System/Volumes/Data/mnt/samples";
  # noowners: macOS enforces file ownership client-side, so a mode-700 dir owned
  # by Jupiter's uid 1001 is unreadable by Mercury's uid 501 even though the
  # server-side export uses all_squash. noowners bypasses the local check; the
  # server still enforces access via the IP-pinned export.
  mountOpts = "resvport,soft,bg,rsize=32768,wsize=32768,timeo=10,retrans=3,noowners";
  exportOpts = "rw,no_subtree_check,all_squash,anonuid=1001,anongid=100";
in
{
  # NixOS server: NFS export
  flake.modules.nixos.nfs = _: {
    services.nfs.server = {
      enable = true;
      lockdPort = 4001;
      statdPort = 4002;
      exports = ''
        ${musicPath} ${mercuryIp}(${exportOpts})
        ${samplesPath} ${mercuryIp}(${exportOpts})
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
    let
      mkMountDaemon = name: source: target: {
        serviceConfig = {
          Label = "com.lewisflude.${name}";
          RunAtLoad = true;
          KeepAlive = {
            NetworkState = true;
            SuccessfulExit = false;
          };
          StandardOutPath = "/var/log/${name}.log";
          StandardErrorPath = "/var/log/${name}.log";
        };
        script = ''
          set -eu
          ${pkgs.coreutils}/bin/mkdir -p ${target}
          if /sbin/mount | ${pkgs.gnugrep}/bin/grep -q " on ${target} "; then
            exit 0
          fi
          exec /sbin/mount_nfs -o ${mountOpts} ${jupiterIp}:${source} ${target}
        '';
      };
    in
    {
      launchd.daemons.mount-jupiter-music = mkMountDaemon "mount-jupiter-music" musicPath musicMount;
      launchd.daemons.mount-jupiter-samples =
        mkMountDaemon "mount-jupiter-samples" samplesPath
          samplesMount;
    };

  # User-facing symlinks so the shares are reachable from $HOME.
  flake.modules.homeManager.nfs =
    { config, ... }:
    {
      home.file."Music-Jupiter".source = config.lib.file.mkOutOfStoreSymlink musicMount;
      home.file."Samples-Jupiter".source = config.lib.file.mkOutOfStoreSymlink samplesMount;
    };
}
