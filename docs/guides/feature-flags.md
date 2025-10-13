# Feature Flags Guide

Feature flags allow you to enable/disable modules and features in your configuration without commenting out imports.

## Overview

The feature flag system is defined in `lib/features.nix` and provides utilities for creating toggleable features.

## Basic Usage

### Creating a Feature Option

In a module:

```nix
{ config, lib, pkgs, ... }:
let
  featureLib = import ../lib/features.nix { inherit lib; };
in {
  options.features.gaming = featureLib.mkFeature "gaming" false "Enable gaming support";

  config = lib.mkIf config.features.gaming.enable {
    programs.steam.enable = true;
    hardware.opengl.driSupport32Bit = true;
  };
}
```

### Using Feature Flags in Host Configuration

In `hosts/your-host/configuration.nix`:

```nix
{
  features = {
    gaming.enable = true;
    development.enable = true;
    homeServer.enable = false;
  };
}
```

## Available Helpers

### `mkFeature`

Create a single feature option.

```nix
options.features.myFeature = featureLib.mkFeature 
  "myFeature"    # name
  true           # default value
  "Description"; # description
```

### `mkFeatures`

Create multiple feature options at once.

```nix
options.features = featureLib.mkFeatures {
  gaming = true;
  development = true;
  homeServer = false;
};
```

### `mkFeatureModule`

Create a complete feature module with options and config.

```nix
featureLib.mkFeatureModule {
  name = "gaming";
  description = "Enable gaming support";
  default = false;
  config = {
    programs.steam.enable = true;
    hardware.opengl.enable = true;
  };
}
```

### `featureEnabled`

Check if a feature is enabled.

```nix
let
  gamingEnabled = featureLib.featureEnabled config "gaming";
in
  lib.mkIf gamingEnabled { ... }
```

### `withFeature`

Conditionally include modules based on features.

```nix
imports = featureLib.withFeature config "gaming" [
  ./gaming/steam.nix
  ./gaming/proton.nix
];
```

### `mkPlatformFeature`

Create a platform-specific feature.

```nix
options.features.macosApps = featureLib.mkPlatformFeature {
  platform = "darwin";
  name = "macosApps";
  default = true;
  description = "Enable macOS-specific applications";
};
```

## Example: Gaming Feature Module

`modules/nixos/features/gaming.nix`:

```nix
{ config, lib, pkgs, ... }:
let
  featureLib = import ../../../lib/features.nix { inherit lib; };
  cfg = config.features.gaming;
in {
  options.features.gaming = {
    enable = lib.mkEnableOption "gaming support";
    steam = lib.mkEnableOption "Steam" // { default = true; };
    lutris = lib.mkEnableOption "Lutris" // { default = false; };
    gamemode = lib.mkEnableOption "GameMode" // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    programs.steam.enable = lib.mkIf cfg.steam true;
    
    environment.systemPackages = with pkgs; 
      [ ] 
      ++ lib.optionals cfg.lutris [ lutris ]
      ++ lib.optionals cfg.gamemode [ gamemode ];

    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
  };
}
```

Usage in host config:

```nix
{
  features.gaming = {
    enable = true;
    steam = true;
    lutris = true;
    gamemode = true;
  };
}
```

## Example: Development Feature

`modules/shared/features/development.nix`:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.features.development;
in {
  options.features.development = {
    enable = lib.mkEnableOption "development tools";
    languages = {
      python = lib.mkEnableOption "Python" // { default = true; };
      javascript = lib.mkEnableOption "JavaScript" // { default = true; };
      rust = lib.mkEnableOption "Rust" // { default = false; };
      go = lib.mkEnableOption "Go" // { default = false; };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      [ git gh ]
      ++ lib.optionals cfg.languages.python [ python3 poetry ]
      ++ lib.optionals cfg.languages.javascript [ nodejs yarn ]
      ++ lib.optionals cfg.languages.rust [ rustc cargo ]
      ++ lib.optionals cfg.languages.go [ go gopls ];
  };
}
```

Usage:

```nix
{
  features.development = {
    enable = true;
    languages = {
      python = true;
      javascript = true;
      rust = true;
      go = false;
    };
  };
}
```

## Best Practices

### 1. Feature Organization

Organize features by domain:

```
modules/
├── features/
│   ├── gaming.nix
│   ├── development.nix
│   ├── home-server.nix
│   └── media-center.nix
```

### 2. Sensible Defaults

Set defaults based on common use cases:

```nix
# Development machine defaults
features.development.enable = true;  # Most users want dev tools
features.gaming.enable = false;      # Not everyone games

# Server defaults
features.homeServer.enable = true;   # Primary purpose
features.desktop.enable = false;     # Servers don't need GUI
```

### 3. Feature Dependencies

Handle dependencies explicitly:

```nix
config = lib.mkIf cfg.enable {
  # Ensure required features are enabled
  assertions = [
    {
      assertion = config.features.networking.enable;
      message = "Home server requires networking feature to be enabled";
    }
  ];
};
```

### 4. Documentation

Document each feature:

```nix
options.features.myFeature = {
  enable = lib.mkEnableOption "my feature" // {
    description = ''
      Enables my feature which provides:
      - Thing 1
      - Thing 2
      
      Note: This requires X to be installed.
    '';
  };
};
```

## Migration Guide

### From Commented Imports

**Before:**
```nix
imports = [
  ./gaming.nix
  # ./development.nix  # Disabled
  ./system.nix
];
```

**After:**
```nix
imports = [
  ./gaming.nix
  ./development.nix
  ./system.nix
];

features = {
  gaming.enable = true;
  development.enable = false;  # Controlled by flag
};
```

### From Conditional Imports

**Before:**
```nix
imports = 
  [ ./base.nix ]
  ++ lib.optionals (hostname == "gaming-pc") [ ./gaming.nix ];
```

**After:**
```nix
imports = [
  ./base.nix
  ./gaming.nix
];

features.gaming.enable = (hostname == "gaming-pc");
```

## Future Enhancements

Potential improvements to the feature system:

1. **Feature Presets**: Pre-configured feature sets
   ```nix
   features.preset = "gaming-workstation";  # Enables gaming + dev
   ```

2. **Feature Validation**: Automatic conflict detection
   ```nix
   features.conflicts = {
     minimal = [ "gaming" "development" ];  # Can't be minimal with these
   };
   ```

3. **Feature Discovery**: List available features
   ```bash
   nix eval .#features.available
   ```

---

**See Also:**
- [Module Index](../modules/INDEX.md)
- [Architecture Reference](../reference/architecture.md)
