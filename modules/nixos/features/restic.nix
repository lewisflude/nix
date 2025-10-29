{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.host.features.restic;
  enabledBackups =
    lib.filterAttrs (_name: backupCfg: backupCfg.enable) cfg.backups;
  backupsWithWrappers =
    lib.filterAttrs (_name: backupCfg: backupCfg.enable && backupCfg.createWrapper) cfg.backups;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.restic];

    services.restic.backups =
      lib.mapAttrs (
        _name: backupCfg: {
          inherit
            (backupCfg)
            path
            repository
            passwordFile
            user
            initialize
            createWrapper
            ;
          timerConfig.OnCalendar = backupCfg.timer;
          inherit (backupCfg) extraOptions;
        }
      )
      enabledBackups;

    services.restic.server = lib.mkIf cfg.restServer.enable {
      enable = true;
      listenAddress = "0.0.0.0:${toString cfg.restServer.port}";
      extraFlags =
        cfg.restServer.extraFlags
        ++ (
          if cfg.restServer.htpasswdFile != null
          then ["--htpasswd-file ${cfg.restServer.htpasswdFile}"]
          else ["--no-auth"]
        );
    };

    # Security wrapper for restic
    users.users.restic = lib.mkIf (backupsWithWrappers != {}) {
      isNormalUser = true;
    };

    security.wrappers.restic = lib.mkIf (backupsWithWrappers != {}) {
      source = "${pkgs.restic.out}/bin/restic";
      owner = "restic";
      group = "users";
      permissions = "u=rwx,g=,o=";
      capabilities = "cap_dac_read_search=+ep";
    };

    # Override restic package for backups that use the wrapper
    # This part needs to be handled carefully, as it's per-backup job
    # and not a global override.
    # The user's example shows how to do this within the backup job definition.
    # services.restic.backups.<name>.package = pkgs.writeShellScriptBin "restic" ''exec /run/wrappers/bin/restic "$@"'';
  };
}
