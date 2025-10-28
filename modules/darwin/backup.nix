{username, ...}: {
  system.activationScripts.backup.text = ''
    mkdir -p /Users/${username}/Backups/nix-config
    chown ${username}:staff /Users/${username}/Backups/nix-config
    chmod 755 /Users/${username}/Backups/nix-config
  '';
  launchd.user.agents.nix-config-backup = {
    serviceConfig = {
      ProgramArguments = [
        "/Users/${username}/.config/nix/backup.sh"
      ];
      StartCalendarInterval = [
        {
          Hour = 12;
          Minute = 0;
          Weekday = 1;
        }
        {
          Hour = 12;
          Minute = 0;
          Weekday = 4;
        }
      ];
      StandardOutPath = "/Users/${username}/Library/Logs/nix-backup.log";
      StandardErrorPath = "/Users/${username}/Library/Logs/nix-backup-error.log";
    };
  };
  launchd.user.agents.nix-config-git-backup = {
    serviceConfig = {
      ProgramArguments = [
        "/bin/bash"
        "-c"
        ''
          cd /Users/${username}/.config/nix
          if [[ -n "$(git status --porcelain)" ]]; then
            git add .
            git commit -m "Auto-backup: $(date)"
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
  # Time Machine exclusions for development directories
  system.defaults.CustomUserPreferences."com.apple.TimeMachine".SkipPaths = [
    "/Users/${username}/.cache"
    "/Users/${username}/.npm"
    "/Users/${username}/node_modules"
    "/Users/${username}/.cargo"
    "/Users/${username}/.rustup"
    "/Users/${username}/Library/Caches"
    # Additional development paths
    "/Users/${username}/.pnpm-store"
    "/Users/${username}/.yarn"
    "/Users/${username}/.gradle"
    "/Users/${username}/.m2"
    "/Users/${username}/go/pkg"
    "/Users/${username}/.docker"
  ];
}
