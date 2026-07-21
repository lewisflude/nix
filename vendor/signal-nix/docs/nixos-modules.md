# NixOS System Theming

Signal provides NixOS modules for system-level theming including boot screens, display managers, and console colors.

## Overview

Signal's NixOS modules theme:

- **Virtual Console (TTY)** - Colored text in Ctrl+Alt+F1-F6
- **GRUB Bootloader** - Themed boot menu
- **Plymouth** - Animated boot splash screen
- **Display Managers** - GDM, SDDM, LightDM login screens

These modules are separate from Home Manager modules and theme system-level components.

## Quick Start

### Basic Setup

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    signal.url = "github:lewisflude/signal-nix";
  };

  outputs = { nixpkgs, signal, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        signal.nixosModules.default
        {
          theming.signal.nixos = {
            enable = true;
            mode = "dark";

            boot = {
              console.enable = true;
              grub.enable = true;
              plymouth.enable = true;
            };

            login = {
              gdm.enable = true;
            };
          };

          # Your existing NixOS config
          boot.loader.grub.enable = true;
          services.xserver.displayManager.gdm.enable = true;
        }
      ];
    };
  };
}
```

## Module Structure

### NixOS vs Home Manager

Signal has two separate module systems:

```
signal-nix
├── homeManagerModules.default  → User-level theming
│   └── Applications (editors, terminals, etc.)
│
└── nixosModules.default        → System-level theming
    └── System components (boot, login, console)
```

**Important:** These are independent. You can use one or both:

```nix
{
  # System-level theming
  imports = [ signal.nixosModules.default ];
  theming.signal.nixos.enable = true;

  # User-level theming
  home-manager.users.you = {
    imports = [ signal.homeManagerModules.default ];
    theming.signal.enable = true;
  };
}
```

## Boot Components

### Virtual Console (TTY)

Theme the Linux virtual console (Ctrl+Alt+F1-F6):

```nix
{
  theming.signal.nixos = {
    enable = true;
    mode = "dark";

    boot.console.enable = true;
  };
}
```

**What this does:**
- Sets console colors for TTY1-6
- Applies Signal's 16-color ANSI palette
- Improves readability of console text

**Requirements:**
- None (works on all NixOS systems)

### GRUB Bootloader

Theme the GRUB boot menu:

```nix
{
  theming.signal.nixos = {
    enable = true;
    mode = "dark";

    boot.grub.enable = true;
  };

  # GRUB must be enabled
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";  # or "nodev" for UEFI
  };
}
```

**What this does:**
- Custom GRUB theme with Signal colors
- Themed menu entries and selection
- Signal-styled boot menu

**Requirements:**
- `boot.loader.grub.enable = true`

**Customization:**

```nix
{
  theming.signal.nixos.boot.grub = {
    enable = true;
    # Additional GRUB options can be set via boot.loader.grub.*
  };
}
```

### Plymouth Boot Splash

Animated boot splash screen:

```nix
{
  theming.signal.nixos = {
    enable = true;
    mode = "dark";

    boot.plymouth.enable = true;
  };

  # Plymouth must be enabled
  boot.plymouth.enable = true;
}
```

**What this does:**
- Signal-themed boot animation
- Smooth transition to login screen
- Hides boot messages with themed splash

**Requirements:**
- `boot.plymouth.enable = true`

**Customization:**

```nix
{
  theming.signal.nixos.boot.plymouth = {
    enable = true;
    # Additional Plymouth options via boot.plymouth.*
  };
}
```

## Login Components

### GDM (GNOME Display Manager)

Theme the GNOME login screen:

```nix
{
  theming.signal.nixos = {
    enable = true;
    mode = "dark";

    login.gdm.enable = true;
  };

  # GDM must be enabled
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
  };
}
```

**What this does:**
- Signal colors for GDM login screen
- Themed user selection and password prompt
- Consistent with Signal desktop theme

**Requirements:**
- `services.xserver.displayManager.gdm.enable = true`

### SDDM (Simple Desktop Display Manager)

Theme the SDDM login screen:

```nix
{
  theming.signal.nixos = {
    enable = true;
    mode = "dark";

    login.sddm.enable = true;
  };

  # SDDM must be enabled
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
  };
}
```

**What this does:**
- Custom SDDM theme with Signal colors
- Themed login form and background
- Signal-styled user interface

**Requirements:**
- `services.xserver.displayManager.sddm.enable = true`

### LightDM

Theme the LightDM login screen:

```nix
{
  theming.signal.nixos = {
    enable = true;
    mode = "dark";

    login.lightdm.enable = true;
  };

  # LightDM must be enabled
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
  };
}
```

**What this does:**
- Signal colors for LightDM greeter
- Themed login interface
- Consistent with Signal theme

**Requirements:**
- `services.xserver.displayManager.lightdm.enable = true`

## Complete Configuration

### Full System Theming

Theme everything at the system level:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    signal.url = "github:lewisflude/signal-nix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, signal, home-manager, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        signal.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          # System-level Signal theming
          theming.signal.nixos = {
            enable = true;
            mode = "dark";

            boot = {
              console.enable = true;
              grub.enable = true;
              plymouth.enable = true;
            };

            login = {
              gdm.enable = true;
            };
          };

          # System configuration
          boot = {
            loader.grub = {
              enable = true;
              device = "/dev/sda";
            };
            plymouth.enable = true;
          };

          services.xserver = {
            enable = true;
            displayManager.gdm.enable = true;
            desktopManager.gnome.enable = true;
          };

          # User-level Signal theming
          home-manager.users.yourusername = {
            imports = [ signal.homeManagerModules.default ];

            theming.signal = {
              enable = true;
              autoEnable = true;
              mode = "dark";
            };

            programs = {
              helix.enable = true;
              kitty.enable = true;
              # ... your programs
            };
          };
        }
      ];
    };
  };
}
```

## Configuration Options

### All NixOS Options

```nix
theming.signal.nixos = {
  # Core options
  enable = true;              # Enable NixOS theming
  mode = "dark";              # "light" or "dark"

  # Boot components
  boot = {
    console = {
      enable = true;          # Theme virtual console
    };

    grub = {
      enable = true;          # Theme GRUB bootloader
    };

    plymouth = {
      enable = true;          # Theme boot splash
    };
  };

  # Login components
  login = {
    gdm = {
      enable = true;          # Theme GDM
    };

    sddm = {
      enable = true;          # Theme SDDM
    };

    lightdm = {
      enable = true;          # Theme LightDM
    };
  };
};
```

## Theme Modes

Like Home Manager modules, NixOS modules support light and dark modes:

```nix
# Dark mode (default)
theming.signal.nixos.mode = "dark";

# Light mode
theming.signal.nixos.mode = "light";
```

The mode affects:
- Console colors
- GRUB theme colors
- Plymouth splash colors
- Display manager theme colors

## Conditional Theming

Enable components conditionally:

```nix
{ config, lib, ... }:

{
  theming.signal.nixos = {
    enable = true;
    mode = "dark";

    boot = {
      # Only theme GRUB if it's enabled
      grub.enable = config.boot.loader.grub.enable;

      # Only theme Plymouth if it's enabled
      plymouth.enable = config.boot.plymouth.enable;
    };

    login = {
      # Only theme the enabled display manager
      gdm.enable = config.services.xserver.displayManager.gdm.enable;
      sddm.enable = config.services.xserver.displayManager.sddm.enable;
      lightdm.enable = config.services.xserver.displayManager.lightdm.enable;
    };
  };
}
```

## Troubleshooting

### GRUB theme not showing

1. **Verify GRUB is enabled:**
   ```nix
   boot.loader.grub.enable = true;
   ```

2. **Check Signal GRUB is enabled:**
   ```nix
   theming.signal.nixos.boot.grub.enable = true;
   ```

3. **Rebuild and reboot:**
   ```bash
   sudo nixos-rebuild switch
   sudo reboot
   ```

### Plymouth not showing

1. **Verify Plymouth is enabled:**
   ```nix
   boot.plymouth.enable = true;
   ```

2. **Check Signal Plymouth is enabled:**
   ```nix
   theming.signal.nixos.boot.plymouth.enable = true;
   ```

3. **Ensure quiet boot:**
   ```nix
   boot.kernelParams = [ "quiet" "splash" ];
   ```

4. **Rebuild and reboot:**
   ```bash
   sudo nixos-rebuild switch
   sudo reboot
   ```

### Display manager theme not applying

1. **Verify display manager is enabled:**
   ```nix
   services.xserver.displayManager.<dm>.enable = true;
   ```

2. **Check Signal DM is enabled:**
   ```nix
   theming.signal.nixos.login.<dm>.enable = true;
   ```

3. **Rebuild and restart display manager:**
   ```bash
   sudo nixos-rebuild switch
   sudo systemctl restart display-manager
   ```

### Console colors not showing

1. **Verify console theming is enabled:**
   ```nix
   theming.signal.nixos.boot.console.enable = true;
   ```

2. **Rebuild:**
   ```bash
   sudo nixos-rebuild switch
   ```

3. **Switch to a TTY:**
   Press `Ctrl+Alt+F2` to see console colors

## Examples

See [examples/nixos-complete.nix](../examples/nixos-complete.nix) for a complete NixOS configuration with Signal system theming.

## Next Steps

- **[Getting Started](getting-started.md)** - Setup guide
- **[Configuration Guide](configuration-guide.md)** - Home Manager options
- **[Examples](../examples/)** - Real-world configurations
- **[Troubleshooting](troubleshooting.md)** - Common issues
