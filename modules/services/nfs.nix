# NFS File Sharing
# Server: Export ~/Music from Jupiter for Ableton on Mercury
# Client: macOS autofs (on-demand mount at /mnt/music)
{ config, ... }:
let
  jupiterIp = config.constants.hosts.jupiter.ipv4;
  mercuryIp = config.constants.hosts.mercury.ipv4;
  nfsOpts = "fstype=nfs,resvport,soft,intr,bg,rsize=32768,wsize=32768,timeo=10,retrans=3";
in
{
  # NixOS server: NFS export
  flake.modules.nixos.nfs = _: {
    services.nfs.server = {
      enable = true;
      lockdPort = 4001;
      statdPort = 4002;
      exports = ''
        /home/${config.username}/Music ${mercuryIp}(rw,no_subtree_check,all_squash,anonuid=1001,anongid=100)
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

  # macOS client: autofs on-demand NFS mount under the data volume.
  # Modern macOS (Catalina+) has a read-only root, so autofs targets must live
  # under /System/Volumes/Data. User-facing access is via the ~/Music-Jupiter
  # symlink created by the home-manager module below.
  flake.modules.darwin.nfs = _: {
    environment.etc."auto_nfs".text = ''
      /System/Volumes/Data/mnt/music -${nfsOpts} ${jupiterIp}:/home/${config.username}/Music
    '';

    environment.etc."auto_master".text = ''
      #
      # Automounter master map
      #
      +auto_master
      /net			-hosts		-nobrowse,hidefromfinder,nosuid
      /home			auto_home	-nobrowse,hidefromfinder
      /Network/Servers	-fstab
      /-			-static
      /-			auto_nfs	-nobrowse,nosuid
    '';

    # Reload autofs at boot to pick up nix-darwin managed config
    launchd.daemons.reload-autofs = {
      serviceConfig = {
        Label = "org.nix.reload-autofs";
        ProgramArguments = [
          "/bin/sh"
          "-c"
          "automount -cv"
        ];
        RunAtLoad = true;
      };
    };
  };

  # User-facing symlink so the share is reachable as ~/Music-Jupiter.
  flake.modules.homeManager.nfs =
    { config, ... }:
    {
      home.file."Music-Jupiter".source =
        config.lib.file.mkOutOfStoreSymlink "/System/Volumes/Data/mnt/music";
    };
}
