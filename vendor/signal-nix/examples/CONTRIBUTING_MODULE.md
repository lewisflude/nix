# Contributing a New Module to Signal-Nix

This guide walks you through adding a new application module to signal-nix. By the end, you'll have a fully-integrated, tested module that follows all best practices.

## Prerequisites

- Familiarity with Nix and Home Manager
- Your application installed and working
- Basic understanding of your app's configuration format
- 30-60 minutes of time

## Overview

Adding a module involves 5 steps:

1. **Choose a template** - Terminal, editor, or custom
2. **Map colors** - Translate semantic colors to app config
3. **Integrate** - Add to signal-nix module system
4. **Test** - Verify both light and dark modes
5. **Submit** - Create a PR

Let's walk through each step!

---

## Step 1: Choose Your Template

Signal-nix provides templates for common application types:

### Terminal Emulator

Use `templates/terminal-module-template.nix` if your app is:
- A terminal emulator (kitty, wezterm, foot, etc.)
- Needs ANSI colors (16-color palette)
- Has basic UI (background, foreground, cursor, selection)

**Example apps:** alacritty, kitty, wezterm, foot, ghostty

### Code Editor

Use `templates/editor-module-template.nix` if your app is:
- A code editor (neovim, helix, emacs, etc.)
- Needs syntax highlighting colors
- Has editor-specific UI (line numbers, gutter, etc.)

**Example apps:** neovim, helix, vim, emacs, vscode, zed

### Custom Application

For other application types:
- Start with the terminal template (simpler)
- Add categories as needed (ui, status, vcs, etc.)
- See `examples/custom-terminal-example.nix` for guidance

**Example apps:** file managers, system monitors, multiplexers

### Copy the Template

```bash
# For a terminal
cp templates/terminal-module-template.nix modules/terminals/myapp.nix

# For an editor
cp templates/editor-module-template.nix modules/editors/myapp.nix

# For other apps
cp templates/terminal-module-template.nix modules/category/myapp.nix
```

---

## Step 2: Map Colors to Your Application

This is the core work. You need to translate semantic colors to your app's config format.

### 2.1: Find Your App's Color Configuration

Look at your app's documentation or existing config to understand:
- Where colors are configured (config file, settings, etc.)
- What format colors use (hex, rgb, named, etc.)
- What color properties exist (background, foreground, etc.)

**Example: Alacritty**
```yaml
# ~/.config/alacritty/alacritty.yml
colors:
  primary:
    background: '#1a1b1e'
    foreground: '#cbd2d9'
  normal:
    black: '#1a1b1e'
    red: '#ff5252'
    # ...
```

### 2.2: Map Semantic Colors

For each color in your app's config, find the appropriate semantic reference:

| App Color | Semantic Reference |
|-----------|-------------------|
| Background | `semantic.core "background" mode` |
| Foreground/Text | `semantic.core "foreground" mode` |
| Cursor | `semantic.core "cursor" mode` |
| Selection BG | `semantic.core "selection-bg" mode` |
| ANSI Red | `semantic.terminal "ansi-red" mode` |
| ANSI Green | `semantic.terminal "ansi-green" mode` |
| Error Color | `semantic.status "error" mode` |
| Warning Color | `semantic.status "warning" mode` |
| Git Added | `semantic.vcs "added" mode` |
| Comment Color | `semantic.syntax "comment" mode` |
| Keyword Color | `semantic.syntax "keyword" mode` |

See [docs/semantic-bridge-guide.md](../docs/semantic-bridge-guide.md) for all available semantic colors.

### 2.3: Update Your Module

In your copied template, update the color definitions:

```nix
# Define colors using semantic bridge
colors = {
  background = semantic.core "background" themeMode;
  foreground = semantic.core "foreground" themeMode;
  cursor = semantic.core "cursor" themeMode;
  # Add more as needed...
};
```

Then map to your app's config format:

```nix
programs.myapp = {
  settings = {
    colors = {
      # Map semantic colors to app format
      background = colors.background.hex;  # Use .hex for hex strings
      foreground = colors.foreground.hex;
      cursor = colors.cursor.hex;

      # Or use .rgb for RGB format
      # background_rgb = colors.background.rgb;  # "26, 27, 30"
    };
  };
};
```

### 2.4: Handle Different Color Formats

The color object has multiple properties:

```nix
color = semantic.core "background" mode;

color.hex        # "#1a1b1e"       - Hex with #
color.hexRaw     # "1a1b1e"        - Hex without #
color.rgb        # "26, 27, 30"    - RGB comma-separated
color.l          # 0.15            - Lightness (0-1)
color.c          # 0.01            - Chroma (0-0.4)
color.h          # 240             - Hue (0-360)
```

Use the appropriate property for your app's format:

```nix
# Hex format (most common)
background = colors.background.hex;

# RGB format
background_rgb = colors.background.rgb;

# Individual components
background_r = builtins.elemAt (lib.splitString ", " colors.background.rgb) 0;
background_g = builtins.elemAt (lib.splitString ", " colors.background.rgb) 1;
background_b = builtins.elemAt (lib.splitString ", " colors.background.rgb) 2;
```

---

## Step 3: Integrate Into Signal-Nix

### 3.1: Update Module Metadata

At the top of your module file, update the metadata:

```nix
# CONFIGURATION METHOD: structured-colors (Tier 2)
# HOME-MANAGER MODULE: programs.myapp.settings.colors
# UPSTREAM SCHEMA: https://myapp.example.com/docs/config
# SCHEMA VERSION: 1.2.3
# LAST VALIDATED: 2026-01-20
# NOTES: Brief notes about the integration
```

### 3.2: Update App Name

Replace all instances of `myTerminal` or `myEditor` with your app's name:

```nix
# In shouldThemeApp call
shouldTheme = signalLib.shouldThemeApp "myapp" [
  "category"  # terminals, editors, cli, desktop, etc.
  "myapp"
] cfg config;

# In programs configuration
programs.myapp = {
  # ...
};
```

### 3.3: Add to Module Imports

Add your module to `modules/common/default.nix`:

```nix
{
  imports = [
    # ... existing imports ...
    ../../modules/terminals/myapp.nix  # or editors/, cli/, etc.
  ];
}
```

### 3.4: Add Enable Option

Add an enable option to `modules/common/default.nix`:

```nix
options.theming.signal = {
  # ... existing options ...

  # Add in the appropriate section (terminals, editors, etc.)
  myapp = mkEnableOption "Signal theme for MyApp" // {
    default = cfg.autoEnable;
  };
};
```

---

## Step 4: Test Your Module

### 4.1: Build Test Configuration

Create a test configuration:

```nix
# test-config.nix
{ config, pkgs, ... }:

{
  imports = [ ./modules/common/default.nix ];

  theming.signal = {
    enable = true;
    mode = "dark";  # Test dark mode first
    myapp = true;   # Enable your module
  };

  programs.myapp.enable = true;
}
```

Build it:

```bash
nix build .#homeConfigurations.test-user.activationPackage
```

### 4.2: Test Dark Mode

1. Activate the configuration
2. Open your application
3. Verify colors match Signal theme:
   - Background should be dark gray (#1a1b1e)
   - Text should be light gray (#cbd2d9)
   - Colors should match other Signal apps

### 4.3: Test Light Mode

Update test config:

```nix
theming.signal.mode = "light";
```

Rebuild and verify:
- Background should be light gray (#f0f2f5)
- Text should be dark gray (#5a6169)
- Colors should be consistent with light mode

### 4.4: Test Auto Mode

```nix
theming.signal.mode = "auto";
```

Verify it respects system theme preference.

### 4.5: Validate No Hardcoded Colors

Run the validation checks:

```bash
nix flake check
```

This will fail if you have any hardcoded colors. The error will show which file and what color was found.

### 4.6: Visual Comparison

Compare your app side-by-side with another Signal-themed app:
- Do backgrounds match?
- Do ANSI colors match (for terminals)?
- Do syntax colors match (for editors)?
- Does it feel cohesive?

---

## Step 5: Submit Your Contribution

### 5.1: Create a Branch

```bash
git checkout -b feat/add-myapp-module
```

### 5.2: Commit Your Changes

```bash
git add modules/category/myapp.nix
git add modules/common/default.nix
git commit -m "feat(modules): add MyApp theme support

- Add MyApp module with semantic bridge integration
- Support both light and dark modes
- Includes ANSI colors and UI theming
- Validated with nix flake check"
```

### 5.3: Write a Good PR Description

Include:
- What application you're adding
- What features are themed (colors, UI, etc.)
- Screenshots of light and dark modes
- Confirmation that `nix flake check` passes
- Any special considerations or limitations

**Example:**
```markdown
## Add MyApp Theme Support

This PR adds Signal theme support for MyApp, a terminal emulator.

### Features
- ✅ Full ANSI color support (16 colors)
- ✅ UI theming (tabs, statusbar)
- ✅ Light and dark modes
- ✅ Semantic bridge integration
- ✅ No hardcoded colors

### Testing
- Tested on NixOS 24.05
- Verified with `nix flake check`
- Screenshots attached

### Screenshots
[Attach screenshots of light and dark modes]

### Notes
MyApp requires version 2.0+ for structured color configuration.
```

### 5.4: Submit PR

Push your branch and create a PR on GitHub:

```bash
git push origin feat/add-myapp-module
```

Then open a PR at: https://github.com/lewisflude/signal-nix/pulls

---

## Troubleshooting

### "Semantic reference not found"

**Error:**
```
error: Semantic reference not found: core.backgorund
```

**Solution:** Check spelling of category and name. See [docs/semantic-bridge-guide.md](../docs/semantic-bridge-guide.md).

### Colors Don't Match Other Apps

**Issue:** Your app's colors look different from other Signal apps.

**Solution:**
- Verify you're using the correct semantic categories
- Use `semantic.core "background"` for main background, not `semantic.editor "background"`
- Compare hex values with another Signal app

### Module Not Being Applied

**Issue:** Configuration builds but app isn't themed.

**Solution:**
1. Check `shouldTheme` is true
2. Verify app name matches in `shouldThemeApp` call
3. Ensure `cfg.enable` is true
4. Check that your app's enable option is set

### Hardcoded Color Detection Fails

**Issue:** `nix flake check` fails with "Hardcoded colors found"

**Solution:**
```bash
# Find the hardcoded color
grep -n "#[0-9a-fA-F]\{6\}" modules/category/myapp.nix

# Replace with semantic reference
# Before: background = "#1a1b1e";
# After:  background = semantic.core "background" mode;
```

### Need a Color Not in Semantic Bridge

**Issue:** Your app needs a color that doesn't exist in semantic categories.

**Solution:**
1. Check if an existing category fits (e.g., use `semantic.ui "panel-border"` for dividers)
2. If truly unique, add to `lib/semantic.nix`:
   ```nix
   myCategory = {
     myColor = {
       type = "tonal";
       path = "divider-primary";
     };
   };
   ```
3. Document in [docs/semantic-bridge-guide.md](../docs/semantic-bridge-guide.md)
4. Mention in PR description

---

## Best Practices Checklist

Before submitting, verify:

- [ ] Uses semantic bridge exclusively (no hardcoded colors)
- [ ] Organized color definitions (grouped by purpose)
- [ ] Descriptive variable names
- [ ] Comments for non-obvious mappings
- [ ] Tested in both light and dark modes
- [ ] `nix flake check` passes
- [ ] Added to `modules/common/default.nix` imports
- [ ] Enable option added to `modules/common/default.nix`
- [ ] Module metadata updated (config method, schema, etc.)
- [ ] Follows existing module patterns
- [ ] No linter errors

---

## Examples to Learn From

### Simple Terminal
- **File:** `modules/terminals/foot.nix`
- **Good for:** Basic terminal integration
- **Complexity:** Low

### Complex Terminal
- **File:** `modules/terminals/alacritty.nix`
- **Good for:** Advanced terminal features
- **Complexity:** Medium

### Simple Editor
- **File:** `modules/editors/helix.nix`
- **Good for:** Straightforward editor theming
- **Complexity:** Medium

### Complex Editor
- **File:** `modules/editors/neovim.nix`
- **Good for:** Full-featured editor with extensive syntax highlighting
- **Complexity:** High

### CLI Tool
- **File:** `modules/cli/bat.nix`
- **Good for:** Command-line tools with syntax highlighting
- **Complexity:** Low

---

## Getting Help

- **Documentation:** [docs/signal-palette-integration.md](../docs/signal-palette-integration.md)
- **Quick Reference:** [docs/semantic-bridge-guide.md](../docs/semantic-bridge-guide.md)
- **Examples:** [examples/](../examples/)
- **GitHub Issues:** https://github.com/lewisflude/signal-nix/issues
- **Discussions:** https://github.com/lewisflude/signal-nix/discussions

---

## Thank You!

Your contribution helps make Signal theming available to more applications and users. We appreciate your effort! 🎨

---

**Last Updated:** 2026-01-20
