# Scientific Theme Usage Examples

This guide provides practical examples for using and customizing the Scientific Theme system.

## Basic Usage

### Example 1: Enable Dark Mode Theme

The simplest way to enable the theme:

**File:** `hosts/my-host/configuration.nix`

```nix
{
  host.features.desktop = {
    enable = true;
    scientificTheme = {
      enable = true;
      mode = "dark";
    };
  };
}
```

This will automatically apply the dark theme to:

- Cursor/VS Code
- Helix editor
- Zed editor
- Ghostty terminal
- GTK applications (Linux only)
- Niri window manager (if enabled)

### Example 2: Enable Light Mode Theme

For a light mode theme:

```nix
{
  host.features.desktop = {
    enable = true;
    scientificTheme = {
      enable = true;
      mode = "light";
    };
  };
}
```

## Selective Application Theming

### Example 3: Theme Only Specific Applications

If you only want to theme certain applications:

```nix
{
  # Disable the high-level feature flag
  host.features.desktop.scientificTheme.enable = false;

  # Configure theme manually
  theming.scientific = {
    enable = true;
    mode = "dark";

    applications = {
      cursor.enable = true;
      helix.enable = true;
      zed.enable = false;      # Don't theme Zed
      ghostty.enable = false;  # Don't theme Ghostty
      gtk.enable = false;      # Don't theme GTK
      niri.enable = false;     # Don't theme Niri
    };
  };
}
```

### Example 4: Linux-Specific Configuration

Apply theme only to Linux-specific applications:

```nix
{ lib, pkgs, ... }:
{
  host.features.desktop = {
    enable = true;
    scientificTheme = {
      enable = true;
      mode = "dark";
    };
  };

  # GTK and Niri are automatically disabled on non-Linux systems
  # But you can be explicit:
  theming.scientific.applications = {
    gtk.enable = lib.mkForce (pkgs.stdenv.isLinux);
    niri.enable = lib.mkForce false; # Disable even on Linux
  };
}
```

## Advanced Customization

### Example 5: Override Specific Colors

If you need to tweak specific colors (advanced usage):

```nix
{
  theming.scientific = {
    enable = true;
    mode = "dark";

    # Override the primary accent color to a different shade of green
    overrides = {
      "accent-primary" = {
        l = 0.65;  # Slightly darker
        c = 0.22;  # More saturated
        h = 130.0;
        hex = "#3d9e55"; # Pre-calculated hex value
      };
    };
  };
}
```

?? **Warning**: Overriding colors may affect accessibility and visual consistency.

### Example 6: Per-User Theme Configuration

Apply different themes for different users:

```nix
{
  # User 1: Dark theme
  home-manager.users.alice = {
    theming.scientific = {
      enable = true;
      mode = "dark";
    };
  };

  # User 2: Light theme
  home-manager.users.bob = {
    theming.scientific = {
      enable = true;
      mode = "light";
    };
  };
}
```

## Integration with Existing Configurations



### Example 8: Gradual Migration

Migrate one application at a time:

**Week 1:** Enable for Cursor only

```nix
{
  theming.scientific = {
    enable = true;
    mode = "dark";
    applications = {
      cursor.enable = true;
      helix.enable = false;
      zed.enable = false;
      ghostty.enable = false;
      gtk.enable = false;
      niri.enable = false;
    };
  };
}
```

**Week 2:** Add Helix

```nix
{
  theming.scientific.applications = {
    cursor.enable = true;
    helix.enable = true;  # Added
    # ... rest false
  };
}
```

And so on...

## Platform-Specific Examples

### Example 9: NixOS Configuration

**File:** `hosts/my-nixos-box/configuration.nix`

```nix
{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  host = {
    username = "myuser";
    features.desktop = {
      enable = true;
      niri = true;  # Enable Niri compositor
      scientificTheme = {
        enable = true;
        mode = "dark";
      };
    };
  };

  # The theme will automatically apply to:
  # - Cursor, Helix, Zed (editors)
  # - Ghostty (terminal)
  # - GTK applications (system-wide)
  # - Niri (window manager colors)
}
```

### Example 10: macOS (nix-darwin) Configuration

**File:** `hosts/my-macbook/configuration.nix`

```nix
{ config, pkgs, ... }:
{
  host = {
    username = "myuser";
    features.desktop = {
      enable = true;
      scientificTheme = {
        enable = true;
        mode = "dark";
      };
    };
  };

  # On macOS, GTK and Niri are automatically disabled
  # Theme applies to:
  # - Cursor, Helix, Zed (editors)
  # - Ghostty (terminal, if enabled)
}
```

## Testing and Verification

### Example 11: Test Theme in Development Shell

Create a temporary shell to test theme files:

```bash
# Enter a shell with theme packages
nix develop

# Check generated theme files
ls -la ~/.config/Cursor/User/themes/
cat ~/.config/Cursor/User/themes/scientific-dark.json | jq '.colors | keys'

# Check Helix theme
helix --health
```

### Example 12: Verify Color Values

Use the Scientific Theme library in a Nix REPL:

```bash
nix repl
```

```nix
:l <nixpkgs>
palette = import ./modules/shared/theming/palette.nix { inherit lib; }
palette.tonal.dark.base-L015
# => { l = 0.15; c = 0.01; h = 240; hex = "#1e1f26"; rgb = { r = 30; g = 31; b = 38; }; }
```

## Troubleshooting Examples

### Example 13: Debug Theme Not Applied

```nix
{
  # Enable verbose output
  theming.scientific = {
    enable = true;
    mode = "dark";
  };

  # Check that home-manager is working
  assertions = [{
    assertion = config.home-manager.users ? ${config.host.username};
    message = "Home-manager user configuration is missing";
  }];

  # Verify theme palette is accessible
  _module.args.scientificPalette = lib.mkForce (
    (import ./modules/shared/theming/lib.nix {
      inherit lib;
      palette = import ./modules/shared/theming/palette.nix { inherit lib; };
    }).generateTheme "dark"
  );
}
```

### Example 14: Force Rebuild Theme Files

If theme files aren't updating, force a rebuild:

```bash
# Remove existing theme files
rm -rf ~/.config/Cursor/User/themes/scientific-*.json
rm -rf ~/.config/zed/themes/scientific.json
rm -rf ~/.config/gtk-3.0/gtk.css
rm -rf ~/.config/gtk-4.0/gtk.css

# Rebuild system
nixos-rebuild switch --flake .#my-host
# or
darwin-rebuild switch --flake .#my-host

# Restart applications
```

## Real-World Configurations

### Example 15: Developer Workstation

Full-featured development setup:

```nix
{
  host = {
    username = "dev";
    features = {
      desktop = {
        enable = true;
        niri = true;
        utilities = true;
        scientificTheme = {
          enable = true;
          mode = "dark";
        };
      };
      development = {
        enable = true;
        rust = true;
        python = true;
        node = true;
        helix = true;
      };
    };
  };
}
```

### Example 16: Content Creator Setup

Light mode for content creation:

```nix
{
  host = {
    username = "creator";
    features = {
      desktop = {
        enable = true;
        scientificTheme = {
          enable = true;
          mode = "light";  # Better for photo/video editing
        };
      };
      media = {
        enable = true;
        video.editing = true;
        audio.production = true;
      };
    };
  };
}
```

### Example 17: Minimal Terminal-Only Setup

Theme only terminal applications:

```nix
{
  host = {
    username = "minimalist";
    features = {
      desktop = {
        enable = true;
        scientificTheme = {
          enable = true;
          mode = "dark";
        };
      };
    };
  };

  # Disable GUI apps, keep terminal themed
  theming.scientific.applications = {
    cursor.enable = false;
    helix.enable = true;   # Terminal editor
    zed.enable = false;
    ghostty.enable = true; # Terminal emulator
    gtk.enable = false;
    niri.enable = false;
  };
}
```

## Migration Examples



## Custom Theme Examples

### Example 19: Create a Custom Variant

Create a custom color variant by overriding multiple colors:

```nix
{
  theming.scientific = {
    enable = true;
    mode = "dark";

    # Create a "warm" variant with more orange/red tones
    overrides = {
      "accent-primary" = {
        l = 0.68;
        c = 0.20;
        h = 40.0;  # More orange
        hex = "#d17a5f";
      };
      "accent-focus" = {
        l = 0.68;
        c = 0.18;
        h = 315.0;  # More magenta
        hex = "#d985c2";
      };
    };
  };
}
```

### Example 20: High Contrast Mode

Create a higher contrast version:

```nix
{
  theming.scientific = {
    enable = true;
    mode = "dark";

    overrides = {
      # Darker background
      "surface-base" = {
        l = 0.10;
        c = 0.01;
        h = 240.0;
        hex = "#131419";
      };
      # Brighter text
      "text-primary" = {
        l = 0.90;
        c = 0.05;
        h = 240.0;
        hex = "#e5e7f0";
      };
    };
  };
}
```

## Summary

These examples cover:

- ? Basic theme enabling (dark/light)
- ? Selective application theming
- ? Advanced customization
- ? Platform-specific configurations
- ? Integration with existing themes
- ? Migration strategies
- ? Troubleshooting techniques
- ? Real-world use cases

For more details, see the main [Scientific Theme documentation](../SCIENTIFIC_THEME.md).
