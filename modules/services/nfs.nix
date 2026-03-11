# NFS File Sharing
# Server: Export ~/Music from Jupiter for Ableton on Mercury
# Client: macOS autofs (on-demand mount at /Volumes/music)
{ config, ... }:
let
  jupiterIp = config.constants.hosts.jupiter.ipv4;
  mercuryIp = config.constants.hosts.mercury.ipv4;
  nfsOpts = "fstype=nfs,resvport,soft,intr,rsize=32768,wsize=32768,timeo=10,retrans=3";
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

  # macOS client: autofs on-demand NFS mount
  flake.modules.darwin.nfs = _: {
    environment.etc."auto_nfs".text = ''
      /Volumes/music -${nfsOpts} ${jupiterIp}:/home/${config.username}/Music
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
  };
}
