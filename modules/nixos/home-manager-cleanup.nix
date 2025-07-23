{
  username,
  lib,
  pkgs,
  ...
}:
{
  # System activation script to clean up Home Manager backup files
  # This prevents conflicts where backup files already exist and Home Manager can't create new ones

  system.activationScripts.home-manager-backup-cleanup = {
    text = ''
      echo "🧹 Cleaning up Home Manager backup files..."

      # Define user home directory
      USER_HOME="/home/${username}"

      # Only proceed if user home exists and is accessible
      if [ ! -d "$USER_HOME" ]; then
        echo "  Warning: User home directory $USER_HOME not found, skipping cleanup"
        exit 0
      fi

      # Function to safely clean backup files in a directory
      cleanup_backup_files() {
        local dir="$1"
        local desc="$2"

        if [ -d "$dir" ]; then
          echo "  Cleaning $desc backup files..."

          # Remove current conflict files (backup extensions)
          ${pkgs.findutils}/bin/find "$dir" -name "*.backup" -type f -print0 2>/dev/null | \
            ${pkgs.coreutils}/bin/xargs -0 -r rm -f 2>/dev/null || true

          ${pkgs.findutils}/bin/find "$dir" -name "*.bak" -type f -print0 2>/dev/null | \
            ${pkgs.coreutils}/bin/xargs -0 -r rm -f 2>/dev/null || true

          # Clean up old backup files (older than 3 days) to prevent accumulation
          ${pkgs.findutils}/bin/find "$dir" -name "*.backup.*" -type f -mtime +3 -print0 2>/dev/null | \
            ${pkgs.coreutils}/bin/xargs -0 -r rm -f 2>/dev/null || true
        fi
      }

      # Clean up Firefox backup files (most common conflict source)
      cleanup_backup_files "$USER_HOME/.mozilla/firefox" "Firefox"

      # Clean up other common Home Manager managed directories
      cleanup_backup_files "$USER_HOME/.config" "config"
      cleanup_backup_files "$USER_HOME/.local/share" "local data"

      # Clean up any backup files in the user's home directory root (but not subdirectories)
      if [ -d "$USER_HOME" ]; then
        echo "  Cleaning home directory backup files..."
        ${pkgs.findutils}/bin/find "$USER_HOME" -maxdepth 1 -name "*.backup" -type f -delete 2>/dev/null || true
        ${pkgs.findutils}/bin/find "$USER_HOME" -maxdepth 1 -name "*.bak" -type f -delete 2>/dev/null || true
      fi

      # Ensure proper ownership of cleaned directories (in case cleanup changed anything)
      if ${pkgs.coreutils}/bin/id "${username}" >/dev/null 2>&1; then
        ${pkgs.coreutils}/bin/chown -R "${username}:users" "$USER_HOME"/.mozilla 2>/dev/null || true
        ${pkgs.coreutils}/bin/chown -R "${username}:users" "$USER_HOME"/.config 2>/dev/null || true
      fi

      echo "  ✅ Home Manager backup cleanup complete"
    '';

    # Run this script before home-manager and after users/groups are created
    deps = [
      "users"
      "groups"
    ];
  };

  # Ensure the script runs on every system activation, not just boot
  system.activationScripts.home-manager-backup-cleanup.supportsDryActivation = true;
}
