{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.host.features.restic;
  enabledBackups = lib.filterAttrs (_name: backupCfg: backupCfg.enable) cfg.backups;

  # Helper to convert simple systemd-style timer strings to launchd intervals
  # This is basic coverage for common cases
  getLaunchdInterval =
    timer:
    if timer == "daily" then
      {
        Hour = 0;
        Minute = 0;
      }
    else if timer == "weekly" then
      {
        Weekday = 0;
        Hour = 0;
        Minute = 0;
      }
    else if timer == "hourly" then
      { Minute = 0; }
    else
      # Default to daily if unknown
      {
        Hour = 0;
        Minute = 0;
      };

  mkBackupScript =
    name: backupCfg:
    pkgs.writeShellScript "restic-backup-${name}" ''
      export PATH=${lib.makeBinPath [ pkgs.restic ]}:$PATH
      export RESTIC_PASSWORD_FILE="${backupCfg.passwordFile}"
      export RESTIC_REPOSITORY="${backupCfg.repository}"

      echo "Starting backup: ${name}"
      echo "Repository: ${backupCfg.repository}"

      # Initialize if requested
      ${lib.optionalString backupCfg.initialize ''
        if ! restic snapshots > /dev/null 2>&1; then
          echo "Initializing repository..."
          restic init
        fi
      ''}

      # Perform backup
      restic backup "${backupCfg.path}" ${lib.concatStringsSep " " backupCfg.extraOptions}

      EXIT_CODE=$?

      if [ $EXIT_CODE -eq 0 ]; then
        echo "Backup ${name} completed successfully."

        # Prune old snapshots
        echo "Pruning old snapshots..."
        restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
      else
        echo "Backup ${name} failed with exit code $EXIT_CODE"
      fi

      exit $EXIT_CODE
    '';
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.restic ];

    launchd.user.agents = lib.mapAttrs' (name: backupCfg: {
      name = "restic-${name}";
      value = {
        serviceConfig = {
          ProgramArguments = [ "${mkBackupScript name backupCfg}" ];
          StartCalendarInterval = [ (getLaunchdInterval backupCfg.timer) ];
          StandardOutPath = "/Users/${config.host.username}/Library/Logs/restic-${name}.log";
          StandardErrorPath = "/Users/${config.host.username}/Library/Logs/restic-${name}-error.log";
          RunAtLoad = false;
          KeepAlive = false;
        };
      };
    }) enabledBackups;
  };
}
