{
  username,
  pkgs,
  ...
}:
{
  system.activationScripts.home-manager-backup-cleanup = {
    text = ''
      echo "🧹 Cleaning up Home Manager backup files..."
      USER_HOME="/home/${username}"
      if [ ! -d "$USER_HOME" ]; then
        echo "  Warning: User home directory $USER_HOME not found, skipping cleanup"
        exit 0
      fi
      cleanup_backup_files() {
        local dir="$1"
        local desc="$2"
        if [ -d "$dir" ]; then
          echo "  Cleaning $desc backup files..."
          ${pkgs.findutils}/bin/find "$dir" -name "*.backup" -type f -print0 2>/dev/null | \
            ${pkgs.coreutils}/bin/xargs -0 -r rm -f 2>/dev/null || true
          ${pkgs.findutils}/bin/find "$dir" -name "*.bak" -type f -print0 2>/dev/null | \
            ${pkgs.coreutils}/bin/xargs -0 -r rm -f 2>/dev/null || true
          ${pkgs.findutils}/bin/find "$dir" -name "*.backup.*" -type f -mtime +3 -print0 2>/dev/null | \
            ${pkgs.coreutils}/bin/xargs -0 -r rm -f 2>/dev/null || true
        fi
      }
      cleanup_backup_files "$USER_HOME/.mozilla/firefox" "Firefox"
      cleanup_backup_files "$USER_HOME/.config" "config"
      cleanup_backup_files "$USER_HOME/.local/share" "local data"
      if [ -d "$USER_HOME" ]; then
        echo "  Cleaning home directory backup files..."
        ${pkgs.findutils}/bin/find "$USER_HOME" -maxdepth 1 -name "*.backup" -type f -delete 2>/dev/null || true
        ${pkgs.findutils}/bin/find "$USER_HOME" -maxdepth 1 -name "*.bak" -type f -delete 2>/dev/null || true
      fi
      if ${pkgs.coreutils}/bin/id "${username}" >/dev/null 2>&1; then
        ${pkgs.coreutils}/bin/chown -R "${username}:users" "$USER_HOME"/.mozilla 2>/dev/null || true
        ${pkgs.coreutils}/bin/chown -R "${username}:users" "$USER_HOME"/.config 2>/dev/null || true
      fi
      echo "  ✅ Home Manager backup cleanup complete"
    '';
    deps = [
      "users"
      "groups"
    ];
  };
  system.activationScripts.home-manager-backup-cleanup.supportsDryActivation = true;
}
