# Restic Aspect
#
# Combines all Restic backup configuration in a single file.
# Reads options from config.host.features.restic (defined in modules/shared/host-options/features/restic.nix)
#
# Platform support:
# - NixOS: systemd-based restic backups, REST server (implemented here)
# - Darwin: launchd-based restic backups (implemented in modules/darwin/restic.nix)
#
# Note: Darwin-specific launchd configuration must remain in modules/darwin/restic.nix
# because the launchd option doesn't exist in the NixOS module system.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    filterAttrs
    mapAttrs
    ;
  cfg = config.host.features.restic;
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;

  enabledBackups = filterAttrs (_name: backupCfg: backupCfg.enable) cfg.backups;
  backupsWithWrappers = filterAttrs (
    _name: backupCfg: backupCfg.enable && backupCfg.createWrapper
  ) cfg.backups;
in
{
  config = mkMerge [
    # ================================================================
    # NixOS Configuration
    # ================================================================
    (mkIf (cfg.enable && isLinux) {
      environment.systemPackages = [ pkgs.restic ];

      services.restic.backups = mapAttrs (_name: backupCfg: {
        inherit (backupCfg)
          path
          repository
          passwordFile
          user
          initialize
          createWrapper
          ;
        timerConfig.OnCalendar = backupCfg.timer;
        inherit (backupCfg) extraOptions;
      }) enabledBackups;

      services.restic.server = mkIf cfg.restServer.enable {
        enable = true;
        listenAddress = "0.0.0.0:${toString cfg.restServer.port}";
        extraFlags =
          cfg.restServer.extraFlags
          ++ (
            if cfg.restServer.htpasswdFile != null then
              [ "--htpasswd-file ${cfg.restServer.htpasswdFile}" ]
            else
              [ "--no-auth" ]
          );
      };

      # Open firewall port for REST server
      networking.firewall.allowedTCPPorts = mkIf cfg.restServer.enable [ cfg.restServer.port ];

      users.users.restic = mkIf (backupsWithWrappers != { }) {
        isNormalUser = true;
      };

      security.wrappers.restic = mkIf (backupsWithWrappers != { }) {
        source = "${pkgs.restic.out}/bin/restic";
        owner = "restic";
        group = "users";
        permissions = "u=rwx,g=,o=";
        capabilities = "cap_dac_read_search=+ep";
      };
    })

    # ================================================================
    # Darwin Configuration
    # ================================================================
    # Note: Darwin launchd configuration is in modules/darwin/restic.nix
    # because launchd options don't exist in the NixOS module system
    (mkIf (cfg.enable && isDarwin) {
      environment.systemPackages = [ pkgs.restic ];
    })

    # ================================================================
    # Assertions (both platforms)
    # ================================================================
    {
      assertions = [
        {
          assertion = !(cfg.restServer.enable && isDarwin);
          message = "Restic REST server is not supported on macOS (requires systemd)";
        }
      ];
    }
  ];
}
