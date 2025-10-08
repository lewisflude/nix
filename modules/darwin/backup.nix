{
  pkgs,
  username,
  ...
}: {
  # System-level backup configuration
  environment.systemPackages = with pkgs; [
    rsync
    gnutar
    gzip
  ];

  # Create backup directories
  system.activationScripts.backup.text = ''
    mkdir -p /Users/${username}/Backups/nix-config
    chown ${username}:staff /Users/${username}/Backups/nix-config
    chmod 755 /Users/${username}/Backups/nix-config
  '';

  # LaunchAgent for automated backups
  launchd.user.agents.nix-config-backup = {
    serviceConfig = {
      ProgramArguments = [
        "/Users/${username}/.config/nix/backup.sh"
      ];
      StartCalendarInterval = [
        {
          Hour = 12;
          Minute = 0;
          Weekday = 1; # Monday
        }
        {
          Hour = 12;
          Minute = 0;
          Weekday = 4; # Thursday
        }
      ];
      StandardOutPath = "/Users/${username}/Library/Logs/nix-backup.log";
      StandardErrorPath = "/Users/${username}/Library/Logs/nix-backup-error.log";
    };
  };

  # Git auto-commit for configuration changes
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

  # Configure system backup exclusions for better performance
  system.defaults.CustomUserPreferences = {
    "com.apple.TimeMachine" = {
      DoNotOfferNewDisksForBackup = false; # Enable Time Machine prompts
      SkipPaths = [
        "/Users/${username}/.cache"
        "/Users/${username}/.npm"
        "/Users/${username}/node_modules"
        "/Users/${username}/.cargo"
        "/Users/${username}/.rustup"
        "/Users/${username}/Library/Caches"
      ];
    };
  };
}
