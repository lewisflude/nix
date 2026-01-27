{ username, ... }:
{
  system.activationScripts.backup.text = ''
    mkdir -p /Users/${username}/Backups/nix-config
    chown ${username}:staff /Users/${username}/Backups/nix-config
    chmod 755 /Users/${username}/Backups/nix-config
  '';
  # Disabled: backup.sh script not found and service failing with EX_CONFIG (78)
  # TODO: Re-enable if backup script is created
  # launchd.user.agents.nix-config-backup = {
  #   serviceConfig = {
  #     ProgramArguments = [
  #       "/Users/${username}/.config/nix/backup.sh"
  #     ];
  #     StartCalendarInterval = [
  #       {
  #         Hour = 12;
  #         Minute = 0;
  #         Weekday = 1;
  #       }
  #       {
  #         Hour = 12;
  #         Minute = 0;
  #         Weekday = 4;
  #       }
  #     ];
  #     StandardOutPath = "/Users/${username}/Library/Logs/nix-backup.log";
  #     StandardErrorPath = "/Users/${username}/Library/Logs/nix-backup-error.log";
  #   };
  # };
  launchd.user.agents.nix-config-git-backup = {
    serviceConfig = {
      ProgramArguments = [
        "/bin/bash"
        "-c"
        ''
          cd /Users/${username}/.config/nix
          if [[ -n "$(git status --porcelain)" ]]; then
            git add .
            # Disable GPG signing and skip hooks for automated backups
            git -c commit.gpgsign=false commit --no-verify -m "Auto-backup: $(date)"
            echo "Configuration changes committed at $(date)"
          fi
        ''
      ];
      StartCalendarInterval = [
        {
          Hour = 18;
          Minute = 0;
        }
      ];
      StandardOutPath = "/Users/${username}/Library/Logs/nix-git-backup.log";
      StandardErrorPath = "/Users/${username}/Library/Logs/nix-git-backup-error.log";
    };
  };
}
