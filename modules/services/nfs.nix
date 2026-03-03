# NFS File Sharing
# Server: Export ~/Music from Jupiter for Ableton on Mercury
# Client: Auto-mount via launchd (soft+intr = errors on timeout, no kernel hangs)
{ config, ... }:
let
  jupiterIp = config.constants.hosts.jupiter.ipv4;
  mercuryIp = config.constants.hosts.mercury.ipv4;
in
{
  # NixOS server: NFS export
  flake.modules.nixos.nfs =
    _:
    {
      services.nfs.server = {
        enable = true;
        exports = ''
          /home/${config.username}/Music ${mercuryIp}(rw,no_subtree_check,all_squash,anonuid=1001,anongid=100)
        '';
      };

      networking.firewall.allowedTCPPorts = [ 2049 ];
      networking.firewall.allowedUDPPorts = [ 2049 ];
    };

  # macOS client: keep music NFS mount active
  flake.modules.homeManager.nfs =
    { pkgs, lib, ... }:
    let
      inherit (pkgs.stdenv) isDarwin;
      mountMusic = pkgs.writeShellScript "mount-music-nfs" ''
        MOUNT_POINT="/Volumes/music"
        /bin/mkdir -p "$MOUNT_POINT"
        if ! /sbin/mount | /usr/bin/grep -q "$MOUNT_POINT"; then
          /sbin/mount -t nfs -o resvport,soft,intr,rsize=32768,wsize=32768,timeo=10,retrans=3 ${jupiterIp}:/home/${config.username}/Music "$MOUNT_POINT"
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
}
