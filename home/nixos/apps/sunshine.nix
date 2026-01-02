{ pkgs, ... }:
{
  # Sunshine configuration for game streaming with KMS capture
  # KMS (Kernel Mode Setting) capture is more reliable than wlroots on Wayland
  # Requires CAP_SYS_ADMIN capability (configured in modules/nixos/features/gaming.nix)
  xdg.configFile."sunshine/sunshine.conf".text = ''
    # Display capture settings
    capture = kms

    # Output settings optimized for Quest 3 and RTX 4090 NVENC
    encoder = nvenc
    adapter_name = /dev/dri/card1
    # Use monitor ID (numeric) - Monitor 0 = DP-3, Monitor 1 = HDMI-A-4 (dummy plug)
    # Target main display (DP-3) for Steam Link streaming
    # Change to output_name = 1 to use dummy HDMI plug instead
    output_name = 0

    # Network settings
    upnp = on
    port = 47989

    # Performance settings
    min_fps_factor = 1
    channels = 2
  '';

  # Sunshine applications configuration
  # Configures apps to launch on HDMI-A-4 (dummy display) for streaming
  xdg.configFile."sunshine/apps.json".text = builtins.toJSON {
    env = {
      PATH = "$(PATH):$(HOME)/.local/bin";
      WAYLAND_DISPLAY = "wayland-1";
      XDG_RUNTIME_DIR = "/run/user/1000";
    };
    apps = [
      {
        name = "Desktop";
        image-path = "desktop.png";
        # Disable auto-lock and unlock screen when streaming desktop
        prep-cmd = [
          {
            do = "pkill swaylock; systemctl --user stop swayidle.service";
            undo = "systemctl --user start swayidle.service";
          }
        ];
        cmd = [ ];
      }
      {
        name = "Steam Big Picture";
        # Disable auto-lock and unlock screen when streaming Steam
        prep-cmd = [
          {
            do = "pkill swaylock; systemctl --user stop swayidle.service";
            undo = "systemctl --user start swayidle.service";
          }
        ];
        detached = [
          # Gamescope wraps Steam Big Picture for reliable streaming
          # Niri window rules force Steam to HDMI-A-4 dummy display
          # -f enables fullscreen mode
          # -w/-h sets internal resolution to match HDMI-A-4 (1920x1080)
          # -W/-H sets output resolution to match HDMI-A-4
          # --backend sdl required for proper cursor locking on Niri
          # -e enables Steam integration
          "${pkgs.gamescope}/bin/gamescope -f -w 1920 -h 1080 -W 1920 -H 1080 --backend sdl -e -- steam -steamos3 -steamdeck -gamepadui"
        ];
        image-path = "steam.png";
      }
    ];
  };
}
