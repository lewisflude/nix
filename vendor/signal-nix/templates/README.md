# Signal Module Templates

This directory contains templates for adding new application modules to the Signal Design System. Each template corresponds to a configuration tier in our tier system.

## Quick Start

1. **Choose the right tier** for your application (see [Tier Selection Guide](#tier-selection-guide))
2. **Copy the appropriate template** to `modules/<category>/<app-name>.nix`
3. **Fill in the placeholders** (marked with UPPERCASE_PLACEHOLDER)
4. **Implement the color mapping** using Signal's semantic colors
5. **Test thoroughly** using the testing checklist in the template
6. **Submit your module** following the contribution guidelines

## Available Templates

### Tier 1: Native Theme Options (BEST)

**File:** `tier-1-native-theme.nix`

**Use when:**
- Home-Manager has dedicated theme/color options
- The app has a standard theme format
- You want maximum type safety

**Examples:** bat, helix

**Pros:**
- Full type safety and validation
- Forward-compatible
- Cleanest integration

**Cons:**
- Fewer apps support this
- May require theme file generation

### Tier 2: Structured Colors (GOOD)

**File:** `tier-2-structured-colors.nix`

**Use when:**
- Home-Manager has structured color attrsets
- Colors are organized in typed options
- No native theme system exists

**Examples:** alacritty

**Pros:**
- Type-safe color options
- Clear namespace separation
- Good validation

**Cons:**
- Limited to apps with structured options
- More verbose than Tier 1

### Tier 3: Freeform Settings (ACCEPTABLE)

**File:** `tier-3-freeform-settings.nix`

**Use when:**
- Home-Manager has freeform `settings` option
- Settings serialize to config format
- No better option exists

**Examples:** kitty, ghostty, delta, lazygit, yazi, fuzzel, starship, zellij

**Pros:**
- Works with many apps
- Home-Manager handles serialization
- Relatively clean

**Cons:**
- Limited type validation
- Key names must match exactly
- Runtime errors possible

### Tier 4: Raw Config (LAST RESORT)

**File:** `tier-4-raw-config.nix`

**Use when:**
- Only `extraConfig` or similar string options exist
- Must manually generate config text
- No other tier is possible

**Examples:** wezterm, eza, fzf, neovim, zsh, btop, tmux, gtk

**Pros:**
- Works when nothing else does
- Full control over config generation

**Cons:**
- No type safety or validation
- Syntax errors cause runtime failures
- Requires exact config format knowledge
- Most maintenance burden

## Tier Selection Guide

Use this flowchart to choose the right tier:

```
Does Home-Manager have dedicated theme options?
├─ YES → Use Tier 1 (Native Theme)
└─ NO
    └─ Does Home-Manager have structured color options?
        ├─ YES → Use Tier 2 (Structured Colors)
        └─ NO
            └─ Does Home-Manager have freeform settings?
                ├─ YES → Use Tier 3 (Freeform Settings)
                └─ NO → Use Tier 4 (Raw Config)
```

**Rule of thumb:** Always use the **highest available tier**. This provides the best type safety, validation, and forward compatibility.

## How to Check Which Tier to Use

1. **Search Home-Manager options:**
   ```bash
   # For NixOS/Home-Manager 24.11
   nix-instantiate --eval '<nixpkgs/nixos>' --arg config '{}' -A options.programs.<app-name>
   
   # Or browse online:
   # https://home-manager-options.extranix.com/
   ```

2. **Look for these option patterns:**
   - Tier 1: `programs.<app>.themes`, `programs.<app>.colorscheme`
   - Tier 2: `programs.<app>.settings.colors`, `programs.<app>.colors`
   - Tier 3: `programs.<app>.settings` (untyped attrset)
   - Tier 4: `programs.<app>.extraConfig`, `programs.<app>.initExtra`

3. **Check upstream documentation:**
   - Does the app have a standard theme format? → Tier 1
   - Does the app have structured color options? → Tier 2
   - Does the app support config files Home-Manager can generate? → Tier 3
   - Does everything else fail? → Tier 4

## Template Usage Instructions

### 1. Copy the Template

```bash
# Example: Adding kitty (Tier 3)
cp templates/tier-3-freeform-settings.nix modules/terminals/kitty.nix
```

### 2. Update Metadata Block

Replace the placeholders in the header comment:

```nix
# CONFIGURATION METHOD: freeform-settings (Tier 3)
# HOME-MANAGER MODULE: programs.kitty.settings
# UPSTREAM SCHEMA: https://sw.kovidgoyal.net/kitty/conf/
# SCHEMA VERSION: 0.32.0
# LAST VALIDATED: 2026-01-17
# NOTES: No native theme option available. Home-Manager serializes the settings
#        attrset to kitty.conf format. All keys must match kitty schema exactly.
```

### 3. Replace Placeholders

Search for and replace these placeholders:

- `APP_NAME` → lowercase app name (e.g., `kitty`, `alacritty`)
- `CATEGORY` → category name (e.g., `terminals`, `editors`, `cli`)
- `UPSTREAM_DOCUMENTATION_URL` → link to app's color/theme docs
- `VERSION_NUMBER` → current version of the app
- `YYYY-MM-DD` → today's date
- `THEME_EXTENSION` → file extension for themes (Tier 1 only)

### 4. Implement Color Mapping

Use Signal's semantic color system:

**Tonal colors** (for UI elements):
```nix
signalColors.tonal."surface-base"      # Main background
signalColors.tonal."surface-subtle"    # Secondary background
signalColors.tonal."surface-hover"     # Hover state
signalColors.tonal."text-primary"      # Main text
signalColors.tonal."text-secondary"    # Secondary text
signalColors.tonal."text-tertiary"     # Disabled text
signalColors.tonal."divider-primary"   # Subtle borders
signalColors.tonal."divider-strong"    # Strong borders
signalColors.tonal."black"             # Only for ANSI black
```

**Accent colors** (for highlights):
```nix
accent.primary.Lc60    # Green/Success (darker)
accent.primary.Lc75    # Green/Success (lighter)
accent.secondary.Lc60  # Blue (darker)
accent.secondary.Lc75  # Blue (lighter)
accent.tertiary.Lc60   # Purple (darker)
accent.tertiary.Lc75   # Purple (lighter)
accent.danger.Lc60     # Red (darker)
accent.danger.Lc75     # Red (lighter)
accent.warning.Lc60    # Yellow (darker)
accent.warning.Lc75    # Yellow (lighter)
accent.info.Lc60       # Cyan (darker)
accent.info.Lc75       # Cyan (lighter)
```

**Color formats:**
```nix
colors.surface-base.hex           # "#1a1b26" (most common)
colors.surface-base.rgb           # [26 27 38] (list)
colors.surface-base.oklch         # { l = 0.15; c = 0.02; h = 250; }
```

### 5. Test Your Module

Use the testing checklist in the template:

- [ ] Test in light mode (`theming.signal.mode = "light"`)
- [ ] Test in dark mode (`theming.signal.mode = "dark"`)
- [ ] Test in auto mode (`theming.signal.mode = "auto"`)
- [ ] Verify colors match Signal design system
- [ ] Run `nix flake check`
- [ ] Check app works without Signal theming
- [ ] Verify app-specific targeting works
- [ ] Test in the actual application

### 6. Add Module Import

Add your module to `modules/common/default.nix`:

```nix
{
  # ... existing imports ...
  terminals = [
    ../terminals/alacritty.nix
    ../terminals/kitty.nix
    ../terminals/YOUR_NEW_MODULE.nix  # Add here
  ];
}
```

### 7. Submit Your Contribution

Follow the standard contribution process:

1. Run `nix flake check` to verify everything builds
2. Format with `nixfmt` if available
3. Create a commit with a descriptive message
4. Submit a pull request

## Common Patterns

### Standard ANSI Color Mapping

Most terminal apps use this mapping:

```nix
ansiColors = {
  # Normal colors
  black = signalColors.tonal."black";
  red = accent.danger.Lc75;
  green = accent.primary.Lc75;
  yellow = accent.warning.Lc75;
  blue = accent.secondary.Lc75;
  magenta = accent.tertiary.Lc75;
  cyan = accent.info.Lc75;
  white = signalColors.tonal."text-secondary";

  # Bright colors
  bright-black = signalColors.tonal."text-tertiary";
  bright-red = accent.danger.Lc75;
  bright-green = accent.primary.Lc75;
  bright-yellow = accent.warning.Lc75;
  bright-blue = accent.secondary.Lc75;
  bright-magenta = accent.tertiary.Lc75;
  bright-cyan = accent.info.Lc75;
  bright-white = signalColors.tonal."text-primary";
};
```

### Theme Activation Check

All modules should use the centralized helper:

```nix
shouldTheme = signalLib.shouldThemeApp "app-name" [
  "category"
  "app-name"
] cfg config;
```

This checks:
- If the app is enabled (`programs.app-name.enable`)
- If category targeting is active (`cfg.category.enable`)
- If app-specific targeting is active (`cfg.category.app-name.enable`)

### Mode-Specific Colors (Tier 4)

For raw config that doesn't support dynamic switching:

```nix
themeMode = signalLib.resolveThemeMode cfg.mode;

colors = if themeMode == "light" then {
  background = signalColors.tonal."surface-subtle".hex;
  # ... light colors ...
} else {
  background = signalColors.tonal."surface-base".hex;
  # ... dark colors ...
};
```

## Module Helpers (mkAppModule)

**NEW:** Signal now provides `mkAppModule` helpers to reduce boilerplate and standardize module creation. These are optional but recommended for new modules.

### Available Helpers

#### `mkTier3Module` - For Freeform Settings

Best for apps with `programs.<app>.settings` option (Tier 3):

```nix
{
  config,
  lib,
  signalColors,
  signalLib,
  ...
}:
let
  ansiColors = signalLib.makeAnsiColors signalColors;
  uiColors = signalLib.makeUIColors signalColors;
in
signalLib.mkTier3Module {
  appName = "kitty";
  category = [ "terminals" ];
  
  settingsGenerator = _: {
    foreground = uiColors.text-primary.hex;
    background = uiColors.surface-base.hex;
    # ... rest of settings ...
  };
}
```

**Benefits:**
- Automatically handles theme activation logic
- Uses standard `shouldThemeApp` check
- Reduces from ~120 lines to ~80 lines
- More maintainable and consistent

#### `mkTier2Module` - For Structured Colors

Best for apps with typed color options (Tier 2):

```nix
signalLib.mkTier2Module {
  appName = "alacritty";
  category = [ "terminals" ];
  configPath = [ "settings" "colors" ];
  
  colorMapping = signalColors: {
    primary = {
      background = signalColors.tonal."surface-base".hex;
      foreground = signalColors.tonal."text-primary".hex;
    };
    # ... rest of colors ...
  };
}
```

#### `mkTier4Module` - For Raw Config

Best for apps with `extraConfig` strings (Tier 4):

```nix
signalLib.mkTier4Module {
  appName = "tmux";
  category = [ "multiplexers" ];
  configOption = "extraConfig";
  
  configGenerator = signalColors: themeMode: pkgs: ''
    set -g status-bg ${signalColors.tonal."surface-base".hex}
    set -g status-fg ${signalColors.tonal."text-primary".hex}
  '';
}
```

### Color Mapping Helpers

#### `makeAnsiColors` - Standard ANSI Terminal Colors

Generates the standard 16-color ANSI palette:

```nix
let
  ansiColors = signalLib.makeAnsiColors signalColors;
in
{
  color0 = ansiColors.black.hex;
  color1 = ansiColors.red.hex;
  color2 = ansiColors.green.hex;
  # ... etc ...
}
```

**Includes:**
- Normal colors: black, red, green, yellow, blue, magenta, cyan, white
- Bright colors: bright-black through bright-white

#### `makeUIColors` - Standard UI Colors

Generates common UI color roles:

```nix
let
  uiColors = signalLib.makeUIColors signalColors;
in
{
  # Surface colors
  background = uiColors.surface-base.hex;
  sidebar = uiColors.surface-subtle.hex;
  
  # Text colors
  foreground = uiColors.text-primary.hex;
  dimmed = uiColors.text-secondary.hex;
  
  # Accent colors
  link = uiColors.accent-secondary.hex;
  success = uiColors.success.hex;
  warning = uiColors.warning.hex;
  danger = uiColors.danger.hex;
}
```

**Includes:**
- Surface: base, subtle, hover
- Text: primary, secondary, tertiary
- Divider: primary, strong
- Accent: primary, secondary, tertiary
- Semantic: success, warning, danger, info

### When to Use Helpers

**Use mkAppModule helpers when:**
- ✅ Creating a new module from scratch
- ✅ Refactoring an existing module
- ✅ You want less boilerplate
- ✅ You want consistent patterns

**Manual implementation when:**
- ⚠️ Very complex custom logic needed
- ⚠️ Unusual Home Manager integration
- ⚠️ Module requires special handling

### Migration Guide

To migrate an existing module to use helpers:

1. **Identify the tier** - Check what your module uses (settings, colors, etc.)
2. **Extract color logic** - Move color definitions to the generator function
3. **Use color helpers** - Replace manual ANSI/UI colors with `makeAnsiColors`/`makeUIColors`
4. **Test thoroughly** - Verify `nix flake check` passes
5. **Compare output** - Ensure generated config is identical

**Example migration:**

<details>
<summary>Before (127 lines)</summary>

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
  
  colors = {
    surface-base = signalColors.tonal."surface-subtle";
    text-primary = signalColors.tonal."text-primary";
    # ... more colors ...
  };
  
  ansiColors = {
    black = signalColors.tonal."black";
    red = signalColors.accent.danger.Lc75;
    # ... 16 ANSI colors ...
  };
  
  shouldTheme = signalLib.shouldThemeApp "kitty" [
    "terminals"
    "kitty"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.kitty = {
      settings = {
        foreground = colors.text-primary.hex;
        background = colors.surface-base.hex;
        color0 = ansiColors.black.hex;
        # ... 50+ more settings ...
      };
    };
  };
}
```
</details>

<details>
<summary>After (98 lines)</summary>

```nix
{
  config,
  lib,
  signalColors,
  signalLib,
  ...
}:
let
  ansiColors = signalLib.makeAnsiColors signalColors;
  uiColors = signalLib.makeUIColors signalColors;
in
signalLib.mkTier3Module {
  appName = "kitty";
  category = [ "terminals" ];
  
  settingsGenerator = _: {
    foreground = uiColors.text-primary.hex;
    background = uiColors.surface-base.hex;
    color0 = ansiColors.black.hex;
    # ... 50+ more settings ...
  };
}
```
</details>

**Lines saved:** 29 lines (23% reduction)  
**Boilerplate removed:** Theme activation, color definitions, mkIf logic

## Best Practices

### DO:
- ✅ Use semantic color names (e.g., `surface-base`, `text-primary`)
- ✅ Test both light and dark modes
- ✅ Use `signalLib.shouldThemeApp` for activation checks
- ✅ Document any special color requirements in NOTES
- ✅ Keep the metadata block up to date
- ✅ Test in the actual application, not just Nix evaluation

### DON'T:
- ❌ Hardcode hex colors directly
- ❌ Use arbitrary color mappings without semantic meaning
- ❌ Skip the testing checklist
- ❌ Forget to update LAST VALIDATED date
- ❌ Mix tiers (e.g., using Tier 4 when Tier 3 is available)

## Troubleshooting

### "Option does not exist" errors

**Problem:** Home-Manager doesn't recognize the option.

**Solution:**
- Verify Home-Manager version compatibility
- Check option name spelling
- Ensure the app's Home-Manager module is available

### Colors don't appear in the app

**Problem:** App shows default colors instead of Signal colors.

**Solution:**
- Check that `theming.signal.enable = true`
- Verify the app is enabled (`programs.app.enable = true`)
- Check app-specific targeting isn't disabled
- Look for config file in `~/.config/app/` to verify generation

### Wrong color format

**Problem:** App doesn't accept the color format.

**Solution:**
- Check upstream docs for required format
- Try `.hex` for hex colors
- Try `.rgb` for RGB lists
- Some apps need strings like `"rgb(r, g, b)"`

### Build failures

**Problem:** `nix flake check` fails.

**Solution:**
- Check for syntax errors in your Nix code
- Verify all variables are defined
- Ensure imports are correct
- Run `nix flake check --show-trace` for detailed errors

## Related Documentation

- [Tier System](../docs/tier-system.md) - Detailed tier system explanation
- [Integration Standards](../docs/integration-standards.md) - Integration guidelines
- [Design Principles](../docs/design-principles.md) - Color usage philosophy
- [Testing Guide](../docs/TESTING_GUIDE.md) - Comprehensive testing guidance ← **Recommended!**
- [Testing Overview](../docs/testing.md) - Test suite overview
- [Contribution Guide](../CONTRIBUTING.md) - How to contribute
- [Contributing Applications](../CONTRIBUTING_APPLICATIONS.md) - Step-by-step app guide

## Examples

Real-world examples of each tier:

- **Tier 1:** [bat](../modules/cli/bat.nix) - Native theme with tmTheme generation
- **Tier 2:** [alacritty](../modules/terminals/alacritty.nix) - Structured color options
- **Tier 3:** [kitty](../modules/terminals/kitty.nix) - Freeform settings
- **Tier 4:** [gtk](../modules/gtk/default.nix) - Raw CSS generation

## Questions?

- Check existing modules for examples
- Read the [tier system documentation](../docs/tier-system.md)
- Ask in GitHub Discussions
- Open an issue for clarification

---

**Remember:** Always use the **highest available tier** for the best integration quality!
