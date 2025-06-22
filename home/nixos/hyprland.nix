{ pkgs, hyprland, lib, ... }: {
  imports = [
    ./hyprland/keybinds.nix
    ./hyprland/window-rules.nix
    ./hyprland/startup.nix
  ];
  # Core Hyprland packages
  home.packages = with pkgs; [
    # Idle management and screen locking
    hypridle
    hyprlock
    hyprpaper  # Wallpaper daemon

    # Desktop utilities
    nwg-dock-hyprland
    nwg-drawer
    fuzzel      # Application launcher
    mako        # Notification daemon

    # Screenshot and media
    grim        # Screenshot utility
    slurp       # Region selector for screenshots
    swappy      # Screenshot editor

    # System monitoring and control
    pavucontrol # Audio control
    brightnessctl # Brightness control
    playerctl   # Media player control
  ];

  # Configure Hyprland
  wayland.windowManager.hyprland = {
    enable = true;
    package = hyprland.packages.${pkgs.system}.hyprland;
    systemd.enable = false; # Using UWSM instead of systemd

    settings = {
      # Variables
      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$fileManager" = "ghostty -e yazi";
      "$menu" = "fuzzel --launch-prefix='uwsm app -- '";

      # Monitor configuration (placeholder - adjust for actual setup)
      monitor = [
        # Main monitor example (adjust resolution/refresh rate as needed)
        "DP-1,3440x1440@165,0x0,1,bitdepth,10,vrr,1"
        # Additional monitors can be added here
      ];

      # General appearance
      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        resize_on_border = false;
        allow_tearing = true;
        layout = "dwindle";
      };

      # Decoration settings
      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = lib.mkForce 1.0;

        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };

        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
        "col.shadow" = "rgba(1a1a1aee)";
      };

      # Animations
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      # Input settings
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0; # -1.0 - 1.0, 0 means no modification

        touchpad = {
          natural_scroll = false;
        };
      };

      # Gestures
      gestures = {
        workspace_swipe = false;
      };

      # Miscellaneous settings
      misc = {
        force_default_wallpaper = 0; # Set to 0 to disable anime mascot wallpapers
        disable_hyprland_logo = true;
      };

      # Dwindle layout settings
      dwindle = {
        pseudotile = true; # Master switch for pseudotiling
        preserve_split = true; # You probably want this
      };

      # Master layout settings
      master = {
        new_status = "master";
      };
    };
  };
}