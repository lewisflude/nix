# Niri Animations Configuration
# Optimized for high-end hardware (13900K + RTX 4090)
_: {
  animations = {
    enable = true;
    slowdown = 1.0;

    # Workspace switching - fast and snappy
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

    # Window open - elegant fade and scale
    window-open = {
      enable = true;
      kind = {
        easing = {
          duration-ms = 150;
          curve = "ease-out-expo";
        };
      };
    };

    # Window close - quick and clean
    window-close = {
      enable = true;
      kind = {
        easing = {
          duration-ms = 125;
          curve = "ease-out-cubic";
        };
      };
    };

    # Window resize - smooth and responsive
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

    # Horizontal view movement - smooth scrolling between workspaces
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

    # Config notification - subtle feedback
    config-notification-open-close = {
      enable = true;
      kind = {
        easing = {
          duration-ms = 200;
          curve = "ease-out-quad";
        };
      };
    };
  };
}
