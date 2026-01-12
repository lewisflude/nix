{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.auto-update-immersed;
in
{
  options.services.auto-update-immersed = {
    enable = lib.mkEnableOption "automatic Immersed VR updates";

    interval = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = ''
        How often to check for Immersed updates.
        Uses systemd timer OnCalendar format.
        Examples: "daily", "weekly", "Mon *-*-* 00:00:00"
      '';
    };

    configPath = lib.mkOption {
      type = lib.types.path;
      default = /home/${config.users.users.lewis.name}/.config/nix;
      description = "Path to the Nix configuration repository";
    };

    autoCommit = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Automatically create a git commit when Immersed is updated.
        Warning: This will commit changes without user review.
      '';
    };

    autoRebuild = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Automatically rebuild the system after updating Immersed.
        Warning: This will rebuild without user review.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Systemd service to update Immersed
    systemd.services.update-immersed = {
      description = "Update Immersed VR to latest version";
      serviceConfig = {
        Type = "oneshot";
        User = config.users.users.lewis.name;
        WorkingDirectory = cfg.configPath;
      };

      path = [
        pkgs.nix
        pkgs.git
        pkgs.curl
        pkgs.gnused
      ];

      script = ''
        set -euo pipefail

        echo "Checking for Immersed updates..."

        # Download and calculate hash
        TEMP_FILE=$(mktemp)
        trap "rm -f $TEMP_FILE" EXIT

        if ! curl -fsSL "https://static.immersed.com/dl/Immersed-x86_64.AppImage" -o "$TEMP_FILE"; then
          echo "Failed to download Immersed" >&2
          exit 1
        fi

        NEW_HASH=$(nix hash file "$TEMP_FILE")
        OVERLAY_FILE="${cfg.configPath}/overlays/default.nix"

        if grep -q "$NEW_HASH" "$OVERLAY_FILE"; then
          echo "Immersed is already up to date"
          exit 0
        fi

        echo "New version detected, updating..."

        # Update hash in overlay
        sed -i "/if prev.stdenv.isLinux && prev.stdenv.isx86_64 then/,/else if prev.stdenv.isLinux && prev.stdenv.isAarch64 then/ s|hash = \"sha256-[^\"]*\"|hash = \"$NEW_HASH\"|" "$OVERLAY_FILE"

        # Format
        nix fmt "$OVERLAY_FILE" 2>/dev/null || true

        echo "Immersed overlay updated to hash: $NEW_HASH"

        ${lib.optionalString cfg.autoCommit ''
          # Commit changes
          cd "${cfg.configPath}"
          git add overlays/default.nix
          git commit -m "chore(vr): auto-update Immersed to latest version

          New hash: $NEW_HASH
          Updated by: auto-update-immersed.service" || true
        ''}

        ${lib.optionalString cfg.autoRebuild ''
          # Rebuild system
          echo "Rebuilding system..."
          if command -v nh >/dev/null 2>&1; then
            nh os switch
          else
            nixos-rebuild switch --flake "${cfg.configPath}"
          fi
        ''}
      '';
    };

    # Systemd timer to run the update check
    systemd.timers.update-immersed = {
      description = "Timer for Immersed VR updates";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.interval;
        Persistent = true;
        RandomizedDelaySec = "1h"; # Random delay to avoid load spikes
      };
    };
  };
}
