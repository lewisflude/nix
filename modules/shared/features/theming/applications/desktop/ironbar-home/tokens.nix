# Ironbar Design Tokens - Relaxed Profile (1440p+)
# Complete design token system for the Signal theme
# Based on formal design specification v1.0
#
# Usage:
#   tokens = import ./tokens.nix { };
#   commands = tokens.commands pkgs;  # Shell commands need pkgs
{ }:
rec {
  # Profile: Relaxed (optimized for 1440p+ displays)
  profile = "relaxed";

  # Grid System
  grid = {
    base-unit = 8; # Primary spacing unit (px)
    micro-unit = 4; # Fine adjustments (px)
  };

  # Bar Dimensions
  bar = {
    height = 48; # Bar height (px)
    margin = 12; # Screen edge distance, synced with Niri layout.gaps (px)
    widget-height = 44; # Bar height - 4px (px)
    item-height = 40; # Bar height - 8px (px)
  };

  # Typography Scale (Modular scale ratio: 1.125 Major Second)
  typography = {
    xs = 13; # Micro text, badges (px)
    sm = 14; # Base text, default size (px)
    md = 15; # Buttons, workspace icons (px)
    lg = 17; # Clock, emphasized text (px)
    xl = 19; # Popup headers (px)
  };

  # Font Weights
  font-weights = {
    normal = 400; # Default body text
    medium = 450; # Labels, secondary emphasis
    semibold = 500; # Active/focused states
    bold = 600; # Headers, strong emphasis
  };

  # Icon Sizes
  icons = {
    small = 18; # Inline with text, notifications (px)
    medium = 20; # Standalone icons, buttons (px)
    large = 22; # Emphasized icons (px)
    tray = 22; # System tray icons (fixed) (px)

    # Widget icon glyphs (Nerd Fonts)
    # Centralized to allow easy theme switching
    glyphs = {
      brightness = "󰃠";
      bell = "";
      power = "";

      # Volume icons (dynamic based on level)
      volume = {
        high = "󰕾"; # > 66%
        medium = "󰖀"; # 33-66%
        low = "󰕿"; # 1-32%
        muted = "󰝟"; # 0% or muted
      };

      # Workspace numbers (circled Unicode)
      workspace = {
        "1" = "①";
        "2" = "②";
        "3" = "③";
        "4" = "④";
        "5" = "⑤";
        "6" = "⑥";
        "7" = "⑦";
        "8" = "⑧";
        "9" = "⑨";
        "10" = "⑩";
      };
    };
  };

  # Semantic Text Colors (Signal Theme - Dark Mode, OKLCH)
  colors = {
    text = {
      primary = "#c0c3d1"; # L:0.80, C:0.05, H:240 - Primary readable text
      secondary = "#9498ab"; # L:0.65, C:0.05, H:240 - Secondary information
      tertiary = "#6b6f82"; # L:0.50, C:0.04, H:240 - Subtle/inactive text
    };

    # Semantic Surface Colors
    surface = {
      base = "#25262f"; # L:0.19, C:0.01, H:240 - Island backgrounds, popups
      emphasis = "#2d2e39"; # L:0.23, C:0.02, H:240 - Borders, hover backgrounds
    };

    # Semantic Accent Colors
    accent = {
      focus = "#5a7dcf"; # L:0.68, C:0.18, H:240 - Active state indicator
      warning = "#c9a93a"; # L:0.79, C:0.15, H:90 - Warning states (battery low)
      danger = "#d9574a"; # L:0.64, C:0.23, H:40 - Critical/destructive actions
    };

    # Derived Interaction Colors (for hover states)
    # Note: GTK CSS does not support rgba() with variables, use explicit values
    hover = {
      subtle = "rgba(45, 46, 57, 0.12)"; # surface-emphasis @ 0.12
      standard = "rgba(45, 46, 57, 0.15)"; # surface-emphasis @ 0.15
      active = "rgba(45, 46, 57, 0.25)"; # surface-emphasis @ 0.25
    };
  };

  # Opacity Tokens
  opacity = {
    invisible = 0;
    hint = 0.1;
    disabled = 0.4;
    muted = 0.45;
    hover-subtle = 0.65;
    secondary = 0.7;
    tertiary = 0.75;
    primary = 0.8;
    emphasis = 0.9;
    full = 1.0;
  };

  # Spacing Scale (8pt grid system)
  spacing = {
    none = 0;
    xs = 4; # Micro-unit, fine details (px)
    sm = 8; # Standard small gaps (px)
    md = 12; # Comfortable spacing (px)
    lg = 16; # Section separation (px)
    xl = 20; # Generous gaps (px)
    "2xl" = 24; # Major sections (px)
    "3xl" = 32; # Large separation (px)
  };

  # Border Radius Scale
  radius = {
    none = 0;
    sm = 10; # Small elements, tray icons (px)
    md = 12; # Interactive elements, buttons (px)
    lg = 16; # Islands, primary containers (px) - SYNCED WITH NIRI
    xl = 18; # Popups, major emphasis (px)
  };

  # Border Widths
  borders = {
    standard = 2; # Standard border width (px)
    accent = 3; # Accent bar width (px) - fixed, not profile-dependent
  };

  # Shadow Tokens (GTK CSS inset shadows only)
  shadows = {
    island = "inset 0 1px 0 rgba(255, 255, 255, 0.08)"; # Standard islands
    island-center = "inset 0 1px 0 rgba(255, 255, 255, 0.10)"; # Center island (emphasis)
    popup = "inset 0 1px 0 rgba(255, 255, 255, 0.12)"; # Popup containers
  };

  # Transition Tokens
  transitions = {
    duration = {
      fast = 50; # Micro-interactions (ms)
      normal = 150; # Standard transitions (ms)
      slow = 200; # Emphasized transitions (ms)
    };
    easing = {
      default = "ease";
      out = "ease-out";
      in-out = "ease-in-out";
    };
  };

  # Animation Durations
  animations = {
    pulse = 1000; # Critical battery pulse (ms)
    urgent-pulse = 1500; # Urgent workspace pulse (ms)
    fade-in = 150; # Popup entry (ms)
  };

  # Z-Index Layers
  z-index = {
    bar = 100;
    popup = 200;
  };

  # Touch Target Minimum (accessibility)
  touch-target = {
    min = 24; # Minimum interactive size (px)
  };

  # Widget-Specific Constants
  widgets = {
    clock = {
      min-width = 128; # Fixed width for layout stability (px)
    };
    numeric-display = {
      percentage = {
        min-width = 40; # e.g., "100%" (px)
      };
      time = {
        min-width = 48; # e.g., "23:59" (px)
      };
      time-extended = {
        min-width = 72; # e.g., "23:59:59" (px)
      };
    };
    workspace-button = {
      min-width = 40; # Compact square (px)
      min-height = 40;
      margin = 4; # Horizontal margin between buttons (px)
      padding-horizontal = 8; # Internal padding (px)
      padding-vertical = 4;
    };
    tray-icon = {
      display-size = 18; # Normalized from 22px source (px)
      container-size = 24; # Touch target (px)
      padding = 4; # Internal padding (px)
      margin = 3; # Horizontal margin (px)
    };
    window-title = {
      max-width = 296; # Maximum container width (px)
      max-chars = 50; # Character truncation limit
    };
  };

  # Niri Synchronization Values
  # These MUST match the Niri window manager configuration
  # Used by home/nixos/niri/layout.nix and home/nixos/niri/window-rules.nix
  niriSync = {
    windowRadius = radius.lg; # 16px - window corners match island borders
    windowGap = bar.margin; # 12px - window gaps match bar margin
  };

  # Shell commands used by widgets
  # Centralized for maintainability and testing
  # Pass pkgs when importing: (tokens.commands pkgs)
  commands = pkgs: {
    niri = {
      layoutMode = "${pkgs.niri-unstable}/bin/niri msg focused-window | ${pkgs.jq}/bin/jq -r '.layout_mode // \"tiled\"'";
    };

    brightness = {
      decrease = "${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
      increase = "${pkgs.brightnessctl}/bin/brightnessctl set +5%";
      reset = "${pkgs.brightnessctl}/bin/brightnessctl set 50%";
    };

    volume = {
      toggleMute = "{{${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle}}";
      increaseBy = amount: "{{${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ ${amount}+}}";
      decreaseBy = amount: "{{${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ ${amount}-}}";
    };

    notifications = {
      toggle = "${pkgs.swaynotificationcenter}/bin/swaync-client -t";
    };

    power = {
      menu = ''
        echo -e "Logout\nSuspend\nHibernate\nReboot\nShutdown" | \
        ${pkgs.fuzzel}/bin/fuzzel --dmenu | \
        ${pkgs.gnused}/bin/sed \
          -e 's/^Logout$/loginctl terminate-user $USER/' \
          -e 's/^Suspend$/systemctl suspend/' \
          -e 's/^Hibernate$/systemctl hibernate/' \
          -e 's/^Reboot$/systemctl reboot/' \
          -e 's/^Shutdown$/systemctl poweroff/' | \
        sh
      '';
    };
  };
}
