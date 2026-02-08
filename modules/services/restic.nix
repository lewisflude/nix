# Restic Backup Service Module - Dendritic Pattern
# Backup solution with REST server
{ ... }:
{
  flake.modules.nixos.restic =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.restic ];

      # REST server for backup storage
      services.restic.server = {
        enable = true;
        listenAddress = "0.0.0.0:8000";
        extraFlags = [ "--no-auth" ];
      };

      networking.firewall.allowedTCPPorts = [ 8000 ];

      users.users.restic = {
        isSystemUser = true;
        group = "restic";
      };

      users.groups.restic = { };

      security.wrappers.restic = {
        source = "${pkgs.restic.out}/bin/restic";
        owner = "restic";
        group = "users";
        permissions = "u=rwx,g=,o=";
        capabilities = "cap_dac_read_search=+ep";
      };
    };
}
