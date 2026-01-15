# Niri Animations Configuration
# Optimized for high-end hardware (13900K + RTX 4090)
#
# Animation types:
# - Spring: Physics-based, better for interactive/gestural elements (respects velocity)
# - Easing: Duration-based with curves, better for non-interactive timed animations
#
# Spring parameters:
# - damping-ratio: 1.0 = critically damped (no bounce, minimum time)
# - stiffness: Higher = faster (800-1200 tuned for high-end hardware)
# - epsilon: When to stop animating (0.0001 = very precise)
_: {
  animations = {
    enable = true;
    slowdown = 1.0;

    # Workspace switching - fast and snappy spring
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

    # Window movement - smooth drag and drop
    window-movement = {
      enable = true;
      kind = {
        spring = {
          damping-ratio = 1.0;
          stiffness = 800;
          epsilon = 0.0001;
        };
      };
    };

    # Window open - "The Pop" spring animation
    # High stiffness (1000) for fast opening that feels responsive
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

    # Window close - quick and clean
    window-close = {
      enable = true;
      kind = {
        easing = {
          duration-ms = 150;
          curve = "ease-out-quad";
        };
      };
    };

    # Window resize - very responsive (higher stiffness for high-end hardware)
    window-resize = {
      enable = true;
      kind = {
        spring = {
          damping-ratio = 1.0;
          stiffness = 1200;
          epsilon = 0.0001;
        };
      };
    };

    # Horizontal view movement - snappy scrolling (higher stiffness for responsiveness)
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

    # Config notification - subtle bounce for feedback
    config-notification-open-close = {
      enable = true;
      kind = {
        spring = {
          damping-ratio = 0.6;
          stiffness = 1000;
          epsilon = 0.001;
        };
      };
    };

    # Exit confirmation dialog - gentle bounce
    exit-confirmation-open-close = {
      enable = true;
      kind = {
        spring = {
          damping-ratio = 0.6;
          stiffness = 500;
          epsilon = 0.01;
        };
      };
    };

    # Screenshot UI - smooth open
    screenshot-ui-open = {
      enable = true;
      kind = {
        easing = {
          duration-ms = 200;
          curve = "ease-out-quad";
        };
      };
    };

    # Overview (workspace overview) - smooth toggle
    overview-open-close = {
      enable = true;
      kind = {
        spring = {
          damping-ratio = 1.0;
          stiffness = 800;
          epsilon = 0.0001;
        };
      };
    };
  };
}
