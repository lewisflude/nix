# Scientific Color Theme

A scientifically-designed color theming system based on the OKLCH color space, providing perceptually uniform colors with excellent accessibility and visual consistency.

## Overview

The Scientific Theme system uses the OKLCH (Oklab Lightness Chroma Hue) color space, which provides:

- **Perceptual Uniformity**: Colors with the same lightness value appear equally bright
- **Predictable Behavior**: Adjusting hue maintains consistent lightness and saturation
- **Accessibility**: Built-in contrast ratios meet WCAG guidelines
- **Color Harmony**: Mathematical relationships between hues create natural color schemes

## Features

- ? Dual-mode support (light and dark themes)
- ? Semantic color mapping for UI elements
- ? Syntax highlighting optimized for code readability
- ? Terminal ANSI color support
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
    scientificTheme = {
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

**Location:** `~/.config/Cursor/User/themes/scientific-dark.json`

**Theme Name:** "Scientific Dark" (or "Scientific Light")

### Helix Editor

Integrated with Helix's native theme system.

**Theme Name:** `scientific-dark` (or `scientific-light`)

**Activation:** Automatic via `programs.helix.settings.theme`

### Zed Editor

Theme file generated for Zed editor.

**Location:** `~/.config/zed/themes/scientific.json`

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
host.features.desktop.scientificTheme = {
  enable = true;
  mode = "dark"; # "light", "dark", or "auto"
};
```

### Advanced Configuration

For fine-grained control, you can configure individual applications:

```nix
theming.scientific = {
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
theming.scientific = {
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

## Switching Between Light and Dark Mode

### System-wide Switch

Update your host configuration:

```nix
host.features.desktop.scientificTheme.mode = "light";
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

1. Check that the theme file exists: `~/.config/Cursor/User/themes/scientific-dark.json`
2. Manually select the theme: `Cmd/Ctrl+K Cmd/Ctrl+T` ? "Scientific Dark"
3. Ensure no workspace-specific theme overrides exist

### GTK Apps Not Themed (Linux)

1. Ensure you're on Linux (GTK theme is Linux-only)
2. Check that GTK is enabled: `theming.scientific.applications.gtk.enable = true`
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
{ config, lib, pkgs, scientificPalette ? null, ... }:
let
  cfg = config.theming.scientific;
  theme = scientificPalette;
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
modules/shared/theming/
??? default.nix           # Main module with options
??? palette.nix           # Color definitions (OKLCH + hex)
??? lib.nix              # Helper functions and semantic mappings
??? applications/        # Per-application theme modules
    ??? cursor.nix
    ??? helix.nix
    ??? zed.nix
    ??? ghostty.nix
    ??? gtk.nix
    ??? niri.nix
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
3. Verify WCAG contrast ratios
4. Test with actual code and UI examples
5. Document any new semantic mappings

## Resources

- [OKLCH Color Space](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl)
- [WCAG Contrast Guidelines](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)
- [Oklab Color Space](https://bottosson.github.io/posts/oklab/)

## Future Enhancements

- [ ] Auto mode (system preference detection)
- [ ] Additional application support (Alacritty, Kitty, tmux, etc.)
- [ ] Theme preview tool
- [ ] Color accessibility checker
- [ ] Color temperature adjustment for time of day
- [ ] Custom palette generator from seed colors

## License

Part of the NixOS/nix-darwin configuration repository.
