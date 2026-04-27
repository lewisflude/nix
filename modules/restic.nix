# Restic Backup Service Module - Dendritic Pattern
# Backup solution with REST server
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.restic =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.restic ];

      # REST server for backup storage
      services.restic.server = {
        enable = true;
        listenAddress = "127.0.0.1:${toString constants.ports.services.restic}";
        extraFlags = [ "--no-auth" ];
      };

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
