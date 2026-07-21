# Signal Palette Integration

## Source of Truth

**signal-nix does NOT define colors.** All color values are imported from the [`signal-palette`](https://github.com/lewisflude/signal-palette) repository, which serves as the single source of truth for the Signal color system.

## Architecture

```
┌─────────────────────────────────────────────┐
│        signal-palette (SOURCE)              │
│  ┌────────────────────────────────────┐    │
│  │   palette.json                     │    │  ← Color values
│  │   (OKLCH, APCA, sRGB)             │    │
│  └────────────────────────────────────┘    │
│  ┌────────────────────────────────────┐    │
│  │   semantic-bridge.json             │    │  ← UI mappings
│  │   (background → surface.base)      │    │
│  └────────────────────────────────────┘    │
│           │                                 │
│           │ generates                       │
│           ▼                                 │
│  ┌────────────────────────────────────┐    │
│  │   exports/palette.nix              │    │  ← Nix format
│  │   exports/semantic-bridge.nix      │    │
│  └────────────────────────────────────┘    │
└──────────────────┬──────────────────────────┘
                   │
                   │ imported by
                   ▼
┌─────────────────────────────────────────────┐
│        signal-nix (IMPLEMENTATION)          │
│  ┌────────────────────────────────────┐    │
│  │   modules/terminals/               │    │  ← Use bridge
│  │   modules/editors/                 │    │  ← Use bridge
│  │   modules/cli/                     │    │  ← Use bridge
│  │   pkgs/gtk-theme/                  │    │  ← Use bridge
│  └────────────────────────────────────┘    │
└─────────────────────────────────────────────┘
```

## Why This Separation?

1. **Single Source of Truth** - Colors are defined once, used everywhere
2. **Platform Independence** - signal-palette can export to any format (CSS, JSON, YAML, Nix)
3. **Scientific Integrity** - Color specifications remain unchanged across implementations
4. **Versioning** - Palette updates are independent of implementation updates
5. **Reusability** - Other projects can consume signal-palette without Nix

## Using Signal Colors in Modules

### ✅ RECOMMENDED: Use Semantic Bridge (Current Best Practice)

**All signal-nix modules now use the semantic bridge exclusively.** This provides a stable, semantic API for accessing colors.

```nix
{ config, lib, signalLib, semantic, ... }:

let
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;  # "light" or "dark"

  # Define colors using semantic categories
  colors = {
    background = semantic.core "background" themeMode;
    foreground = semantic.core "foreground" themeMode;
    cursor = semantic.core "cursor" themeMode;
  };

  # ANSI colors for terminals
  ansiColors = {
    red = semantic.terminal "ansi-red" themeMode;
    green = semantic.terminal "ansi-green" themeMode;
    blue = semantic.terminal "ansi-blue" themeMode;
  };
in {
  programs.alacritty.settings.colors = {
    primary = {
      background = colors.background.hex;  # Access hex value
      foreground = colors.foreground.hex;
    };
    normal = {
      red = ansiColors.red.hex;
      green = ansiColors.green.hex;
      blue = ansiColors.blue.hex;
    };
  };
}
```

**Why use the semantic bridge?**
- ✅ Stable API - palette structure changes don't break modules
- ✅ Consistent naming - same semantic names across all applications
- ✅ Readable code - `semantic.core "background"` vs `palette.tonal.dark."surface-base"`
- ✅ Validated references - helpful errors if you use a wrong name
- ✅ Type safety - returns full color object with `.hex`, `.rgb`, `.l`, `.c`, `.h` properties

### ⚠️ DEPRECATED: Direct Palette Access

Direct palette access is no longer recommended. Use the semantic bridge instead:

```nix
# ⚠️ OLD PATTERN (Deprecated)
{ config, lib, signalLib, ... }:

let
  signalColors = signalLib.getColors mode;
in {
  programs.alacritty.colors = {
    primary = {
      background = signalColors.tonal."surface-base".hex;
      foreground = signalColors.tonal."text-primary".hex;
    };
  };
}
```

### ❌ FORBIDDEN: Hardcoded colors

```nix
# NEVER DO THIS
programs.alacritty.colors = {
  primary = {
    background = "#1a1b1e";  # ❌ Hardcoded
    foreground = "#cbd2d9";  # ❌ Hardcoded
  };
};
```

**Hardcoded colors are automatically detected by CI and will fail the build.**

### ❌ FORBIDDEN: Redeclared colors

```nix
# NEVER DO THIS
let
  myColors = {
    background = "oklch(0.15 0.01 240)";  # ❌ Redeclared
  };
in
# ...
```

## Semantic Bridge API Reference

The semantic bridge is the recommended way to access colors in signal-nix. It provides 10 semantic categories with consistent naming across all applications.

### Module Setup

Modules automatically receive `semantic` and `signalLib` as arguments:

```nix
{ config, lib, signalLib, semantic, ... }:

let
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;  # "light" or "dark"
in {
  # Use semantic categories...
}
```

### Basic Usage

The semantic bridge provides category-specific functions:

```nix
# Pattern: semantic.<category> "<name>" <mode>

# Core UI colors
bg = semantic.core "background" themeMode;
fg = semantic.core "foreground" themeMode;

# Terminal ANSI colors
red = semantic.terminal "ansi-red" themeMode;

# Status indicators
error = semantic.status "error" themeMode;

# Syntax highlighting
keyword = semantic.syntax "keyword" themeMode;
```

### Color Object Structure

Each semantic reference returns a full color object:

```nix
color = semantic.core "background" "dark";
# Returns: {
#   hex = "#1a1b1e";           # Hex string with #
#   hexRaw = "1a1b1e";         # Hex without #
#   rgb = "26, 27, 30";        # RGB comma-separated
#   l = 0.15;                  # Lightness (0-1)
#   c = 0.01;                  # Chroma (0-0.4)
#   h = 240;                   # Hue (0-360)
#   description = "...";       # Human description
# }

# Access individual fields
programs.app.colors.bg = color.hex;           # "#1a1b1e"
programs.app.colors.bg_rgb = color.rgb;       # "26, 27, 30"
```

### Available Semantic Categories

#### 1. Core - Fundamental UI elements

```nix
semantic.core "background" mode      # Main background
semantic.core "foreground" mode      # Main text color
semantic.core "cursor" mode          # Cursor/caret
semantic.core "selection-bg" mode    # Selected text background
semantic.core "selection-fg" mode    # Selected text foreground
semantic.core "focus" mode           # Focus indicator
```

#### 2. UI - Panels, borders, hover states

```nix
semantic.ui "panel-background" mode
semantic.ui "panel-border" mode
semantic.ui "element-hover" mode
semantic.ui "element-active" mode
semantic.ui "element-selected" mode
semantic.ui "element-disabled" mode
semantic.ui "status-bar-background" mode
semantic.ui "tab-active-background" mode
semantic.ui "tab-inactive-background" mode
semantic.ui "tab-border" mode
semantic.ui "title-bar-active" mode
semantic.ui "title-bar-inactive" mode
```

#### 3. Text - Text hierarchy

```nix
semantic.text "primary" mode         # Primary text
semantic.text "secondary" mode       # Secondary/dimmed text
semantic.text "tertiary" mode        # Even more dimmed
semantic.text "disabled" mode        # Disabled state text
semantic.text "placeholder" mode     # Input placeholder text
semantic.text "link" mode            # Hyperlink text
semantic.text "link-hover" mode      # Hyperlink on hover
```

#### 4. Terminal - ANSI colors

```nix
# Normal colors (0-7)
semantic.terminal "ansi-black" mode
semantic.terminal "ansi-red" mode
semantic.terminal "ansi-green" mode
semantic.terminal "ansi-yellow" mode
semantic.terminal "ansi-blue" mode
semantic.terminal "ansi-magenta" mode
semantic.terminal "ansi-cyan" mode
semantic.terminal "ansi-white" mode

# Bright colors (8-15)
semantic.terminal "ansi-bright-black" mode
semantic.terminal "ansi-bright-red" mode
semantic.terminal "ansi-bright-green" mode
semantic.terminal "ansi-bright-yellow" mode
semantic.terminal "ansi-bright-blue" mode
semantic.terminal "ansi-bright-magenta" mode
semantic.terminal "ansi-bright-cyan" mode
semantic.terminal "ansi-bright-white" mode
```

#### 5. Editor - Editor-specific UI

```nix
semantic.editor "background" mode
semantic.editor "foreground" mode
semantic.editor "gutter-background" mode
semantic.editor "active-line-background" mode
semantic.editor "line-number" mode
semantic.editor "active-line-number" mode
semantic.editor "indent-guide" mode
semantic.editor "indent-guide-active" mode
semantic.editor "invisible" mode
semantic.editor "bracket-match-background" mode
semantic.editor "find-match-background" mode
semantic.editor "find-match-foreground" mode
semantic.editor "scrollbar-thumb" mode
semantic.editor "scrollbar-track" mode
```

#### 6. Syntax - Code highlighting

```nix
semantic.syntax "keyword" mode       # if, for, return
semantic.syntax "function" mode      # Function names
semantic.syntax "string" mode        # String literals
semantic.syntax "number" mode        # Numeric literals
semantic.syntax "comment" mode       # Comments
semantic.syntax "type" mode          # Type names
semantic.syntax "variable" mode      # Variables
semantic.syntax "constant" mode      # Constants
semantic.syntax "operator" mode      # +, -, *, /
semantic.syntax "tag" mode           # HTML/XML tags
semantic.syntax "attribute" mode     # HTML attributes
semantic.syntax "preprocessing" mode # Preprocessor directives
semantic.syntax "punctuation" mode   # Brackets, semicolons
semantic.syntax "escape" mode        # Escape sequences
```

#### 7. Markup - Markdown/documentation

```nix
semantic.markup "heading" mode
semantic.markup "bold" mode
semantic.markup "italic" mode
semantic.markup "link" mode
semantic.markup "link-url" mode
semantic.markup "code" mode
semantic.markup "code-block" mode
semantic.markup "quote" mode
semantic.markup "list-marker" mode
```

#### 8. VCS - Version control status

```nix
semantic.vcs "added" mode            # New files/lines
semantic.vcs "modified" mode         # Changed files/lines
semantic.vcs "deleted" mode          # Deleted files/lines
semantic.vcs "renamed" mode          # Renamed files
semantic.vcs "conflict" mode         # Merge conflicts
semantic.vcs "ignored" mode          # Ignored files
```

#### 9. Status - Indicators and states

```nix
semantic.status "error" mode         # Errors
semantic.status "warning" mode       # Warnings
semantic.status "success" mode       # Success states
semantic.status "info" mode          # Information
semantic.status "hint" mode          # Subtle hints
```

#### 10. Multiplayer - Collaboration colors

```nix
semantic.multiplayer "player-1" mode
semantic.multiplayer "player-2" mode
semantic.multiplayer "player-3" mode
semantic.multiplayer "player-4" mode
semantic.multiplayer "player-5" mode
semantic.multiplayer "player-6" mode
semantic.multiplayer "player-7" mode
semantic.multiplayer "player-8" mode
```

### Advanced Usage

#### Bulk Operations

Get all colors for a category at once:

```nix
# Get all core colors for dark mode
allCoreColors = semantic.getAllColors "core" "dark";
# Returns: { background = {...}; foreground = {...}; ... }

bg = allCoreColors.background.hex;
fg = allCoreColors.foreground.hex;
```

#### Validation Helpers

Query available names for documentation/validation:

```nix
# Get all category names
categories = semantic.getAvailableCategories;
# Returns: ["core" "ui" "text" "terminal" "editor" ...]

# Get all names within a category
coreNames = semantic.getAvailableNames "core";
# Returns: ["background" "foreground" "cursor" ...]
```

#### Error Handling

The semantic bridge provides helpful errors:

```nix
# Typo in category
color = semantic.cor "background" mode;
# Error: Semantic reference not found: cor.background
#
# Available categories: core, ui, text, terminal, editor, syntax, markup, vcs, status, multiplayer
#
# See docs/semantic-bridge-guide.md for all available semantic references.

# Typo in name
color = semantic.core "backgorund" mode;
# Error: Semantic reference not found: core.backgorund
#
# Available categories: core, ui, text, terminal, editor, syntax, markup, vcs, status, multiplayer
#
# Available names in 'core': background, foreground, cursor, selection-bg, selection-fg, focus
#
# See docs/semantic-bridge-guide.md for all available semantic references.
```

### Integration Points

#### 1. Flake Input

Signal-nix automatically imports signal-palette:

```nix
# flake.nix (already configured)
{
  inputs = {
    signal-palette.url = "github:lewisflude/signal-palette";
    # ...
  };
}
```

#### 2. Module Arguments

All modules receive `semantic` and `signalLib` automatically:

```nix
# modules/yourapp/default.nix
{ config, lib, signalLib, semantic, ... }:

let
  cfg = config.theming.signal;
  mode = signalLib.resolveThemeMode cfg.mode;
in {
  # Use semantic bridge...
}
```

No imports or setup needed - it just works!

### Complete Working Example

Here's a complete terminal module using the semantic bridge:

```nix
{ config, lib, signalLib, semantic, ... }:

let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Core colors
  colors = {
    background = semantic.core "background" themeMode;
    foreground = semantic.core "foreground" themeMode;
    cursor = semantic.core "cursor" themeMode;
    selection-bg = semantic.core "selection-bg" themeMode;
  };

  # ANSI colors
  ansi = {
    black = semantic.terminal "ansi-black" themeMode;
    red = semantic.terminal "ansi-red" themeMode;
    green = semantic.terminal "ansi-green" themeMode;
    yellow = semantic.terminal "ansi-yellow" themeMode;
    blue = semantic.terminal "ansi-blue" themeMode;
    magenta = semantic.terminal "ansi-magenta" themeMode;
    cyan = semantic.terminal "ansi-cyan" themeMode;
    white = semantic.terminal "ansi-white" themeMode;
  };

  # Status colors
  status = {
    error = semantic.status "error" themeMode;
    warning = semantic.status "warning" themeMode;
  };

  # Check if app should be themed
  shouldTheme = signalLib.shouldThemeApp "myterminal" [
    "terminals"
    "myterminal"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.myterminal = {
      colors = {
        # Primary colors
        background = colors.background.hex;
        foreground = colors.foreground.hex;
        cursor = colors.cursor.hex;

        # Selection
        selection_background = colors.selection-bg.hex;

        # Normal ANSI
        black = ansi.black.hex;
        red = ansi.red.hex;
        green = ansi.green.hex;
        yellow = ansi.yellow.hex;
        blue = ansi.blue.hex;
        magenta = ansi.magenta.hex;
        cyan = ansi.cyan.hex;
        white = ansi.white.hex;
      };
    };
  };
}
```

## Color Update Workflow

When signal-palette releases a new version:

1. **Update flake input:**
   ```bash
   nix flake lock --update-input signal-palette
   ```

2. **Rebuild configurations:**
   ```bash
   home-manager switch
   ```

3. **Test all themes:**
   ```bash
   ./run-tests.sh
   ```

4. **Verify validation passes:**
   ```bash
   nix flake check
   ```

No code changes needed in signal-nix—colors update automatically through the semantic bridge!

## Documentation

For complete color documentation, see the signal-palette repository:

- **Technical Specification** - Mathematical constraints and validation rules
- **Color System Reference** - Complete palette with usage guidelines
- **Philosophy** - Design principles and reasoning

## Best Practices

### 1. Always Use Semantic Bridge

```nix
# ✅ DO: Use semantic bridge
bg = semantic.core "background" mode;

# ❌ DON'T: Direct palette access
bg = palette.tonal.dark."surface-base";

# ❌ DON'T: Old getColors pattern
signalColors = signalLib.getColors mode;
bg = signalColors.tonal."surface-base";
```

### 2. Organize Colors by Purpose

```nix
# ✅ DO: Group related colors
colors = {
  background = semantic.core "background" mode;
  foreground = semantic.core "foreground" mode;
};

ansi = {
  red = semantic.terminal "ansi-red" mode;
  green = semantic.terminal "ansi-green" mode;
};

# ❌ DON'T: Flat unorganized list
bg = semantic.core "background" mode;
red = semantic.terminal "ansi-red" mode;
fg = semantic.core "foreground" mode;
green = semantic.terminal "ansi-green" mode;
```

### 3. Use Descriptive Variable Names

```nix
# ✅ DO: Clear semantic names
editorBg = semantic.editor "background" mode;
activeLine = semantic.editor "active-line-background" mode;

# ❌ DON'T: Abbreviated or unclear names
ebg = semantic.editor "background" mode;
al = semantic.editor "active-line-background" mode;
```

### 4. Document Application-Specific Mappings

```nix
# ✅ DO: Comment non-obvious mappings
colors = {
  # Neovim's "NonText" highlight → subtle dividers
  non-text = semantic.ui "panel-border" mode;

  # Neovim's "MatchParen" → find matches
  match-paren = semantic.editor "find-match-background" mode;
};
```

### 5. Extract Theme Mode Once

```nix
# ✅ DO: Resolve once at module top
let
  themeMode = signalLib.resolveThemeMode cfg.mode;
  colors = {
    bg = semantic.core "background" themeMode;
    fg = semantic.core "foreground" themeMode;
  };
in

# ❌ DON'T: Resolve repeatedly
colors = {
  bg = semantic.core "background" (signalLib.resolveThemeMode cfg.mode);
  fg = semantic.core "foreground" (signalLib.resolveThemeMode cfg.mode);
};
```

## Troubleshooting

### "Semantic reference not found" Error

**Error message:**
```
error: Semantic reference not found: core.backgorund

Available categories: core, ui, text, ...
Available names in 'core': background, foreground, ...
```

**Solution:** Check for typos in category or name. See the [Available Semantic Categories](#available-semantic-categories) section above.

### "Tonal color not found" Error

**Error message:**
```
error: Tonal color 'surface-bases' not found for mode 'dark'.
Available tonal colors: surface-base, surface-subtle, ...
```

**Solution:** This error occurs when the semantic bridge references a palette color that doesn't exist. This is a bug - please report it.

### Colors Not Updating After Palette Update

**Issue:** Updated signal-palette but colors haven't changed.

**Solution:**
```bash
# 1. Update flake lock
nix flake lock --update-input signal-palette

# 2. Clear any cached builds
nix-collect-garbage -d

# 3. Rebuild
home-manager switch --flake .
```

### Module Not Receiving `semantic` Argument

**Issue:** `error: attribute 'semantic' missing`

**Solution:** Ensure your module is imported through signal-nix's module system. Check that:
1. Module is listed in `modules/common/default.nix` imports
2. Module signature includes `semantic` in arguments: `{ config, lib, semantic, ... }:`

### Validation Fails with "Hardcoded colors found"

**Issue:** CI fails with hardcoded color detection.

**Solution:**
```bash
# Find hardcoded colors
grep -r "#[0-9a-fA-F]{6}" modules/
grep -r "oklch(" modules/

# Replace with semantic bridge
# Before: background = "#1a1b1e";
# After: background = semantic.core "background" mode;
```

## Contributing

**Do not propose color changes in signal-nix.**

Color specifications must be contributed to [signal-palette](https://github.com/lewisflude/signal-palette) instead, where they can be:
- Validated against mathematical constraints
- Tested across all platforms
- Versioned properly
- Reused by all Signal implementations

### For signal-nix contributions:

**Adding a new application module:**
1. Copy `templates/module-template.nix` as starting point
2. Use semantic bridge exclusively for colors
3. Add to `modules/common/default.nix` imports
4. Test with `nix build .#homeConfigurations.test-user.activationPackage`
5. Ensure `nix flake check` passes (validates no hardcoded colors)

**Improving existing modules:**
- Maintain semantic bridge usage
- Keep color mappings consistent with other modules
- Add comments for non-obvious mappings
- Test both light and dark modes

**Extending semantic bridge:**
If you need a semantic reference that doesn't exist:
1. Add it to `lib/semantic.nix` in the appropriate category
2. Map it to an existing palette color
3. Document the mapping
4. Update `docs/semantic-bridge-guide.md`

## Related Documentation

- [Color System Overview](./color-system-overview.md) - Philosophy and contributing guidelines for signal-nix
- [Theming Reference](./theming-reference.md) - Applying Signal to your setup
- [Testing Guide](./TESTING_GUIDE.md) - Validating theme changes

---

**Remember:** signal-nix is an **implementation**, signal-palette is the **specification**.
