# Signal Color Theme

**Name:** Signal
**Tagline:** Perception, engineered.

**Description:** Signal is a scientific, dual-theme color system where every color is the calculated solution to a functional problem. Built on the principles of perceptual uniformity (Oklch) and accessibility (APCA), its purpose is to create a clear, effortless, and predictable user experience. It is a framework for engineering clarity.

## Overview

The Signal Theme system uses the OKLCH (Oklab Lightness Chroma Hue) color space, which provides:

- **Perceptual Uniformity**: Colors with the same lightness value appear equally bright
- **Predictable Behavior**: Adjusting hue maintains consistent lightness and saturation
- **Accessibility**: Built-in contrast ratios meet WCAG guidelines and APCA (Advanced Perceptual Contrast Algorithm) standards
- **Color Harmony**: Mathematical relationships between hues create natural color schemes
- **Legal Defensibility**: Objective, scientifically-based accessibility framework that provides compliance documentation and reduces legal risk
- **Development Velocity**: Eliminates subjective color debates by providing a single, authoritative color system

## Why Adopt This System?

### 1. Prioritize Adoption for Compliance and Velocity

**Legal and Compliance Benefits:**

- **APCA-Based Framework**: Uses the Advanced Perceptual Contrast Algorithm, the future-proof standard for accessibility contrast measurement
- **WCAG AA/AAA Compliant**: All color combinations meet or exceed WCAG accessibility guidelines
- **Legally Defensible**: Objective, scientific foundation provides documentation trail for accessibility compliance
- **Future-Proof**: APCA is the emerging standard that will replace older contrast measurement methods

**Development Benefits:**

- **Ends Subjective Debates**: No more time-consuming discussions about "which shade of blue looks better"
- **Accelerates Development**: Developers and designers have a single source of truth for all color decisions
- **Consistent Results**: Mathematical color relationships ensure visual consistency across all applications
- **Reduced Rework**: No need to adjust colors later for accessibility compliance

### 2. Brand Governance Policy

The system provides clear governance for handling conflicts between functional colors and brand colors:

- **Functional Colors Take Priority**: Semantic colors (e.g., `accent-danger` for errors) maintain their functional meaning regardless of brand guidelines
- **Brand Colors as Decorative Layer**: Brand-specific colors can be applied as decorative elements that don't interfere with functional semantics
- **Configurable Override Policy**: Choose whether functional colors override brand colors or coexist as separate layers

See the [Brand Governance](#brand-governance-policy) section for detailed configuration options.

### 3. Strict Semantic Token Abstraction

**Critical Rule**: Developers and designers must **only** use semantic tokens (e.g., `bg-accent-danger`, `text-text-primary`). They must **never** directly reference underlying Signal tokens (e.g., `dark-accent-Lc75-h040`).

**Why This Matters:**

- **Automatic Theme Switching**: Semantic tokens automatically adapt to light/dark mode
- **System Integrity**: Prevents breaking changes when the underlying palette is updated
- **Accessibility Guarantees**: Semantic tokens are guaranteed to meet contrast requirements
- **Maintainability**: Changes to the scientific palette propagate automatically through semantic mappings

See the [Semantic Token Usage](#semantic-token-abstraction) section for enforcement details.

## Features

- ? Dual-mode support (light and dark themes)
- ? Semantic color mapping for UI elements
- ? Syntax highlighting optimized for code readability
- ? Terminal ANSI color support
- ? **Comprehensive validation system** with WCAG 2.1 and APCA contrast checking
- ? **Automated accessibility testing** to ensure compliance
- ? Application-specific themes for:
  - Cursor/VS Code
  - Helix editor
  - Zed editor
  - Ghostty terminal
  - GTK applications (Linux)
  - Niri window manager (Linux)

## Quick Start

### Enable the Theme

Add to your host configuration (e.g., `hosts/your-host/configuration.nix`):

```nix
{
  host.features.desktop = {
    enable = true;
    signalTheme = {
      enable = true;
      mode = "dark"; # or "light"
    };
  };
}
```

### Rebuild Your System

```bash
# NixOS
sudo nixos-rebuild switch --flake .#your-host

# macOS (nix-darwin)
darwin-rebuild switch --flake .#your-host
```

## Color Palette

The theme consists of three palette types:

### 1. Tonal Palette

Neutral colors for backgrounds, surfaces, dividers, and text:

**Dark Mode:**

- `base-L015`: Main background (#1e1f26)
- `surface-Lc05`: Subtle surface (#25262f)
- `surface-Lc10`: Emphasized surface (#2d2e39)
- `divider-Lc15`: Primary divider (#353642)
- `divider-Lc30`: Secondary divider (#454759)
- `text-Lc45`: Tertiary text (#6b6f82)
- `text-Lc60`: Secondary text (#9498ab)
- `text-Lc75`: Primary text (#c0c3d1)

**Light Mode:**

- `base-L095`: Main background (#f2f3f7)
- `surface-Lc05`: Subtle surface (#e7e8ed)
- `surface-Lc10`: Emphasized surface (#dcdee6)
- `divider-Lc15`: Primary divider (#d1d3dd)
- `divider-Lc30`: Secondary divider (#b9bcc9)
- `text-Lc45`: Tertiary text (#8b8fa1)
- `text-Lc60`: Secondary text (#5f6378)
- `text-Lc75`: Primary text (#373b4e)

### 2. Accent Palette

Semantic colors for UI actions and states:

- **Primary/Success** (h130): Green (#4db368)
- **Danger/Error** (h040): Red (#d9574a)
- **Warning** (h090): Yellow-Orange (#c9a93a)
- **Info** (h190): Cyan (#5aabb9)
- **Focus** (h240): Blue (#5a7dcf)
- **Special** (h290): Purple (#a368cf)

Each accent color has three variants (Lc75, Lc60, Lc45) for different emphasis levels.

### 3. Categorical Palette

For data visualization and syntax highlighting:

- **GA01**: Red-Orange (#d17a5f) - Strings
- **GA02**: Green (#5dc7a8) - Function calls
- **GA03**: Magenta (#d985c2) - Numbers/Constants
- **GA04**: Yellow-Green (#a7b855) - ANSI Yellow
- **GA05**: Blue (#7a96e0) - Keywords
- **GA06**: Orange (#d59857) - Types
- **GA07**: Cyan (#65b4d9) - ANSI Cyan
- **GA08**: Pink (#e07596) - Special

## Semantic Mappings

The theme provides human-readable semantic names:

### Surface Colors

- `surface-base`: Main background
- `surface-subtle`: Slightly elevated surface
- `surface-emphasis`: More prominent surface

### Text Colors

- `text-primary`: Main text
- `text-secondary`: Less important text
- `text-tertiary`: Muted text (comments, hints)

### Accent Colors

- `accent-primary`: Success, affirmative actions
- `accent-danger`: Errors, destructive actions
- `accent-warning`: Warnings, attention needed
- `accent-info`: Informational messages
- `accent-focus`: Focus indicators
- `accent-special`: Special elements

### Syntax Colors

- `syntax-keyword`: Language keywords (blue)
- `syntax-function-def`: Function definitions (yellow-orange)
- `syntax-function-call`: Function calls (green)
- `syntax-string`: String literals (red-orange)
- `syntax-number`: Numeric constants (magenta)
- `syntax-type`: Type annotations (orange)
- `syntax-variable`: Variables (primary text)
- `syntax-comment`: Comments (tertiary text)
- `syntax-error`: Errors (red)
- `syntax-special`: Special keywords (green)

## Application Support

### Cursor/VS Code

The theme automatically generates a VS Code-compatible theme JSON file and applies it to both Cursor and VS Code.

**Location:** `~/.config/Cursor/User/themes/signal-dark.json`

**Theme Name:** "Signal Dark" (or "Signal Light")

### Helix Editor

Integrated with Helix's native theme system.

**Theme Name:** `signal-dark` (or `signal-light`)

**Activation:** Automatic via `programs.helix.settings.theme`

### Zed Editor

Theme file generated for Zed editor.

**Location:** `~/.config/zed/themes/signal.json`

### Ghostty Terminal

ANSI colors applied to Ghostty terminal settings.

**Features:**

- Full 16-color ANSI palette
- Cursor colors
- Selection colors

### GTK Applications (Linux only)

CSS overrides for GTK3 and GTK4 applications.

**Locations:**

- `~/.config/gtk-3.0/gtk.css`
- `~/.config/gtk-4.0/gtk.css`

### Niri Window Manager (Linux only)

Color configuration for Niri compositor.

**Applied to:**

- Focus rings
- Window borders
- Tab indicators
- Shadows

## Configuration Options

### Basic Configuration

```nix
host.features.desktop.signalTheme = {
  enable = true;
  mode = "dark"; # "light", "dark", or "auto"
};
```

### Advanced Configuration

For fine-grained control, you can configure individual applications:

```nix
theming.signal = {
  enable = true;
  mode = "dark";

  applications = {
    cursor.enable = true;
    helix.enable = true;
    zed.enable = true;
    ghostty.enable = true;
    gtk.enable = true;    # Linux only
    niri.enable = true;   # Linux only, requires Niri
  };
};
```

### Color Overrides (Advanced)

You can override specific colors if needed:

```nix
theming.signal = {
  enable = true;
  mode = "dark";

  overrides = {
    "accent-primary" = {
      l = 0.7;
      c = 0.2;
      h = 130;
      hex = "#4db368";
    };
  };
};
```

?? **Warning**: Overriding colors may result in inconsistent theming and accessibility issues.

### Theme Validation

The Signal theme system includes comprehensive validation to ensure accessibility and completeness. Validation can be enabled to automatically check themes during generation.

#### Basic Validation

```nix
theming.signal = {
  enable = true;
  mode = "dark";

  validation = {
    enable = true;
    level = "AA";  # or "AAA" for enhanced contrast
    validationLevel = "standard";  # "basic", "standard", or "strict"
  };
};
```

#### Validation Options

- **`enable`** (default: `false`): Enable automatic theme validation
- **`strictMode`** (default: `false`): Fail theme generation if validation errors are found
- **`level`** (default: `"AA"`): WCAG contrast level (`"AA"` or `"AAA"`)
- **`validationLevel`** (default: `"standard"`):
  - `"basic"`: Only check theme completeness (required tokens exist)
  - `"standard"`: Check completeness and critical accessibility pairs
  - `"strict"`: Full validation including all color pairs and structure checks
- **`useAPCA`** (default: `false`): Also validate using APCA (Advanced Perceptual Contrast Algorithm)

#### Validation Features

The validation system provides:

- **WCAG 2.1 Compliance**: Automatic contrast ratio calculation and validation
- **APCA Support**: Optional perceptual contrast validation using the Advanced Perceptual Contrast Algorithm
- **Theme Completeness**: Ensures all required semantic tokens are present
- **Accessibility Checks**: Validates critical text/background color pairs meet contrast requirements
- **Detailed Reports**: Human-readable and JSON-formatted validation reports

#### Example: Strict Validation

```nix
theming.signal = {
  enable = true;
  mode = "dark";

  validation = {
    enable = true;
    strictMode = true;  # Fail if validation errors found
    level = "AAA";       # Enhanced contrast requirements
    validationLevel = "strict";  # Full validation
    useAPCA = true;     # Also use APCA validation
  };
};
```

When validation is enabled, the theme object includes a `_validation` attribute with:

- `result`: Validation result (passed/failed, errors, warnings)
- `report`: Human-readable validation report
- `json`: Machine-readable JSON report
- `summary`: Summary statistics

### Brand Governance Policy

The Signal Theme system provides clear governance for handling conflicts between functional colors and brand colors. This is essential to prevent conflicts between brand guidelines and accessibility requirements.

#### Policy Options

##### 1. Functional Colors Override Brand (Default)

- Semantic colors (e.g., `accent-danger` for errors) maintain their functional meaning
- Brand colors are applied only as decorative elements
- Ensures accessibility compliance is never compromised

```nix
theming.signal = {
  enable = true;
  brandGovernance = {
    policy = "functional-override"; # Default
    decorativeBrandColors = {
      # Brand colors used only for decorative elements
      "brand-primary" = "#ff6b35";
      "brand-secondary" = "#004e89";
    };
  };
};
```

##### 2. Brand Colors as Separate Layer

- Functional colors and brand colors coexist
- Brand colors are explicitly marked as decorative-only
- Functional semantics are never overridden by brand

```nix
theming.signal = {
  enable = true;
  brandGovernance = {
    policy = "separate-layer";
    decorativeBrandColors = {
      "brand-primary" = "#ff6b35";
      "brand-secondary" = "#004e89";
    };
  };
};
```

##### 3. Brand Integration (Advanced)

- Brand colors can be integrated into the Signal palette
- Must maintain accessibility compliance
- Requires validation of contrast ratios

```nix
theming.signal = {
  enable = true;
  brandGovernance = {
    policy = "integrated";
    brandColors = {
      "accent-primary" = {
        # Brand color that replaces functional color
        # Must meet WCAG AA contrast requirements
        l = 0.7;
        c = 0.2;
        h = 130;
        hex = "#4db368";
      };
    };
  };
};
```

#### Decision Framework

**When to use "functional-override" (Recommended):**

- Accessibility compliance is critical
- Brand colors don't align with functional semantics
- You want guaranteed accessibility

**When to use "separate-layer":**

- Brand colors are important but not functional
- You need both functional and brand colors
- Brand colors are used for logos, headers, etc.

**When to use "integrated":**

- Brand colors can be adjusted using Signal's scientific methodology
- You've validated contrast ratios
- Brand team approves functional color replacement

### Semantic Token Abstraction

**CRITICAL**: The system enforces strict semantic token abstraction. Developers and designers must **only** use semantic tokens and **never** directly reference underlying Signal tokens.

#### Allowed: Semantic Tokens

? **Use these semantic tokens:**

- `colors."accent-primary"` - Success/affirmative actions
- `colors."accent-danger"` - Errors, destructive actions
- `colors."accent-warning"` - Warnings, attention needed
- `colors."text-primary"` - Main text color
- `colors."text-secondary"` - Less important text
- `colors."surface-base"` - Main background
- `colors."surface-emphasis"` - Elevated surfaces
- `colors."syntax-keyword"` - Code keywords
- `colors."syntax-function-call"` - Function calls
- And all other semantic tokens from `theme.colors`

#### Forbidden: Direct Signal Token Access

? **Never use these directly:**

- `palette.accent.dark.Lc75-h130` - Direct Signal palette token
- `palette.tonal.dark.base-L015` - Direct palette access
- `palette.categorical.dark.GA05` - Direct categorical access

#### Why This Matters

1. **Automatic Theme Switching**: Semantic tokens automatically adapt to light/dark mode
2. **System Integrity**: Prevents breaking changes when the underlying palette is updated
3. **Accessibility Guarantees**: Semantic tokens are guaranteed to meet contrast requirements
4. **Maintainability**: Changes to the Signal palette propagate automatically

#### Example: Correct Usage

```nix
# ? CORRECT: Using semantic tokens
let
  theme = signalPalette;
  errorColor = theme.colors."accent-danger".hex;
  primaryText = theme.colors."text-primary".hex;
in
  # Use errorColor and primaryText in your configuration
```

#### Example: Incorrect Usage

```nix
# ? INCORRECT: Direct access to Signal palette tokens
let
  palette = signalPalette;
  errorColor = palette.accent.dark.Lc75-h040.hex; # DON'T DO THIS
in
  # This breaks theme switching and may violate accessibility
```

#### Enforcement

The system enforces semantic token abstraction through:

1. **API Design**: The primary `theme.colors` API only exposes semantic tokens
2. **Documentation**: Clear warnings in code comments discourage direct palette access
3. **Deprecation Path**: Direct palette access is moved to `_internal` namespace (for internal use only)
4. **Code Review**: Application modules should be reviewed to ensure they use semantic tokens

**Implementation Details:**

- ? `theme.colors` - Primary API (use this)
- ?? `theme.semantic` - Deprecated, use `theme.colors` instead
- ? `theme.tonal`, `theme.accent`, `theme.categorical` - Moved to `theme._internal.*` (internal use only)

Application modules should access colors like this:

```nix
let
  theme = signalPalette;
  colors = theme.colors; # ? CORRECT: Semantic tokens
in
  # Use colors."accent-danger", colors."text-primary", etc.
```

## Switching Between Light and Dark Mode

### System-wide Switch

Update your host configuration:

```nix
host.features.desktop.signalTheme.mode = "light";
```

Then rebuild your system.

### Per-Application (Not Recommended)

While possible, it's recommended to use a consistent mode across all applications for the best user experience.

## Design Principles

### 1. Perceptual Uniformity

All colors at the same lightness level (e.g., Lc75) appear equally bright, reducing visual fatigue and improving readability.

### 2. Semantic Consistency

Color meanings are consistent across applications:

- Green: Success, affirmative, function calls
- Red: Errors, danger, destructive actions
- Blue: Keywords, focus, information
- Yellow/Orange: Warnings, function definitions, types

### 3. Accessibility

All text-background combinations meet WCAG AA contrast requirements:

- Primary text: 7:1 contrast ratio
- Secondary text: 4.5:1 contrast ratio
- Large text: 3:1 contrast ratio

### 4. Code Readability

Syntax highlighting uses distinct hues with consistent saturation:

- Keywords stand out with blue
- Functions are warm-toned (yellow/green/orange)
- Literals (strings, numbers) use distinctive colors
- Comments are muted but readable

## Troubleshooting

### Theme Not Applied

1. Ensure the theme is enabled in your configuration
2. Rebuild your system
3. Restart the affected application
4. Check that `home-manager` is properly configured

### Colors Look Different Between Apps

This is expected if applications use different color spaces. The OKLCH values are consistent; rendering may vary slightly.

### VS Code/Cursor Not Using Theme

1. Check that the theme file exists: `~/.config/Cursor/User/themes/signal-dark.json`
2. Manually select the theme: `Cmd/Ctrl+K Cmd/Ctrl+T` ? "Signal Dark"
3. Ensure no workspace-specific theme overrides exist

### GTK Apps Not Themed (Linux)

1. Ensure you're on Linux (GTK theme is Linux-only)
2. Check that GTK is enabled: `theming.signal.applications.gtk.enable = true`
3. Verify CSS files exist in `~/.config/gtk-3.0/` and `~/.config/gtk-4.0/`
4. Restart the GTK application

## Extending the Theme

### Adding a New Application

1. Create a new module in `modules/shared/theming/applications/`
2. Follow the existing module patterns (see `cursor.nix`, `helix.nix`)
3. Add an enable option to `modules/shared/theming/default.nix`
4. Import the module in the theming default.nix

Example structure:

```nix
# modules/shared/theming/applications/myapp.nix
{ config, lib, pkgs, signalPalette ? null, ... }:
let
  cfg = config.theming.signal;
  theme = signalPalette;
in {
  config = lib.mkIf (cfg.enable && cfg.applications.myapp.enable && theme != null) {
    # Your theme configuration here
  };
}
```

### Modifying Colors

The easiest way to modify colors is to edit `modules/shared/theming/palette.nix`. This file contains all color definitions with both OKLCH and hex values.

## Technical Details

### Color Space: OKLCH

OKLCH is a cylindrical representation of the Oklab color space:

- **L (Lightness)**: 0.0 (black) to 1.0 (white)
- **C (Chroma)**: 0.0 (grayscale) to 0.4+ (highly saturated)
- **H (Hue)**: 0-360 degrees (color wheel position)

### File Structure

```
modules/shared/features/theming/
??? palette.nix           # Color definitions (OKLCH + hex)
??? lib.nix              # Helper functions and semantic mappings
??? helpers.nix          # Theme import helpers
??? validation.nix        # Validation framework (WCAG, APCA)
??? options.nix          # Shared options definitions
??? mode.nix             # Mode resolution system
??? context.nix          # Theme context provider
??? applications/        # Application-specific themes
    ??? editors/         # Editor themes (cursor, helix, zed)
    ??? terminals/       # Terminal themes (ghostty, zellij)
    ??? desktop/         # Desktop themes (gtk, mako, swaync, etc.)
    ??? cli/             # CLI tool themes (bat, fzf, lazygit, yazi)
    ??? registry.nix    # Application registry
    ??? interface.nix    # Standard application interface
??? tests/               # Comprehensive test suite
    ??? palette.nix     # Palette generation tests
    ??? mode.nix        # Mode resolution tests
    ??? semantic.nix    # Semantic mapping tests
    ??? validation.nix  # Validation function tests
    ??? applications.nix # Application integration tests
    ??? options.nix     # Option definition tests
    ??? snapshots.nix   # Snapshot tests

modules/nixos/features/theming/
??? default.nix           # NixOS module with options
??? applications/         # Per-application theme modules
    ??? fuzzel.nix
    ??? ironbar.nix
    ??? mako.nix
    ??? swaync.nix
    ??? swappy.nix

home/common/theming/
??? default.nix           # Home Manager module with options
??? applications/         # Per-application theme modules
    ??? cursor.nix
    ??? helix.nix
    ??? zed.nix
    ??? ghostty.nix
    ??? gtk.nix
    ??? ironbar.nix
    ??? bat.nix
    ??? fzf.nix
    ??? lazygit.nix
    ??? yazi.nix
    ??? zellij.nix
```

### Color Conversion

Colors are pre-calculated and stored as both OKLCH and hex values. The `lib.nix` module provides helper functions for:

- Getting colors by mode (light/dark)
- Semantic color mappings
- Adding alpha transparency
- Formatting colors for different applications

## Contributing

When contributing theme improvements:

1. Maintain perceptual uniformity (same L value = same perceived brightness)
2. Test in both light and dark modes
3. Run validation: Enable `theming.signal.validation.enable = true` to automatically verify WCAG contrast ratios
4. Run test suite: `nix flake check` to ensure all tests pass
5. Test with actual code and UI examples
6. Document any new semantic mappings

## Resources

- [OKLCH Color Space](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl)
- [WCAG Contrast Guidelines](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)
- [APCA (Advanced Perceptual Contrast Algorithm)](https://www.myndex.com/APCA/)
- [Oklab Color Space](https://bottosson.github.io/posts/oklab/)

## Future Enhancements

- [x] Auto mode (system preference detection) - ? Implemented (defaults to dark)
- [ ] Additional application support (Alacritty, Kitty, tmux, etc.)
- [ ] Theme preview tool
- [x] Color accessibility checker - ? Implemented (WCAG & APCA validation)
- [ ] Color temperature adjustment for time of day
- [ ] Custom palette generator from seed colors

## License

Part of the NixOS/nix-darwin configuration repository.
