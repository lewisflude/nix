{ username, ... }:
{
  system.activationScripts.backup.text = ''
    mkdir -p /Users/${username}/Backups/nix-config
    chown ${username}:staff /Users/${username}/Backups/nix-config
    chmod 755 /Users/${username}/Backups/nix-config
  '';

  launchd.user.agents.nix-config-git-backup = {
    serviceConfig = {
      ProgramArguments = [
        "/bin/bash"
        "-c"
        ''
          cd /Users/${username}/.config/nix
          if [[ -n "$(git status --porcelain)" ]]; then
            git add .
            git -c commit.gpgsign=false commit --no-verify -m "Auto-backup: $(date)"
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
