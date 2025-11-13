# Correct Theming Approaches for Applications

This document shows the **correct way** to theme each application using the Signal theme system, based on how your configuration is structured.

## Table of Contents

1. [swayidle/swaylock](#swayidleswaylock)
2. [mpv](#mpv)
3. [niri](#niri) (pending)

---

## swayidle/swaylock

### Correct Approach

**swayidle** does not have a GUI - it uses **swaylock** for the lock screen. The theming should be done via Home Manager's `programs.swaylock.settings` option.

### Home Manager Format

```nix
{
  programs.swaylock.settings = {
    # Color settings (swaylock accepts hex colors without #)
    color = "808080";  # Default color
    font-size = 24;
    indicator-idle-visible = false;
    indicator-radius = 100;
    line-color = "ffffff";
    show-failed-attempts = true;

    # Ring colors (for the unlock indicator)
    ring-color = colors."accent-focus".hexRaw;  # hexRaw removes # prefix
    key-hl-color = colors."accent-info".hexRaw;

    # Background/inside colors
    inside-color = colors."surface-base".hexRaw;
    line-color = "00000000";  # Transparent
    separator-color = "00000000";  # Transparent

    # Text color
    text-color = colors."text-primary".hexRaw;

    # Effects (swaylock-effects specific)
    screenshots = true;
    clock = true;
    indicator = true;
    indicator-thickness = 7;
    effect-blur = "7x5";
    effect-vignette = "0.5:0.5";
    grace = 2;
    fade-in = 0.2;
  };
}
```

### Signal Theme Integration

```nix
{
  config,
  lib,
  themeContext ? null,
  ...
}:
let
  themeHelpers = import ../../../modules/shared/features/theming/helpers.nix { inherit lib; };
  themeImport = themeHelpers.importTheme {
    repoRootPath = ../../..;
  };
  fallbackTheme = themeImport.generateTheme "dark";
  theme = (themeContext.theme or fallbackTheme);
  colors = theme.colors;
in
{
  services.swayidle = {
    enable = true;
    package = pkgs.swayidle;
    timeouts = [
      {
        timeout = 300;
        # Use swaylock without color args - colors come from programs.swaylock.settings
        command = "${pkgs.swaylock-effects}/bin/swaylock --screenshots --clock --indicator --indicator-radius 100 --indicator-thickness 7 --effect-blur 7x5 --effect-vignette 0.5:0.5 --grace 2 --fade-in 0.2";
      }
      {
        timeout = 600;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors";
      }
    ];
    events = [
      {
        event = "before-sleep";
        command = "${pkgs.swaylock-effects}/bin/swaylock";
      }
    ];
  };

  programs.swaylock.settings = {
    # Signal theme colors
    ring-color = colors."accent-focus".hexRaw;
    key-hl-color = colors."accent-info".hexRaw;
    line-color = "00000000";  # Transparent
    inside-color = "${colors."surface-base".hexRaw}88";  # With alpha
    separator-color = "00000000";  # Transparent
    text-color = colors."text-primary".hexRaw;

    # Visual settings
    font-size = 24;
    indicator-idle-visible = false;
    indicator-radius = 100;
    indicator-thickness = 7;
    show-failed-attempts = true;
  };
}
```

### Key Points

- **swayidle** commands should NOT include color arguments
- Colors are configured via `programs.swaylock.settings` in Home Manager
- Use `hexRaw` (without #) for swaylock color values
- Alpha transparency can be added as hex suffix (e.g., `"88"` for ~50% opacity)

---

## mpv

### Correct Approach

**mpv** uses a config file format with:

- Main options: Standard hex colors (#RRGGBB format)
- Script-opts: BGR format (#BBGGRR) for stats and UOSC scripts
- UOSC options: Comma-separated key=value pairs

### Native Config File Format

```ini
# Main mpv options (RGB hex format)
background-color='#1e1e2e'
osd-back-color='#11111b'
osd-border-color='#11111b'
osd-color='#cdd6f4'
osd-shadow-color='#1e1e2e'

# Stats script options (BGR format: #BBGGRR)
# Colors are in #BBGGRR format (Blue-Green-Red, not RGB)
script-opts-append=stats-border_color=f4d6cd
script-opts-append=stats-font_color=cdd6f4
script-opts-append=stats-plot_bg_border_color=89b4fa
script-opts-append=stats-plot_bg_color=cdd6f4
script-opts-append=stats-plot_color=89b4fa

# UOSC options (comma-separated key=value pairs)
script-opts-append=uosc-color=foreground=89b4fa,foreground_text=313244,background=1e1e2e,background_text=cdd6f4,curtain=181825,success=a6e3a1,error=f38ba8
```

### Signal Theme Integration

```nix
{
  config,
  lib,
  themeContext ? null,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  theme = themeContext.theme;
  colors = theme.colors;

  # Access theme format conversion utilities
  themeLib = theme._internal.themeLib;
in
{
  config = mkIf (cfg.enable && cfg.applications.mpv.enable && theme != null) {
    xdg.configFile."mpv/config".text = ''
      # Video output
      vo=wayland
      gpu-context=wayland
      hwdec=auto-safe

      # Main OSD colors (RGB hex format)
      osd-color=${colors."text-primary".hex}
      osd-border-color=${colors."surface-base".hex}
      osd-shadow-color=${colors."surface-emphasis".hex}
      osd-back-color=${colors."surface-base".hex}cc

      # Subtitle colors (RGB hex format)
      sub-color=${colors."text-primary".hex}
      sub-border-color=${colors."surface-base".hex}
      sub-shadow-color=${colors."surface-emphasis".hex}
      sub-back-color=${colors."surface-base".hex}cc

      # OSD bar settings
      osd-bar-align-y=0.9
      osd-bar-w=100
      osd-bar-h=2
      osd-bar-border-size=1
      osd-bar-pos-y=0.9
      osd-bar-color=${colors."accent-focus".hex}
      osd-bar-border-color=${colors."accent-info".hex}

      # OSD font settings
      osd-font-size=24
      osd-duration=2000
      osd-margin-x=40
      osd-margin-y=40

      # Cache settings
      cache=yes
      cache-secs=60
      demuxer-max-bytes=500M
      demuxer-max-back-bytes=500M

      # Stats script options (BGR format: #BBGGRR)
      script-opts-append=stats-border_color=${theme.formats.bgrHexRaw colors."divider-primary"}
      script-opts-append=stats-font_color=${theme.formats.bgrHexRaw colors."text-primary"}
      script-opts-append=stats-plot_bg_border_color=${theme.formats.bgrHexRaw colors."accent-info"}
      script-opts-append=stats-plot_bg_color=${theme.formats.bgrHexRaw colors."surface-base"}
      script-opts-append=stats-plot_color=${theme.formats.bgrHexRaw colors."accent-focus"}

      # UOSC options (comma-separated, RGB hex without #)
      script-opts-append=uosc-color=foreground=${colors."accent-focus".hexRaw},foreground_text=${colors."surface-base".hexRaw},background=${colors."surface-base".hexRaw},background_text=${colors."text-primary".hexRaw},curtain=${colors."surface-emphasis".hexRaw},success=${colors."accent-primary".hexRaw},error=${colors."accent-danger".hexRaw}
    '';
  };
}
```

### Semantic Color Mappings for mpv

Based on Signal theme semantics:

| mpv Option | Signal Theme Color | Purpose |
|------------|-------------------|---------|
| `background-color` | `surface-base` | Main background |
| `osd-back-color` | `surface-base` | OSD background |
| `osd-border-color` | `surface-base` | OSD border |
| `osd-color` | `text-primary` | OSD text |
| `osd-shadow-color` | `surface-emphasis` | OSD shadow |
| `osd-bar-color` | `accent-focus` | Progress bar |
| `osd-bar-border-color` | `accent-info` | Progress bar border |
| `stats-border_color` (BGR) | `divider-primary` | Stats border |
| `stats-font_color` (BGR) | `text-primary` | Stats text |
| `stats-plot_color` (BGR) | `accent-focus` | Stats plot |
| `uosc foreground` | `accent-focus` | UOSC foreground |
| `uosc background` | `surface-base` | UOSC background |
| `uosc success` | `accent-primary` | UOSC success state |
| `uosc error` | `accent-danger` | UOSC error state |

### Key Points

- **Main mpv options**: Use RGB hex format (`colors."name".hex`)
- **Script-opts (stats)**: Use BGR format (`theme.formats.bgrHexRaw colors."name"`)
- **UOSC options**: Use RGB hex without # (`colors."name".hexRaw`)
- BGR conversion: `#RRGGBB` ? `#BBGGRR` (e.g., `#cdd6f4` ? `#f4d6cd`)
- Use semantic color names from `theme.colors` for consistency

---

## niri

### Correct Approach

**niri** window manager uses Home Manager's `programs.niri.settings` with color options that accept either solid colors or gradients.

### Home Manager Format

```nix
{
  programs.niri.settings = {
    # Background colors
    layout.background-color = "#1e1e2e";
    outputs."DP-1".backdrop-color = "#1e1e2e";
    outputs."DP-1".background-color = "#1e1e2e";
    overview.backdrop-color = "#1e1e2e";

    # Borders (can be color or gradient)
    layout.border = {
      enable = true;
      width = 2;
      active = "#89b4fa";  # Solid color
      inactive = "#45475a";  # Solid color
      urgent = "#f38ba8";  # Solid color
    };

    # Focus ring (can be color or gradient)
    layout.focus-ring = {
      enable = true;
      width = 2;
      active = "#89b4fa";
      inactive = "#45475a";
    };

    # Shadows
    layout.shadow = {
      enable = true;
      color = "#000000aa";
      inactive-color = "#00000055";
      offset = { x = 0; y = 4; };
      softness = 8;
      spread = 2;
    };

    # Tab indicator (can be color or gradient)
    layout.tab-indicator = {
      enable = true;
      width = 2;
      active = "#89b4fa";
      inactive = "#45475a";
    };

    # Cursor
    cursor = {
      size = 24;
      theme = "Adwaita";
    };
  };
}
```

### Signal Theme Integration

```nix
{
  config,
  lib,
  themeContext ? null,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  theme = themeContext.theme;
  colors = theme.colors;
in
{
  config = mkIf (cfg.enable && cfg.applications.niri.enable && theme != null) {
    programs.niri.settings = {
      # Background colors
      layout.background-color = colors."surface-base".hex;
      overview.backdrop-color = colors."surface-base".hex;

      # Output-specific backgrounds (if needed)
      outputs = lib.mapAttrs (_name: output: output // {
        backdrop-color = colors."surface-base".hex;
        background-color = colors."surface-base".hex;
      }) config.programs.niri.settings.outputs or { };

      # Borders
      layout.border = {
        enable = true;
        width = 2;
        active = colors."accent-special".hex;
        inactive = colors."divider-secondary".hex;
        urgent = colors."accent-danger".hex;
      };

      # Focus ring
      layout.focus-ring = {
        enable = true;
        width = 2;
        active = colors."accent-focus".hex;
        inactive = colors."text-tertiary".hex;
      };

      # Shadows
      layout.shadow = {
        enable = true;
        color = "${colors."surface-base".hex}aa";  # With alpha
        inactive-color = "${colors."surface-base".hex}55";  # Lighter alpha
        offset = { x = 0; y = 4; };
        softness = 8;
        spread = 2;
      };

      # Tab indicator
      layout.tab-indicator = {
        enable = true;
        width = 2;
        active = colors."accent-special".hex;
        inactive = colors."text-tertiary".hex;
      };

      # Insert hint (when moving windows)
      layout.insert-hint = {
        enable = true;
        display = colors."accent-focus".hex;
      };

      # Overview workspace shadow
      overview.workspace-shadow = {
        enable = true;
        color = "${colors."surface-base".hex}80";
        offset = { x = 0; y = 4; };
        softness = 8;
        spread = 2;
      };
    };
  };
}
```

### Semantic Color Mappings for niri

Based on Signal theme semantics:

| niri Option | Signal Theme Color | Purpose |
|-------------|-------------------|---------|
| `layout.background-color` | `surface-base` | Default workspace background |
| `outputs.*.backdrop-color` | `surface-base` | Output backdrop |
| `outputs.*.background-color` | `surface-base` | Output solid background |
| `overview.backdrop-color` | `surface-base` | Overview backdrop |
| `layout.border.active` | `accent-special` | Active window border |
| `layout.border.inactive` | `divider-secondary` | Inactive window border |
| `layout.border.urgent` | `accent-danger` | Urgent window border |
| `layout.focus-ring.active` | `accent-focus` | Active focus ring |
| `layout.focus-ring.inactive` | `text-tertiary` | Inactive focus ring |
| `layout.shadow.color` | `surface-base` (with alpha) | Window shadow |
| `layout.shadow.inactive-color` | `surface-base` (lighter alpha) | Inactive window shadow |
| `layout.tab-indicator.active` | `accent-special` | Active tab indicator |
| `layout.tab-indicator.inactive` | `text-tertiary` | Inactive tab indicator |
| `layout.insert-hint.display` | `accent-focus` | Window move hint |
| `overview.workspace-shadow.color` | `surface-base` (with alpha) | Workspace shadow in overview |

### Gradient Support

niri also supports gradients. If you want to use gradients instead of solid colors:

```nix
layout.border.active = {
  gradient = {
    angle = 45;  # Degrees
    from = colors."accent-focus".hex;
    to = colors."accent-special".hex;
    in' = "srgb";  # Colorspace: "srgb" or "oklch"
    relative-to = "window";  # "window" or "output"
  };
};
```

### Key Points

- **Colors**: Use `colors."name".hex` for solid colors
- **Alpha transparency**: Append hex alpha suffix (e.g., `"aa"` for ~67%, `"55"` for ~33%)
- **Gradients**: Use the `gradient` attribute set instead of a color string
- **Per-output overrides**: Can override global settings per output
- **Window/layer rules**: Can override per-window or per-layer via `window-rules` and `layer-rules`

---

## Summary

### Format Reference

| Application | Format | Example |
|-------------|--------|---------|
| swaylock | Hex without # | `colors."accent-focus".hexRaw` |
| mpv (main) | RGB hex with # | `colors."text-primary".hex` |
| mpv (stats) | BGR hex without # | `theme.formats.bgrHexRaw colors."text-primary"` |
| mpv (UOSC) | RGB hex without # | `colors."accent-focus".hexRaw` |
| niri | RGB hex with # | `colors."surface-base".hex` |
| niri (with alpha) | RGB hex with # + alpha | `"${colors."surface-base".hex}aa"` |

### Available Format Functions

From `theme.formats` (on the theme object):

- `hex` - RGB hex with # (e.g., `#cdd6f4`)
- `hexRaw` - RGB hex without # (e.g., `cdd6f4`)
- `bgrHex` - BGR hex with # (e.g., `#f4d6cd`)
- `bgrHexRaw` - BGR hex without # (e.g., `f4d6cd`)
- `rgb` - RGB tuple `{ r, g, b }`
- `rgbString` - RGB string `"r,g,b"`

### Semantic Color Names

Use these semantic names from `theme.colors`:

- `surface-base`, `surface-subtle`, `surface-emphasis`
- `text-primary`, `text-secondary`, `text-tertiary`
- `accent-primary`, `accent-danger`, `accent-warning`, `accent-info`, `accent-focus`, `accent-special`
- `divider-primary`, `divider-secondary`

See `docs/SIGNAL_THEME.md` for the complete list of semantic colors.
