# Architecture

Understanding how Signal applies colors to your Nix environment through Home Manager.

## Table of Contents

- [Overview](#overview)
- [Component Architecture](#component-architecture)
- [Data Flow](#data-flow)
- [Module System](#module-system)
- [Color Resolution](#color-resolution)
- [Integration Points](#integration-points)
- [Extension Patterns](#extension-patterns)

## Overview

Signal is a Home Manager module that applies colors from the Signal Design System to your applications. It follows a simple architecture:

```
┌─────────────────────────────────────────────┐
│  Your Configuration                         │
│  ├─ programs.*.enable = true                │
│  └─ theming.signal.enable = true            │
└────────────────┬────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│  Signal Module System                       │
│  ├─ Detects enabled programs                │
│  ├─ Resolves theme mode (dark/light)        │
│  ├─ Loads colors from signal-palette        │
│  └─ Applies colors to program configs       │
└────────────────┬────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│  Home Manager Activation                    │
│  └─ Generates config files with colors      │
└─────────────────────────────────────────────┘
```

### Key Principles

1. **Color-Only Scope**: Signal only sets colors, never program behavior or installation
2. **Lazy Evaluation**: Modules only evaluate when enabled
3. **Declarative**: All color configuration is reproducible
4. **Composable**: Works alongside other Home Manager modules

## Component Architecture

```
signal-nix/
│
├─ flake.nix                    # Flake outputs and module exports
│
├─ lib/
│  ├─ default.nix               # Color conversion and utility helpers
│  │  ├─ resolveThemeMode       # Convert "auto" to "dark" or "light"
│  │  ├─ getColors              # Get colors for a mode
│  │  ├─ hexToRgbSpaceSeparated # RGB conversion (for Zellij)
│  │  ├─ hexWithAlpha           # Add alpha channel (for Fuzzel)
│  │  └─ isValidHexColor        # Validate hex format
│  │
│  └─ mkAppModule.nix           # Module generator helpers (NEW)
│     ├─ mkTier1Module          # For native theme support
│     ├─ mkTier2Module          # For structured colors
│     ├─ mkTier3Module          # For freeform settings
│     ├─ mkTier4Module          # For raw config
│     ├─ makeAnsiColors         # Standard ANSI palette
│     ├─ makeUIColors           # Common UI colors
│     └─ Validation helpers     # Color format checking
│
├─ modules/
│  ├─ common/
│  │  └─ default.nix            # Core module system
│  │     ├─ Options             # Define theming.signal.*
│  │     ├─ Imports             # Import all app modules
│  │     └─ Config              # Pass colors to modules
│  │
│  ├─ editors/
│  │  ├─ helix.nix              # Helix color theming
│  │  └─ neovim.nix             # Neovim color theming
│  │
│  ├─ terminals/
│  │  ├─ kitty.nix              # Kitty color theming
│  │  ├─ ghostty.nix            # Ghostty color theming
│  │  └─ ...
│  │
│  └─ ...                        # Other categories
│
└─ examples/                     # Example configurations
```

### Module Types

**Common Module** (`modules/common/default.nix`):
- Defines all options under `theming.signal`
- Imports all application-specific modules
- Provides Signal colors to child modules
- Handles global configuration (mode, autoEnable)

**Application Modules** (e.g., `modules/editors/helix.nix`):
- Receives colors via `_module.args`
- Implements `shouldTheme` logic (explicit enable or autoEnable)
- Generates application-specific color configuration
- Uses `mkIf` guards for conditional evaluation

## Data Flow

### Configuration Phase

```
1. User defines configuration
   ├─ programs.helix.enable = true
   └─ theming.signal.enable = true

2. Flake evaluation
   ├─ Load signal-nix flake
   ├─ Import signal-palette dependency
   └─ Make modules available

3. Home Manager evaluation
   ├─ Import signal.homeManagerModules.default
   ├─ Evaluate modules/common/default.nix
   │  ├─ Create options (theming.signal.*)
   │  ├─ Import all app modules
   │  └─ Set _module.args with colors
   │
   └─ Evaluate application modules
      ├─ Check if should theme (shouldTheme logic)
      ├─ If yes: Generate color configuration
      └─ If no: No-op (mkIf guard)

4. Configuration generation
   └─ Home Manager generates config files
      ├─ ~/.config/helix/config.toml
      ├─ ~/.config/kitty/kitty.conf
      └─ ...
```

### Color Resolution Flow

```
User sets mode → resolveThemeMode → getColors → Apply to apps
     ↓
  "dark"     →      "dark"      →   Signal   →  program
  "light"    →      "light"     →   palette  →  color
  "auto"     →      "dark"      →   colors   →  configs
```

### shouldTheme Logic

Each application module implements this pattern:

```nix
let
  shouldTheme =
    cfg.<category>.<app>.enable ||              # Explicit enable
    (cfg.autoEnable &&                           # OR autoEnable
     (config.programs.<app>.enable or false));   # AND program enabled
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    # Apply theming
  };
}
```

**Truth table:**

| Signal enabled | autoEnable | Explicit enable | Program enabled | Result |
|---------------|------------|-----------------|-----------------|--------|
| ✅ | ✅ (default) | ❌ | ✅ | ✅ Theme applied |
| ✅ | ✅ (default) | ❌ | ❌ | ❌ No theme |
| ✅ | ✅ (default) | `false` | ✅ | ❌ No theme (explicit disable) |
| ✅ | ❌ (opt-out) | ❌ | ✅ | ❌ No theme |
| ✅ | ❌ (opt-out) | ✅ | ✅ | ✅ Theme applied |
| ✅ | ❌ (opt-out) | ✅ | ❌ | ✅ Theme applied* |

*Note: Explicit enable themes even if program not enabled (may cause errors)

**Key changes:**
- `autoEnable` now defaults to `true` (automatic theming is the default behavior)
- Most users will use the first row: Signal enabled + autoEnable (default) + program enabled = themed
- To opt-out of automatic theming, set `autoEnable = false`

## Module System

### Option Definition

Options are defined in `modules/common/default.nix`:

```nix
options.theming.signal = {
  enable = mkEnableOption "Signal Design System";

  autoEnable = mkOption {
    type = types.bool;
    default = true;  # ← Changed: Automatic theming is now default
    description = "Automatically theme all enabled programs";
  };

  mode = mkOption {
    type = types.enum ["light" "dark" "auto"];
    default = "dark";
  };

  # Per-app options
  editors.helix.enable = mkEnableOption "Signal theme for Helix";
  # ... more options
};
```

### Module Arguments

Colors and utilities are passed to child modules via `_module.args`:

```nix
config = lib.mkIf cfg.enable {
  _module.args = {
    signalPalette = palette;
    signalLib = import ../../lib { inherit lib palette; };
    signalColors = signalLib.getColors (signalLib.resolveThemeMode cfg.mode);
  };
};
```

Child modules receive these automatically:

```nix
{
  config,
  lib,
  signalColors,      # ← Available via _module.args
  signalLib,         # ← Available via _module.args
  ...
}:
```

### Application Module Pattern

Standard pattern for application modules:

```nix
{
  config,
  lib,
  signalColors,
  signalLib,
  ...
}:

let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Map Signal colors to app-specific structure
  colors = {
    background = signalColors.tonal."surface-Lc05".hex;
    foreground = signalColors.tonal."text-Lc75".hex;
    accent = signalColors.accent.focus.Lc75.hex;
  };

  # Generate app configuration
  appConfig = {
    theme = {
      background = colors.background;
      foreground = colors.foreground;
      # ... more config
    };
  };

  # Determine if should theme
  shouldTheme =
    cfg.<category>.<app>.enable ||
    (cfg.autoEnable && (config.programs.<app>.enable or false));
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.<app> = appConfig;
  };
}
```

## Color Resolution

### Signal Palette Structure

Colors come from the `signal-palette` flake:

```
signal-palette/
└─ palette.nix
   ├─ tonal
   │  ├─ dark
   │  │  ├─ surface-Lc05  { l, c, h, hex, ... }
   │  │  ├─ text-Lc75     { l, c, h, hex, ... }
   │  │  └─ ...
   │  └─ light
   │     ├─ surface-Lc90  { l, c, h, hex, ... }
   │     └─ ...
   │
   ├─ accent
   │  ├─ focus
   │  │  ├─ Lc75  { l, c, h, hex, ... }
   │  │  └─ ...
   │  ├─ danger
   │  ├─ success
   │  └─ ...
   │
   └─ categorical
      ├─ dark
      │  ├─ GA01  { l, c, h, hex, ... }
      │  └─ ...
      └─ light
```

### Color Object Structure

Each color is an attribute set:

```nix
{
  l = 0.75;                           # Lightness (0-1)
  c = 0.12;                           # Chroma
  h = 240;                            # Hue (0-360)
  hex = "#a8b9cf";                    # Hex color
  hexRaw = "a8b9cf";                  # Hex without #
  rgb = { r = 168; g = 185; b = 207; }; # RGB values
}
```

### Accessing Colors

**In application modules:**

```nix
signalColors.tonal."surface-Lc05".hex        # "#0a0d12"
signalColors.tonal."text-Lc75".hex           # "#c5cdd8"
signalColors.accent.focus.Lc75.hex           # "#5a8dcf"
signalColors.categorical.GA02.hex            # "#6ba875"
```

**Color naming convention:**

- `surface-Lc05` = Surface color, Lightness/Chroma level 05
- `text-Lc75` = Text color, Lightness/Chroma level 75
- `GA02` = Categorical color, Group A, slot 02

### High-Fidelity Color Conversion

Signal uses [nix-colorizer](https://github.com/nutsalhan87/nix-colorizer) for accurate color format conversions. This ensures colors maintain maximum fidelity across different application formats.

**Why nix-colorizer?**

- **OKLCh Color Space**: Uses perceptually uniform OKLCh instead of RGB for color math
- **Accurate Conversions**: Proper hex ↔ sRGB ↔ OKLCh conversion with alpha channel support
- **Pure Nix**: No external dependencies, fully evaluated at build time
- **High Precision**: Maintains color accuracy for professional design systems

**Available conversion utilities** (in `lib/default.nix`):

```nix
# Convert hex to space-separated RGB (0-255 range)
# Used by: Zellij
signalLib.hexToRgbSpaceSeparated color
# Example: "#6b87c8" → "107 135 200"

# Add alpha channel in RRGGBBAA format (no # prefix)
# Used by: Fuzzel
signalLib.hexWithAlpha color alpha
# Example: color="#6b87c8" alpha=0.949 → "6b87c8f2"

# Validate hex color format
signalLib.isValidHexColor str
# Example: "#6b87c8" → true, "invalid" → false
```

**Example usage in application modules:**

```nix
# Zellij: requires RGB space-separated
let
  toZellijColor = signalLib.hexToRgbSpaceSeparated;
in {
  themes.signal = {
    text_unselected.base = toZellijColor colors.text-primary;
    # Result: "197 205 216"
  };
}

# Fuzzel: requires RRGGBBAA format
let
  withAlpha = color: alpha: signalLib.hexWithAlpha color alpha;
in {
  colors = {
    background = withAlpha colors.background 0.949;  # 95% opacity
    text = withAlpha colors.text 1.0;                # Fully opaque
    # Results: "1a1c22f2", "c5cdd8ff"
  };
}
```

**Color conversion flow:**

```
Signal Palette (LCH)
        ↓
    Color Object
    { l, c, h, hex, hexRaw, rgb }
        ↓
 nix-colorizer conversion
    hex → OKLCh → sRGB
        ↓
Application-specific format
    - Zellij: "R G B"
    - Fuzzel: "RRGGBBAA"
    - Others: "#RRGGBB"
```

This architecture ensures that colors maintain their intended appearance across all applications, regardless of the target format requirements.

## Integration Points

### Home Manager Integration

Signal integrates with Home Manager through the module system:

```
Home Manager
    ├─ programs.*                    # Program installation
    │  └─ <app>.enable = true        # User enables programs
    │
    └─ theming.signal.*              # Signal theming
       ├─ enable = true              # User enables Signal
       ├─ autoEnable = true          # Auto-detect programs
       └─ mode = "dark"              # Theme mode

Home Manager builds configuration
    ├─ Evaluates all modules
    ├─ Generates config files
    └─ Activates new generation
```

### NixOS Integration

Signal works with Home Manager as a NixOS module:

```
NixOS System
    ├─ home-manager.nixosModules.home-manager
    │  └─ home-manager.users.<user>
    │     ├─ imports = [ signal.homeManagerModules.default ]
    │     └─ theming.signal.*
    │
    └─ nixos-rebuild switch
       └─ Activates system + home-manager
```

### Nix-darwin Integration

Same pattern for macOS:

```
nix-darwin System
    ├─ home-manager.darwinModules.home-manager
    │  └─ home-manager.users.<user>
    │     ├─ imports = [ signal.homeManagerModules.default ]
    │     └─ theming.signal.*
    │
    └─ darwin-rebuild switch
```

## Extension Patterns

### Adding a New Application

1. **Create module file** (`modules/<category>/<app>.nix`):

```nix
{
  config,
  lib,
  signalColors,
  signalLib,
  ...
}:

let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Map colors
  appTheme = {
    # Your color mappings
  };

  shouldTheme =
    cfg.<category>.<app>.enable ||
    (cfg.autoEnable && (config.programs.<app>.enable or false));
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.<app> = appTheme;
  };
}
```

2. **Add option** in `modules/common/default.nix`:

```nix
options.theming.signal.<category>.<app> = {
  enable = mkEnableOption "Signal theme for App";
};
```

3. **Import module** in `modules/common/default.nix`:

```nix
imports = [
  # ... existing imports
  ../../modules/<category>/<app>.nix
];
```

### Custom Color Mappings

Access Signal colors in your own modules:

```nix
{ config, ... }:

let
  signalColors = config.theming.signal.colors;
in
{
  programs.my-app.colors = {
    bg = signalColors.tonal."surface-Lc05".hex;
    fg = signalColors.tonal."text-Lc75".hex;
  };
}
```

### Theme Variants

Future support for theme variants (high-contrast, color-blind-friendly):

```nix
options.theming.signal.variant = mkOption {
  type = types.nullOr (types.enum [
    "default"
    "high-contrast"
    "reduced-motion"
    "color-blind-friendly"
  ]);
  default = null;
};
```

## Performance Considerations

### Lazy Evaluation

Modules use guards to avoid unnecessary evaluation:

```nix
config = mkIf (cfg.enable && shouldTheme) {
  # Only evaluated if condition is true
};
```

### Module System Overhead

Signal adds minimal overhead:

- **~20 module evaluations** (one per app category)
- **Each module**: O(1) if disabled (mkIf guard)
- **Total overhead**: ~100ms for full evaluation

### Build Times

Signal doesn't affect package build times:

- No package rebuilds
- Only config file generation
- Home Manager activation: ~1-2 seconds

## Debugging

### Checking Evaluation

```bash
# Check if Signal is enabled
nix eval .#homeConfigurations.user.config.theming.signal.enable

# Check theme mode
nix eval .#homeConfigurations.user.config.theming.signal.mode

# Check specific app theming
nix eval .#homeConfigurations.user.config.programs.helix.settings.theme
```

### Tracing Module Evaluation

```bash
# Show evaluation trace
nix build --show-trace .#homeConfigurations.user.activationPackage

# Check module imports
nix-instantiate --eval --strict -E '
  let
    config = import ./. {};
  in
    config.homeConfigurations.user.config._module.args
'
```

## Architecture Decisions

### Why Home Manager?

- User-level theming belongs in user-level config
- Declarative and reproducible color management
- Works across NixOS, nix-darwin, and standalone
- Rich ecosystem of program modules to theme

### Why Separate signal-palette?

- Platform-agnostic colors (use Signal colors in web apps, design tools)
- Independent versioning of colors
- Stable color API across platforms
- Reusable across projects beyond Nix

### Why autoEnable?

- Reduces configuration burden
- Matches user expectation ("theme my programs")
- Still allows fine-grained control
- Provides sensible defaults

## Next Steps

- **Using Signal** - See [Configuration Guide](configuration-guide.md) for all options
- **Contributing** - Add new app support ([CONTRIBUTING.md](../CONTRIBUTING.md))
- **Advanced Usage** - See [Advanced Usage](advanced-usage.md)
