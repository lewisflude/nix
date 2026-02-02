# Niri Unified Configuration
# Consolidates: layout, input, animations, startup, and packages
{
  pkgs,
  config,
  inputs,
  system,
  ...
}:
{
  # ============================================================================
  # LAYOUT CONFIGURATION
  # ============================================================================
  # Note: DMS includes may override some of these settings via ~/.config/niri/dms/
  # If conflicts occur, adjust DMS includes.override or these values

  layout = {
    # Window spacing - 8px for tight 8pt grid system
    gaps = 8;

    # Layout behavior
    always-center-single-column = true;
    empty-workspace-above-first = true;
    default-column-display = "tabbed";

    # Center focused column when it doesn't fit on screen with previous column
    center-focused-column = "on-overflow";

    # Preset column widths for quick switching with Mod+R
    preset-column-widths = [
      { proportion = 1.0 / 3.0; }
      { proportion = 1.0 / 2.0; }
      { proportion = 2.0 / 3.0; }
      { proportion = 1.0; }
    ];

    # Border: disabled in favor of DMS-managed focus ring
    border = {
      enable = false;
    };

    # Struts: reserve screen edges (not needed)
    struts = {
      left = 0;
      right = 0;
      top = 0;
      bottom = 0;
    };
  };

  # ============================================================================
  # INPUT CONFIGURATION
  # ============================================================================

  input = {
    keyboard = {
      xkb = {
        layout = "us";
      };

      # Key repeat settings (600ms delay before repeat, 25 keys/sec when repeating)
      repeat-delay = 600;
      repeat-rate = 25;
    };

    # Focus follows mouse for "tape scrolling" metaphor
    # max-scroll-amount = "0%": instant focus without delay
    # In a scrolling UI, the cursor acts as a "read head"
    focus-follows-mouse = {
      enable = true;
      max-scroll-amount = "0%";
    };

    # Warp mouse disabled - prevents disorientation during keyboard navigation
    # Per guide: "Disable warping - it disorients the user"
    warp-mouse-to-focus = {
      enable = false;
    };

    # Quick workspace switching - press same keybind twice to toggle back
    workspace-auto-back-and-forth = true;

    mouse = {
      natural-scroll = true;
      # Flat profile disables pointer acceleration for consistent 1:1 movement
      accel-profile = "flat";
      scroll-factor = 1.0;
    };
  };

  # ============================================================================
  # ANIMATIONS CONFIGURATION
  # ============================================================================

  animations = {
    enable = true;
    slowdown = 1.0;

    # Uniform fast spring for interactive elements
    workspace-switch = {
      enable = true;
      kind = {
        spring = {
          damping-ratio = 1.0;
          stiffness = 1000;
          epsilon = 0.0001;
        };
      };
    };

    window-movement = {
      enable = true;
      kind = {
        spring = {
          damping-ratio = 1.0;
          stiffness = 1000;
          epsilon = 0.0001;
        };
      };
    };

    window-open = {
      enable = true;
      kind = {
        spring = {
          damping-ratio = 1.0;
          stiffness = 1000;
          epsilon = 0.0001;
        };
      };
    };

    window-resize = {
      enable = true;
      kind = {
        spring = {
          damping-ratio = 1.0;
          stiffness = 1000;
          epsilon = 0.0001;
        };
      };
    };

    horizontal-view-movement = {
      enable = true;
      kind = {
        spring = {
          damping-ratio = 1.0;
          stiffness = 1000;
          epsilon = 0.0001;
        };
      };
    };

    # Quick easing for non-interactive
    window-close = {
      enable = true;
      kind = {
        easing = {
          duration-ms = 150;
          curve = "ease-out-quad";
        };
      };
    };

    screenshot-ui-open = {
      enable = true;
      kind = {
        easing = {
          duration-ms = 150;
          curve = "ease-out-quad";
        };
      };
    };
  };

  # ============================================================================
  # STARTUP COMMANDS
  # ============================================================================

  spawn-at-startup = [
    # xwayland-satellite is automatically managed by niri >= 25.08
    # It spawns on-demand when X11 clients connect and auto-restarts if it crashes
    # No need to spawn it manually here

    # awww wallpaper daemon
    # "An Answer to your Wayland Wallpaper Woes"
    # Set wallpapers with: awww img /path/to/image.png
    {
      command = [
        "${inputs.awww.packages.${system}.awww}/bin/awww-daemon"
      ];
    }

    # Apply ICC color profile for AW3423DWF monitor
    # ArgyllCMS dispwin loads the calibrated color profile
    # Note: If this fails, displays might not be ready yet (rare race condition)
    {
      command = [
        "${pkgs.argyllcms}/bin/dispwin"
        "-d"
        "1"
        "${config.home.homeDirectory}/.local/share/icc/aw3423dwf.icc"
      ];
    }

    # Gamma and brightness correction for display quality
    # For OLED displays (AW3423DWF), gamma 1.0 provides accurate color reproduction
    # Adjust if needed: gamma >1.0 brightens, <1.0 darkens
    {
      command = [
        "${pkgs.wl-gammactl}/bin/wl-gammactl"
        "--gamma"
        "1.0"
        "--brightness"
        "1.0"
      ];
    }

    # Enable dummy HDMI output for Sunshine game streaming
    # This ensures HDMI-A-4 is always available as Monitor 1 for streaming
    # Alternative: Could be handled via output config, but explicit enable ensures reliability
    {
      command = [
        "${pkgs.niri}/bin/niri"
        "msg"
        "output"
        "HDMI-A-4"
        "on"
      ];
    }
  ];
}
