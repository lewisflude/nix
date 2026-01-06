{ pkgs, ... }:
let
  # Sunshine prep script - enables HDMI-A-4 and moves workspace to it
  sunshine-prep = pkgs.writeShellApplication {
    name = "sunshine-prep";
    runtimeInputs = [
      pkgs.niri
      pkgs.jq
      pkgs.systemd
      pkgs.coreutils
    ];
    text = ''
      # Log to journalctl for debugging
      log() {
          echo "[sunshine-prep] $*" | systemd-cat -t sunshine-prep -p info
      }

      log "Starting Sunshine stream preparation"

      # Move current workspace to HDMI-A-4 (brings any existing windows with it)
      current_ws=$(niri msg --json workspaces | jq -r '.[] | select(.is_focused == true) | .idx')
      log "Moving workspace $current_ws to HDMI-A-4"
      niri msg action move-workspace-to-monitor-right

      sleep 1.0

      # Turn off DP-3 to ensure all content goes to HDMI-A-4
      log "Disabling DP-3 to force all content to HDMI-A-4"
      niri msg output DP-3 off

      sleep 1.0

      # Focus HDMI-A-4 explicitly to ensure new windows open there
      log "Focusing HDMI-A-4 display"
      niri msg action focus-monitor-right

      sleep 0.5

      log "Preparation complete - workspace $current_ws is now on HDMI-A-4 (DP-3 disabled)"
    '';
  };

  # Sunshine cleanup script - moves windows back to DP-3 and disables HDMI-A-4
  sunshine-cleanup = pkgs.writeShellApplication {
    name = "sunshine-cleanup";
    runtimeInputs = [
      pkgs.niri
      pkgs.jq
      pkgs.systemd
      pkgs.coreutils
    ];
    text = ''
      # Log to journalctl for debugging
      log() {
          echo "[sunshine-cleanup] $*" | systemd-cat -t sunshine-cleanup -p info
      }

      log "Starting Sunshine stream cleanup"

      # Re-enable DP-3 first (so we have somewhere to move windows to)
      log "Re-enabling DP-3"
      niri msg output DP-3 on

      sleep 0.5

      # Move workspace from HDMI-A-4 back to DP-3
      log "Moving workspace from HDMI-A-4 back to DP-3"
      niri msg action move-workspace-to-monitor-left

      sleep 0.3

      # Note: We keep HDMI-A-4 enabled so Sunshine can always detect it
      log "Cleanup complete - all windows back on DP-3 (HDMI-A-4 remains enabled but unused)"
    '';
  };
in
{
  # Sunshine - Open source game streaming server
  # Enables streaming games from this host to remote clients
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # only needed for Wayland -- omit this when using with Xorg
    openFirewall = true;

    # Sunshine settings - configure which output to capture
    # HDMI-A-4 is always enabled so Sunshine detects it as Monitor 1
    settings = {
      output_name = "1"; # Capture Monitor 1 (HDMI-A-4)
    };

    # Application definitions with prep-cmd lifecycle hooks
    applications = {
      apps = [
        # Desktop streaming - streams entire workspace
        {
          name = "Desktop";
          prep-cmd = [
            {
              do = "${sunshine-prep}/bin/sunshine-prep";
              undo = "${sunshine-cleanup}/bin/sunshine-cleanup";
            }
          ];
          image-path = "desktop.png";
        }

        # Steam Big Picture - for gaming
        {
          name = "Steam Big Picture";
          detached = [ "${pkgs.steam}/bin/steam steam://open/bigpicture" ];
          prep-cmd = [
            {
              do = "${sunshine-prep}/bin/sunshine-prep";
              undo = "${sunshine-cleanup}/bin/sunshine-cleanup && ${pkgs.steam}/bin/steam steam://close/bigpicture";
            }
          ];
          image-path = "steam.png";
        }

        # Regular Steam - for desktop mode gaming
        {
          name = "Steam";
          detached = [ "${pkgs.steam}/bin/steam" ];
          prep-cmd = [
            {
              do = "${sunshine-prep}/bin/sunshine-prep";
              undo = "${sunshine-cleanup}/bin/sunshine-cleanup";
            }
          ];
          image-path = "steam.png";
        }
      ];
    };
  };

  # Make scripts available system-wide for debugging
  environment.systemPackages = [
    sunshine-prep
    sunshine-cleanup
  ];
}
