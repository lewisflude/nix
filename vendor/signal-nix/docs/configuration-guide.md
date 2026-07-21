# Configuration Guide

Complete reference for all Signal configuration options.

## Table of Contents

- [Basic Configuration](#basic-configuration)
- [Theme Modes](#theme-modes)
- [Automatic vs Selective Theming](#automatic-vs-selective-theming)
- [Per-Application Options](#per-application-options)
- [Advanced Options](#advanced-options)
- [Configuration Patterns](#configuration-patterns)

## Basic Configuration

### Minimal Setup

The simplest Signal configuration:

```nix
{
  theming.signal = {
    enable = true;
    autoEnable = true;
    mode = "dark";
  };
}
```

This will:
- Enable Signal theming system
- Automatically theme all enabled programs
- Use dark mode colors

### Full Options

```nix
{
  theming.signal = {
    # Core options
    enable = true;              # Enable Signal theming
    autoEnable = false;         # Auto-theme all enabled programs
    mode = "dark";              # Theme mode: "light", "dark", or "auto"

    # Per-category options
    editors = {
      helix.enable = true;
      neovim.enable = true;
      vim.enable = true;
      vscode.enable = true;
      emacs.enable = false;
      zed.enable = true;
    };

    terminals = {
      ghostty.enable = true;
      alacritty.enable = true;
      kitty.enable = true;
      wezterm.enable = true;
      foot.enable = true;
    };

    cli = {
      bat.enable = true;
      delta.enable = true;
      eza.enable = true;
      vivid.enable = true;
      fzf.enable = true;
      lazygit.enable = true;
      lazydocker.enable = true;
      yazi.enable = true;
      ranger.enable = true;
      lf.enable = true;
      nnn.enable = true;
      btop.enable = true;
      htop.enable = true;
      bottom.enable = true;
      procs.enable = true;
      mangohud.enable = true;
      tealdeer.enable = true;
      less.enable = true;
      ripgrep.enable = true;
      glow.enable = true;
      tig.enable = true;
    };

    shells = {
      zsh.enable = true;
      fish.enable = true;
      bash.enable = true;
      nushell.enable = true;
    };

    prompts = {
      starship.enable = true;
    };

    multiplexers = {
      tmux.enable = true;
      zellij.enable = true;
    };

    browsers = {
      firefox.enable = true;
      qutebrowser.enable = true;
    };

    fileManagers = {
      yazi.enable = true;
      ranger.enable = true;
      lf.enable = true;
      nnn.enable = true;
    };

    monitors = {
      btop.enable = true;
      htop.enable = true;
      bottom.enable = true;
    };

    desktop = {
      hyprland.enable = true;
      sway.enable = true;
      i3.enable = true;
      bspwm.enable = true;
      awesome.enable = true;
      rofi.enable = true;
      wofi.enable = true;
      tofi.enable = true;
      dmenu.enable = true;
      fuzzel.enable = true;
      waybar.enable = true;
      polybar.enable = true;
      ironbar.enable = true;
      dunst.enable = true;
      mako.enable = true;
      swaync.enable = true;
      swaylock.enable = true;
    };

    apps = {
      satty.enable = true;
    };

    gtk = {
      enable = true;
      dconf = {
        enable = true;  # Behavioral settings (animations, fonts, etc.)
        clockFormat = "24h";  # or "12h"
        fontAntialiasing = "rgba";  # LCD subpixel antialiasing
        fontHinting = "slight";  # Subtle hinting for modern fonts
        touchpad = {
          tapToClick = true;
          clickMethod = "fingers";  # Two-finger right-click
          naturalScroll = false;
        };
        nightLight = {
          enable = false;  # Blue light filter
          temperature = 4500;  # Kelvin (2700-6500)
        };
      };
    };

    qt = {
      enable = true;
    };

    media = {
      mpv.enable = true;
    };
  };
}
```

## Theme Modes

Signal supports three theme modes:

### Dark Mode (Recommended)

```nix
theming.signal.mode = "dark";
```

- Dark background (#0a0d12)
- Light text (#c5cdd8)
- Optimized for low-light environments
- Reduced eye strain for extended use

### Light Mode

```nix
theming.signal.mode = "light";
```

- Light background (#f5f7fa)
- Dark text (#2a2d35)
- Optimized for bright environments
- High contrast for readability

### Auto Mode

```nix
theming.signal.mode = "auto";
```

- Follows system theme preference
- Currently defaults to dark mode
- Future: Will detect system theme

## Theming Patterns

### Default Behavior (Automatic Theming)

**This is the recommended approach.** Simply enable Signal and it themes all your programs:

```nix
theming.signal = {
  enable = true;  # Automatically themes all enabled programs
  mode = "dark";
};

# All these will be automatically themed:
programs = {
  helix.enable = true;
  kitty.enable = true;
  bat.enable = true;
  fzf.enable = true;
};
```

**How it works:**
- Signal detects which programs you've enabled
- Automatically applies Signal colors to them
- No per-program configuration needed
- `autoEnable` defaults to `true` (automatic theming enabled by default)

### Selective Disabling

Theme most programs but keep specific ones with their default colors:

```nix
theming.signal = {
  enable = true;  # autoEnable is true by default
  mode = "dark";

  # Explicitly disable theming for specific programs
  cli.bat.enable = false;      # Keep bat's default theme
  terminals.kitty.enable = false;  # Keep kitty's default theme
};

programs = {
  helix.enable = true;   # ✅ Themed (automatic)
  kitty.enable = true;   # ❌ Not themed (explicitly disabled)
  bat.enable = true;     # ❌ Not themed (explicitly disabled)
  fzf.enable = true;     # ✅ Themed (automatic)
};
```

### Manual Control (Advanced)

For complete control over which programs get themed, disable automatic theming:

```nix
theming.signal = {
  enable = true;
  autoEnable = false;  # Disable automatic theming
  mode = "dark";

  # Now explicitly enable theming for each program
  editors.helix.enable = true;
  terminals.kitty.enable = true;
  cli.bat.enable = true;
};

# Even though these are enabled, only explicitly themed programs get Signal colors:
programs = {
  helix.enable = true;   # ✅ Themed (explicitly enabled)
  kitty.enable = true;   # ✅ Themed (explicitly enabled)
  bat.enable = true;     # ✅ Themed (explicitly enabled)
  fzf.enable = true;     # ❌ Not themed (not explicitly enabled)
};
```

## Per-Application Options

Each application has an enable option under its category:

```nix
theming.signal.<category>.<app>.enable = true;
```

### Categories

- `editors` - Text editors (Helix, Neovim, Vim, VS Code, Emacs, Zed)
- `terminals` - Terminal emulators (Ghostty, Alacritty, Kitty, WezTerm, Foot)
- `cli` - Command-line tools (bat, delta, eza, fzf, lazygit, etc.)
- `shells` - Shell environments (zsh, fish, bash, nushell)
- `prompts` - Shell prompts (Starship)
- `multiplexers` - Terminal multiplexers (tmux, Zellij)
- `browsers` - Web browsers (Firefox, Qutebrowser)
- `fileManagers` - File managers (yazi, ranger, lf, nnn)
- `monitors` - System monitors (btop, htop, bottom)
- `desktop` - Desktop environment components (window managers, launchers, bars, notifications)
- `apps` - Applications (Satty)
- `gtk` - GTK theming
- `qt` - Qt theming
- `media` - Media players (MPV)

## Advanced Options

### GTK Behavioral Settings (dconf)

In addition to visual theming (colors, CSS), Signal provides behavioral settings for GTK applications via dconf. These settings control interface behavior, font rendering, and system preferences.

**Enabled by default** when GTK theming is active.

#### Complete dconf Configuration

```nix
theming.signal.gtk.dconf = {
  enable = true;  # Default: true

  # Clock settings
  clockFormat = "24h";  # "12h" or "24h"
  clockShowWeekday = false;  # Show weekday in clock

  # Interface
  enableAnimations = true;  # GTK animations

  # Font rendering (important for LCD monitors)
  fontAntialiasing = "rgba";  # "none", "grayscale", or "rgba"
  fontHinting = "slight";  # "none", "slight", "medium", or "full"

  # Touchpad settings (for laptops)
  touchpad = {
    tapToClick = true;
    clickMethod = "fingers";  # "default", "none", "areas", or "fingers"
    naturalScroll = false;  # Reversed scrolling
  };

  # Night Light (blue light filter)
  nightLight = {
    enable = false;  # Enable Night Light
    temperature = 4500;  # Kelvin (2700-6500)
  };
};
```

#### What dconf Settings Control

Signal's dconf module configures:

1. **color-scheme** - Tells GTK apps to use dark/light variants (`prefer-dark`/`prefer-light`)
2. **Font rendering** - Antialiasing and hinting for better text clarity
3. **Interface behaviors** - Animations, clock format
4. **Touchpad settings** - Tap-to-click, click method, natural scroll
5. **Night Light** - Blue light filter temperature
6. **Application defaults** - Nautilus file manager, GNOME Text Editor

#### Recommended Settings by Monitor Type

**LCD Monitors (most common):**
```nix
fontAntialiasing = "rgba";  # Subpixel antialiasing
fontHinting = "slight";     # Subtle hinting
```

**High-DPI/Retina Displays:**
```nix
fontAntialiasing = "grayscale";  # No subpixel needed
fontHinting = "slight";          # Minimal hinting
```

**Projectors/Low-DPI:**
```nix
fontAntialiasing = "rgba";
fontHinting = "medium";  # More aggressive hinting
```

#### Disabling dconf Settings

If you want only visual theming without behavioral settings:

```nix
theming.signal.gtk = {
  enable = true;  # Visual theming only
  dconf.enable = false;  # No behavioral settings
};
```

### Using with Existing Configurations

Signal respects your existing program configurations:

```nix
{
  # Your existing Helix config
  programs.helix = {
    enable = true;
    settings = {
      editor = {
        line-number = "relative";
        cursorline = true;
      };
    };
  };

  # Signal only adds colors
  theming.signal = {
    enable = true;
    editors.helix.enable = true;
    mode = "dark";
  };
}
```

Signal will merge its color configuration with your existing settings.

### Multiple Machines

Share Signal configuration across machines:

```nix
# shared.nix
{
  theming.signal = {
    enable = true;
    autoEnable = true;
    mode = "dark";
  };
}

# desktop.nix
{ imports = [ ./shared.nix ]; }

# laptop.nix
{
  imports = [ ./shared.nix ];

  # Override for laptop
  theming.signal.mode = "light";
}
```

### Conditional Theming

Theme based on conditions:

```nix
{ config, lib, ... }:

{
  theming.signal = {
    enable = true;
    autoEnable = true;
    mode = if config.networking.hostName == "laptop" then "light" else "dark";
  };
}
```

## Configuration Patterns

### Pattern 1: Full Auto

Let Signal handle everything:

```nix
{
  theming.signal = {
    enable = true;
    autoEnable = true;
    mode = "dark";
  };

  programs = {
    helix.enable = true;
    kitty.enable = true;
    bat.enable = true;
    # ... all your programs
  };
}
```

**Best for:** New users, simple setups

### Pattern 2: Explicit Control

Choose exactly what gets themed:

```nix
{
  theming.signal = {
    enable = true;
    mode = "dark";

    editors.helix.enable = true;
    terminals.kitty.enable = true;
    cli.bat.enable = true;
  };

  programs = {
    helix.enable = true;
    kitty.enable = true;
    bat.enable = true;
    fzf.enable = true;  # Won't be themed
  };
}
```

**Best for:** Mixed themes, testing Signal

### Pattern 3: Mostly Auto with Exceptions

Theme everything except a few programs:

```nix
{
  theming.signal = {
    enable = true;
    autoEnable = true;
    mode = "dark";

    # Keep my custom theme for these
    editors.neovim.enable = false;
    terminals.wezterm.enable = false;
  };

  programs = {
    helix.enable = true;    # Themed
    neovim.enable = true;   # Not themed (custom theme)
    kitty.enable = true;    # Themed
    wezterm.enable = true;  # Not themed (custom theme)
  };
}
```

**Best for:** Gradual migration, custom themes for specific apps

### Pattern 4: Per-Category Control

Enable entire categories at once:

```nix
{
  theming.signal = {
    enable = true;
    mode = "dark";

    # Theme all editors
    editors = {
      helix.enable = true;
      neovim.enable = true;
      vim.enable = true;
    };

    # Theme all terminals
    terminals = {
      kitty.enable = true;
      alacritty.enable = true;
    };
  };
}
```

**Best for:** Category-based organization

## Switching Themes

To switch from dark to light mode:

1. **Update configuration:**

```nix
theming.signal.mode = "light";  # Changed from "dark"
```

2. **Rebuild:**

```bash
# NixOS
sudo nixos-rebuild switch

# nix-darwin
darwin-rebuild switch

# Standalone Home Manager
home-manager switch
```

3. **Restart applications** to load new colors

## Troubleshooting

### Program not themed

**Check these in order:**

1. Is Signal enabled? `theming.signal.enable = true`
2. Is the program enabled? `programs.<app>.enable = true`
3. Is theming enabled for the program?
   - Either `autoEnable = true`
   - Or `<category>.<app>.enable = true`
4. Did you rebuild? Run your rebuild command
5. Did you restart the application?

### Colors not showing

1. **Restart the application** - Most apps need a restart
2. **Check config files** - Verify Signal generated the configs
3. **Check true color support** - Ensure terminal supports 24-bit color

### Conflicts with existing themes

If you have existing color configuration:

```nix
# This might conflict:
programs.helix.settings.theme = "my-custom-theme";

# Signal will override with:
programs.helix.settings.theme = "signal";
```

**Solution:** Disable Signal for that program:

```nix
theming.signal.editors.helix.enable = false;
```

For more help, see the [Troubleshooting Guide](troubleshooting.md).

## Next Steps

- **[Supported Applications](theming-reference.md)** - See all supported apps
- **[Examples](../examples/)** - Real-world configurations
- **[Architecture](architecture.md)** - How Signal works internally
- **[Advanced Usage](advanced-usage.md)** - Power user features
