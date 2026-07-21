# Contributing New Applications to Signal

> **A step-by-step guide for adding application theming support to Signal Design System**

This guide walks you through adding a new application module to Signal. It's designed for first-time contributors and provides everything you need from research to submission.

## Table of Contents

- [Before You Start](#before-you-start)
- [Quick Start Checklist](#quick-start-checklist)
- [Step-by-Step Guide](#step-by-step-guide)
  - [Step 1: Research the Application](#step-1-research-the-application)
  - [Step 2: Choose the Configuration Tier](#step-2-choose-the-configuration-tier)
  - [Step 3: Set Up Your Module](#step-3-set-up-your-module)
  - [Step 4: Implement Color Mapping](#step-4-implement-color-mapping)
  - [Step 5: Test Your Module](#step-5-test-your-module)
  - [Step 6: Integrate and Document](#step-6-integrate-and-document)
  - [Step 7: Submit Your Contribution](#step-7-submit-your-contribution)
- [Decision Tree: Choosing the Right Tier](#decision-tree-choosing-the-right-tier)
- [Example Implementations](#example-implementations)
- [Testing Checklist](#testing-checklist)
- [Pull Request Checklist](#pull-request-checklist)
- [Common Pitfalls](#common-pitfalls)
- [Getting Help](#getting-help)

## Before You Start

### Prerequisites

Make sure you have:

- ✅ Nix installed with flakes enabled ([DeterminateSystems installer](https://github.com/DeterminateSystems/nix-installer) recommended)
- ✅ Basic understanding of Nix syntax and the module system
- ✅ Familiarity with Home Manager configuration
- ✅ The application you want to theme installed and working

### Required Reading

Before contributing, please read:

1. **[Design Principles](docs/design-principles.md)** - Understand Signal's philosophy
2. **[Tier System](docs/tier-system.md)** - Configuration method hierarchy
3. **[Template README](templates/README.md)** - Template usage guide

### Recommended Resources

- [Signal Philosophy](https://github.com/lewisflude/signal-palette/blob/main/docs/philosophy.md) - Color system rationale
- [OKLCH Color Space](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl) - Why we use OKLCH
- [Home Manager Options](https://home-manager-options.extranix.com/) - Browse available options

## Quick Start Checklist

Use this condensed checklist for experienced contributors:

- [ ] Research application's config format and theming capabilities
- [ ] Determine configuration tier (1-4) based on Home Manager options
- [ ] Copy appropriate template from `templates/` directory
- [ ] Replace placeholders with application-specific values
- [ ] Map Signal colors to application schema
- [ ] Test in both light and dark modes
- [ ] Add module import to `modules/common/default.nix`
- [ ] Run `nix flake check` to verify
- [ ] Create example configuration
- [ ] Update documentation (README, integration-standards)
- [ ] Submit pull request with clear description

## Step-by-Step Guide

### Step 1: Research the Application

Before writing any code, gather information about the application you want to theme.

#### 1.1 Understand the Application's Theming

**Questions to answer:**

- How does this application handle colors?
- What configuration format does it use? (TOML, YAML, JSON, INI, etc.)
- Where does it store its configuration files?
- Does it have built-in theme support?
- Are there existing color schemes you can reference?

**Resources:**

- Check the application's official documentation
- Look for theming guides in the upstream repository
- Search for existing color schemes/themes
- Review configuration file examples

**Example research notes:**

```markdown
Application: kitty
Config Format: kitty.conf (custom format)
Config Location: ~/.config/kitty/kitty.conf
Theming Support: Yes - color{0-15}, foreground, background, cursor, etc.
Upstream Docs: https://sw.kovidgoyal.net/kitty/conf/
Version: 0.32.0
```

#### 1.2 Check Home Manager Integration

**Check what options Home Manager provides:**

```bash
# Search for the app in Home Manager options
nix-instantiate --eval '<nixpkgs/nixos>' --arg config '{}' -A options.programs.<app-name>

# Or browse online
# https://home-manager-options.extranix.com/
```

**Look for these patterns:**

- `programs.<app>.themes` or `programs.<app>.theme` → Tier 1 (native theme)
- `programs.<app>.colors` or `programs.<app>.settings.colors` → Tier 2 (structured)
- `programs.<app>.settings` (freeform attrset) → Tier 3 (freeform)
- `programs.<app>.extraConfig` or `programs.<app>.initExtra` → Tier 4 (raw)

**Example:**

```nix
# Found for kitty:
programs.kitty.settings = lib.mkOption {
  type = types.attrsOf types.anything;
  # This is freeform → Tier 3
}
```

#### 1.3 Document Your Findings

Create a research summary you can reference:

```markdown
# Kitty Terminal Research

## Home Manager Module
- **Option**: `programs.kitty.settings` (freeform attrset)
- **Tier**: 3 (Freeform Settings)
- **HM Docs**: https://home-manager-options.extranix.com/...

## Color Configuration
- **Format**: Key-value pairs in kitty.conf
- **Color Properties**:
  - foreground, background, cursor
  - selection_foreground, selection_background
  - color0-color15 (ANSI colors)

## Upstream Documentation
- **Config Docs**: https://sw.kovidgoyal.net/kitty/conf/
- **Color Scheme**: https://sw.kovidgoyal.net/kitty/conf/#color-scheme
- **Version**: 0.32.0
```

### Step 2: Choose the Configuration Tier

Signal uses a 4-tier configuration hierarchy. **Always use the highest available tier** for best type safety and maintainability.

#### Tier Decision Flow

```
┌─────────────────────────────────────────────┐
│ Does Home Manager have dedicated theme      │
│ options (programs.<app>.themes)?            │
└──┬────────────────────────────┬─────────────┘
   │ YES                        │ NO
   ▼                            ▼
┌──────────────┐    ┌──────────────────────────┐
│  USE TIER 1  │    │ Does HM have structured  │
│ Native Theme │    │ color options?           │
└──────────────┘    └──┬────────────┬──────────┘
                       │ YES        │ NO
                       ▼            ▼
                  ┌──────────┐  ┌─────────────────┐
                  │USE TIER 2│  │ Does HM have    │
                  │Structured│  │ freeform        │
                  │  Colors  │  │ settings?       │
                  └──────────┘  └──┬──────┬───────┘
                                   │ YES  │ NO
                                   ▼      ▼
                              ┌─────────┐ ┌─────────┐
                              │USE TIER3│ │USE TIER4│
                              │Freeform │ │   Raw   │
                              │Settings │ │ Config  │
                              └─────────┘ └─────────┘
```

#### Tier Descriptions

| Tier | Method | When to Use | Examples |
|------|--------|-------------|----------|
| **1** | Native theme options | HM has dedicated theme support | bat, helix, rofi, waybar |
| **2** | Structured colors | HM has typed color options | alacritty, sway, i3 |
| **3** | Freeform settings | HM has untyped settings attrset | kitty, ghostty, delta, fuzzel |
| **4** | Raw config | No better option exists | wezterm, tmux, gtk, vim |

**Rule of thumb:** If multiple tiers are possible, choose the **highest number** (Tier 1 is best).

#### Tier Examples

**Tier 1 Example (bat):**
```nix
programs.bat.themes.signal.src = pkgs.writeText "signal.tmTheme" (generateTheme colors);
```

**Tier 2 Example (alacritty):**
```nix
programs.alacritty.settings.colors = {
  primary.background = colors.surface-base.hex;
  primary.foreground = colors.text-primary.hex;
};
```

**Tier 3 Example (kitty):**
```nix
programs.kitty.settings = {
  foreground = colors.text-primary.hex;
  background = colors.surface-base.hex;
  color0 = ansiColors.black.hex;
};
```

**Tier 4 Example (tmux):**
```nix
programs.tmux.extraConfig = ''
  set -g status-bg ${colors.surface-base.hex}
  set -g status-fg ${colors.text-primary.hex}
'';
```

### Step 3: Set Up Your Module

Once you've determined the tier, set up your module file using the appropriate template.

#### 3.1 Copy the Template

```bash
# Navigate to your signal-nix fork
cd signal-nix

# Enter development shell
nix develop

# Copy the appropriate template
# Replace <tier> with tier-1, tier-2, tier-3, or tier-4
# Replace <category> with terminals, editors, cli, etc.
# Replace <app-name> with your application name
cp templates/<tier>-*.nix modules/<category>/<app-name>.nix
```

**Example:**
```bash
# For kitty (Tier 3, terminal)
cp templates/tier-3-freeform-settings.nix modules/terminals/kitty.nix
```

#### 3.2 Update the Metadata Block

Every module **must** start with a metadata comment block. Update it with your application's details:

```nix
{
  config,
  lib,
  signalColors,
  signalLib,
  ...
}:
# CONFIGURATION METHOD: freeform-settings (Tier 3)
# HOME-MANAGER MODULE: programs.kitty.settings
# UPSTREAM SCHEMA: https://sw.kovidgoyal.net/kitty/conf/
# SCHEMA VERSION: 0.32.0
# LAST VALIDATED: 2026-01-18
# NOTES: No native theme option available. Home-Manager serializes the settings
#        attrset to kitty.conf format. All keys must match kitty schema exactly.
let
  # ... your implementation
```

**Metadata fields explained:**

- **CONFIGURATION METHOD**: The tier name (native-theme, structured-colors, freeform-settings, raw-config)
- **HOME-MANAGER MODULE**: The exact Home Manager option path you're configuring
- **UPSTREAM SCHEMA**: Link to the application's configuration documentation
- **SCHEMA VERSION**: Current version of the application
- **LAST VALIDATED**: Today's date (YYYY-MM-DD format)
- **NOTES**: Any important context about why this tier was chosen or special considerations

#### 3.3 Replace Template Placeholders

Search for and replace these placeholders in the template:

| Placeholder | Replace With | Example |
|------------|--------------|---------|
| `APP_NAME` | Lowercase app name | `kitty` |
| `CATEGORY` | Category name | `terminals` |
| `UPSTREAM_DOCUMENTATION_URL` | Config docs URL | `https://...` |
| `VERSION_NUMBER` | Current version | `0.32.0` |
| `YYYY-MM-DD` | Today's date | `2026-01-18` |
| `THEME_EXTENSION` | Theme file extension (Tier 1 only) | `tmTheme` |

**Tip:** Use find-and-replace in your editor:
```bash
# In vim/neovim
:%s/APP_NAME/kitty/g
:%s/CATEGORY/terminals/g

# Or use sed
sed -i 's/APP_NAME/kitty/g' modules/terminals/kitty.nix
```

### Step 4: Implement Color Mapping

Now for the core work: mapping Signal's colors to your application's schema.

#### 4.1 Understanding Signal Colors

Signal provides colors through the `signalColors` argument:

**Tonal colors** (for UI elements):
```nix
signalColors.tonal."surface-base"      # Main background
signalColors.tonal."surface-subtle"    # Secondary background  
signalColors.tonal."surface-hover"     # Hover states
signalColors.tonal."text-primary"      # Primary text
signalColors.tonal."text-secondary"    # Secondary text
signalColors.tonal."text-tertiary"     # Disabled/tertiary text
signalColors.tonal."divider-primary"   # Subtle borders
signalColors.tonal."divider-strong"    # Strong borders
signalColors.tonal."black"             # True black (for ANSI only)
```

**Accent colors** (for highlights and semantic meaning):
```nix
signalColors.accent.primary.Lc60       # Green (darker)
signalColors.accent.primary.Lc75       # Green (lighter)
signalColors.accent.secondary.Lc60     # Blue (darker)
signalColors.accent.secondary.Lc75     # Blue (lighter)
signalColors.accent.tertiary.Lc60      # Purple (darker)
signalColors.accent.tertiary.Lc75      # Purple (lighter)
signalColors.accent.danger.Lc60        # Red (darker)
signalColors.accent.danger.Lc75        # Red (lighter)
signalColors.accent.warning.Lc60       # Yellow (darker)
signalColors.accent.warning.Lc75       # Yellow (lighter)
signalColors.accent.info.Lc60          # Cyan (darker)
signalColors.accent.info.Lc75          # Cyan (lighter)
```

**Color formats:**
```nix
signalColors.tonal."surface-base".hex           # "#1a1b26" (most common)
signalColors.tonal."surface-base".hexRaw        # "1a1b26" (no #)
signalColors.tonal."surface-base".rgb           # { r = 26; g = 27; b = 38; }
signalColors.tonal."surface-base".oklch         # { l = 0.15; c = 0.02; h = 250; }
```

#### 4.2 Using Color Helpers

Signal provides helper functions to generate standard color palettes:

**ANSI Colors (for terminals):**
```nix
let
  ansiColors = signalLib.makeAnsiColors signalColors;
in {
  color0 = ansiColors.black.hex;            # Normal black
  color1 = ansiColors.red.hex;              # Normal red
  color2 = ansiColors.green.hex;            # Normal green
  color3 = ansiColors.yellow.hex;           # Normal yellow
  color4 = ansiColors.blue.hex;             # Normal blue
  color5 = ansiColors.magenta.hex;          # Normal magenta
  color6 = ansiColors.cyan.hex;             # Normal cyan
  color7 = ansiColors.white.hex;            # Normal white
  color8 = ansiColors.bright-black.hex;     # Bright black (gray)
  color9 = ansiColors.bright-red.hex;       # Bright red
  color10 = ansiColors.bright-green.hex;    # Bright green
  color11 = ansiColors.bright-yellow.hex;   # Bright yellow
  color12 = ansiColors.bright-blue.hex;     # Bright blue
  color13 = ansiColors.bright-magenta.hex;  # Bright magenta
  color14 = ansiColors.bright-cyan.hex;     # Bright cyan
  color15 = ansiColors.bright-white.hex;    # Bright white
}
```

**UI Colors (for applications):**
```nix
let
  uiColors = signalLib.makeUIColors signalColors;
in {
  background = uiColors.surface-base.hex;
  foreground = uiColors.text-primary.hex;
  selection-bg = uiColors.surface-hover.hex;
  cursor = uiColors.accent-secondary.hex;
  success = uiColors.success.hex;
  warning = uiColors.warning.hex;
  danger = uiColors.danger.hex;
}
```

#### 4.3 Semantic Color Mapping

Map colors based on their **semantic meaning**, not arbitrary choices:

| Element | Signal Color | Rationale |
|---------|-------------|-----------|
| Main background | `surface-base` | Primary surface |
| Secondary background | `surface-subtle` | De-emphasized areas |
| Hover background | `surface-hover` | Interactive states |
| Primary text | `text-primary` | Main content |
| Secondary text | `text-secondary` | Supporting content |
| Disabled text | `text-tertiary` | Non-interactive |
| Subtle border | `divider-primary` | Soft separators |
| Strong border | `divider-strong` | Prominent separators |
| Success indicator | `accent.primary.Lc75` | Positive feedback |
| Warning indicator | `accent.warning.Lc75` | Caution |
| Error indicator | `accent.danger.Lc75` | Errors |
| Info/Link | `accent.secondary.Lc75` | Information |

#### 4.4 Example Color Mapping

**Terminal example (kitty):**

```nix
let
  ansiColors = signalLib.makeAnsiColors signalColors;
  uiColors = signalLib.makeUIColors signalColors;
in {
  # Basic UI
  foreground = uiColors.text-primary.hex;
  background = uiColors.surface-base.hex;
  selection_foreground = uiColors.text-primary.hex;
  selection_background = uiColors.surface-hover.hex;
  cursor = uiColors.accent-secondary.hex;
  cursor_text_color = uiColors.surface-base.hex;
  
  # ANSI colors (0-15)
  color0 = ansiColors.black.hex;
  color1 = ansiColors.red.hex;
  color2 = ansiColors.green.hex;
  color3 = ansiColors.yellow.hex;
  color4 = ansiColors.blue.hex;
  color5 = ansiColors.magenta.hex;
  color6 = ansiColors.cyan.hex;
  color7 = ansiColors.white.hex;
  color8 = ansiColors.bright-black.hex;
  color9 = ansiColors.bright-red.hex;
  color10 = ansiColors.bright-green.hex;
  color11 = ansiColors.bright-yellow.hex;
  color12 = ansiColors.bright-blue.hex;
  color13 = ansiColors.bright-magenta.hex;
  color14 = ansiColors.bright-cyan.hex;
  color15 = ansiColors.bright-white.hex;
  
  # URL colors
  url_color = uiColors.accent-secondary.hex;
}
```

#### 4.5 Using mkAppModule Helpers (Recommended)

For cleaner, more maintainable code, use Signal's module helpers:

**Tier 3 example with helper:**
```nix
{
  config,
  lib,
  signalColors,
  signalLib,
  ...
}:
# CONFIGURATION METHOD: freeform-settings (Tier 3)
# HOME-MANAGER MODULE: programs.kitty.settings
# UPSTREAM SCHEMA: https://sw.kovidgoyal.net/kitty/conf/
# SCHEMA VERSION: 0.32.0
# LAST VALIDATED: 2026-01-18
# NOTES: Using mkTier3Module helper for reduced boilerplate
let
  ansiColors = signalLib.makeAnsiColors signalColors;
  uiColors = signalLib.makeUIColors signalColors;
in
signalLib.mkTier3Module {
  appName = "kitty";
  category = [ "terminals" ];
  
  settingsGenerator = _: {
    # All the color mappings from above
    foreground = uiColors.text-primary.hex;
    background = uiColors.surface-base.hex;
    # ... etc
  };
}
```

**Benefits of using helpers:**
- ✅ 20-30% less code
- ✅ Automatic theme activation logic
- ✅ Consistent patterns across modules
- ✅ Less boilerplate to maintain

See `templates/README.md` for full documentation on `mkAppModule` helpers.

### Step 5: Test Your Module

Thorough testing ensures your module works correctly in all scenarios.

> **📖 For comprehensive testing guidance, see [docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md)**
>
> The Testing Guide provides detailed information on:
> - Writing unit tests for library functions
> - Writing integration tests for module validation  
> - Choosing between test types with decision trees
> - Test templates for common patterns
> - Debugging test failures with examples
> - Performance optimization tips
>
> **This section covers the basics. Refer to the Testing Guide for complete details.**

#### 5.1 Quick Testing Overview

Signal uses a **hybrid testing approach**:

**Unit Tests** (`tests/unit/`) - For pure functions:
- Library function tests
- Color manipulation tests  
- Theme resolution tests
- Fast execution (< 1s per test)

**Integration Tests** (`tests/integration/`) - For module validation:
- Module structure tests
- Configuration generation tests
- Pattern matching with grep
- Slower execution (~2-5s per test)

**Required tests for your module:**
- ✅ Module structure test (validates file exists and has correct structure)
- ✅ Color configuration test (if applicable)
- ✅ Theme resolution test (for Tier 1-2 modules)

See [docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md) for test templates and detailed examples.

#### 5.2 Add Module Import

First, make your module available by adding it to the imports in `modules/common/default.nix`:

```nix
# modules/common/default.nix
{
  # ... existing code ...
  
  imports = [
    # ... existing imports ...
    
    # Terminals
    ../terminals/alacritty.nix
    ../terminals/ghostty.nix
    ../terminals/kitty.nix        # Add your module here
    # ../terminals/wezterm.nix
    
    # ... rest of imports ...
  ];
}
```

Find the appropriate section for your category and add your module there.

#### 5.3 Static Validation

Run these checks to catch syntax and evaluation errors:

```bash
# Format your code
nix fmt

# Check for anti-patterns
statix check .

# Check for dead code
deadnix .

# Validate flake
nix flake check

# Check module evaluates
nix eval .#homeManagerModules.default
```

All of these should pass without errors.

#### 5.4 Create a Test Configuration

Create a minimal test configuration to verify your module works:

```nix
# test-my-app.nix
{
  imports = [ ./modules/common/default.nix ];
  
  # Enable the program
  programs.kitty.enable = true;
  
  # Enable Signal theming
  theming.signal = {
    enable = true;
    mode = "dark";
    
    # Enable your specific module
    terminals.kitty.enable = true;
  };
}
```

Evaluate it:
```bash
nix-instantiate --eval --strict test-my-app.nix
```

#### 5.5 Visual Testing

Test in the actual application to verify colors appear correctly:

**Dark mode test:**
```nix
# In your home-manager configuration
theming.signal.mode = "dark";
theming.signal.terminals.kitty.enable = true;
```

```bash
# Rebuild and activate
home-manager switch --flake .

# Launch the app and verify:
# ✓ Background is dark
# ✓ Text is light and readable
# ✓ Colors match Signal palette
# ✓ ANSI colors work in terminal output
# ✓ No error messages in app logs
```

**Light mode test:**
```nix
theming.signal.mode = "light";
```

```bash
# Rebuild and verify light theme
home-manager switch --flake .

# Check:
# ✓ Background is light
# ✓ Text is dark and readable
# ✓ Colors are appropriate for light mode
# ✓ Sufficient contrast for accessibility
```

**Auto mode test:**
```nix
theming.signal.mode = "auto";
```

Currently "auto" resolves to "dark" (future: system theme detection).

#### 5.6 AutoEnable Testing

Test that auto-detection works:

```nix
theming.signal = {
  enable = true;
  autoEnable = true;  # Should auto-theme all enabled programs
  mode = "dark";
};

programs.kitty.enable = true;  # Kitty should be themed automatically
```

```bash
home-manager switch --flake .

# Verify:
# ✓ Kitty is themed even without explicit terminals.kitty.enable
# ✓ Config file contains Signal colors
```

#### 5.7 App-Specific Targeting

Test that your module respects targeting options:

**Enable test:**
```nix
theming.signal.terminals.kitty.enable = true;  # Explicit enable
programs.kitty.enable = true;
```
Result: Kitty should be themed ✓

**Disable test:**
```nix
theming.signal.autoEnable = true;
theming.signal.terminals.kitty.enable = false;  # Explicit disable
programs.kitty.enable = true;
```
Result: Kitty should NOT be themed (respects explicit disable) ✓

#### 5.8 Config File Verification

Check that the generated config file contains your colors:

```bash
# Find the config file location (varies by app)
cat ~/.config/kitty/kitty.conf

# Look for Signal colors
# Should see hex colors like #1a1b26, #c5cdd8, etc.

# Verify no syntax errors
kitty --debug-config
```

### Step 6: Integrate and Document

Once testing passes, integrate your module into the project and document it properly.

#### 6.1 Update Module Imports

You already added the import in Step 5.1. Double-check it's in the right place:

```nix
# modules/common/default.nix
imports = [
  # Group by category
  # Terminals
  ../terminals/alacritty.nix
  ../terminals/ghostty.nix
  ../terminals/kitty.nix        # ← Your module
  
  # Editors
  ../editors/helix.nix
  # ...
];
```

#### 6.2 Update README.md

Add your application to the main README's supported applications list:

```markdown
<!-- Find the appropriate category in README.md -->

### Terminals
- **Alacritty** - GPU-accelerated terminal
- **Ghostty** - Fast, native, GTK terminal
- **Kitty** - Fast, GPU-based terminal emulator  ← Add this line
- **WezTerm** - GPU-accelerated cross-platform terminal
```

Keep the list alphabetically sorted within each category.

#### 6.3 Update Integration Standards

Update `docs/integration-standards.md` to mark your application as completed:

```markdown
### ✅ Terminals (5/5 major)
- Alacritty (Tier 2) ✅
- Ghostty (Tier 3) ✅
- Kitty (Tier 3) ✅        ← Update status
- WezTerm (Tier 4) ✅
- Foot (Tier 2) ✅
```

If your application was in a TODO section, move it to the completed section.

#### 6.4 Create Example Configuration (Optional)

For complex integrations or common use cases, add an example:

```nix
# examples/kitty-custom.nix
{
  theming.signal = {
    enable = true;
    mode = "dark";
    
    terminals.kitty.enable = true;
  };
  
  programs.kitty = {
    enable = true;
    
    # Additional kitty settings
    settings = {
      font_family = "JetBrains Mono";
      font_size = 12;
    };
  };
}
```

Examples should be:
- Self-contained and working
- Demonstrate specific features
- Include explanatory comments

#### 6.5 Update CHANGELOG.md

Add an entry for your contribution:

```markdown
## [Unreleased]

### Added
- Support for Kitty terminal emulator (Tier 3)

### Changed
<!-- ... -->
```

Use the appropriate category:
- **Added** - New features/modules
- **Changed** - Changes to existing functionality
- **Fixed** - Bug fixes
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Security** - Security fixes

### Step 7: Submit Your Contribution

Time to share your work with the project!

#### 7.1 Format and Lint

Run all checks one final time:

```bash
# Format code
nix fmt

# Run linters
statix check .
deadnix .

# Run full flake check
nix flake check
```

Fix any issues that are reported.

#### 7.2 Commit Your Changes

Write a clear, descriptive commit message:

```bash
git add modules/terminals/kitty.nix
git add modules/common/default.nix
git add README.md
git add docs/integration-standards.md
git add CHANGELOG.md

git commit -m "feat: add kitty terminal support

- Implement Tier 3 (freeform settings) module
- Full ANSI color support (color0-15)
- Support for both dark and light modes
- Uses mkTier3Module helper for clean implementation
- Includes comprehensive color mapping
- Tested with kitty 0.32.0

Closes #123"
```

**Commit message format:**
```
<type>: <short summary>

<detailed description>

<optional footer>
```

**Types:**
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `refactor:` - Code refactoring
- `test:` - Test additions/changes
- `chore:` - Maintenance tasks

#### 7.3 Push Your Branch

```bash
# Push to your fork
git push origin feature/add-kitty-support

# If you need to update an existing branch
git push --force-with-lease origin feature/add-kitty-support
```

#### 7.4 Create Pull Request

On GitHub, create a pull request with:

**Title:**
```
feat: add kitty terminal support
```

**Description (use the PR template):**

```markdown
## Description
Adds Signal theming support for Kitty terminal emulator using Tier 3 (freeform settings).

## Changes
- [ ] Implemented `modules/terminals/kitty.nix`
- [ ] Added module import to `modules/common/default.nix`
- [ ] Updated README.md with kitty entry
- [ ] Updated docs/integration-standards.md
- [ ] Updated CHANGELOG.md

## Implementation Details
- **Tier**: 3 (Freeform Settings)
- **Reason**: Kitty uses `programs.kitty.settings` attrset
- **Color mapping**: Full ANSI (16 colors) + UI colors
- **Helper**: Uses `mkTier3Module` for reduced boilerplate

## Testing
- [x] Tested in dark mode
- [x] Tested in light mode
- [x] Tested with autoEnable
- [x] Verified config file generation
- [x] Run `nix flake check` successfully
- [x] Tested in actual application

## Screenshots (optional)
[Add screenshots showing the themed application]

## Related Issues
Closes #123

## Additional Notes
Kitty version tested: 0.32.0
```

#### 7.5 Respond to Review Feedback

After submission:

1. **Be responsive** - Check GitHub notifications regularly
2. **Be receptive** - Reviews help improve code quality
3. **Make requested changes** - Update your PR branch
4. **Ask questions** - If feedback is unclear, ask for clarification
5. **Test again** - After making changes, re-test everything

#### 7.6 After Merge

Once your PR is merged:

1. **Celebrate!** 🎉 You've contributed to Signal!
2. **Pull latest changes** - Update your fork
3. **Close related issues** - If you opened issues for this feature
4. **Share your work** - Blog about it, tweet it, etc.

## Decision Tree: Choosing the Right Tier

Use this decision tree to determine the correct tier for your application:

```
START: Research Home Manager options for your application
   ↓
   ├─ Found programs.<app>.themes or programs.<app>.theme?
   │     ↓ YES
   │     └─→ ✅ USE TIER 1 (Native Theme)
   │          Examples: bat, helix, rofi
   │          Template: tier-1-native-theme.nix
   │
   ├─ Found programs.<app>.colors (structured attrset)?
   │     ↓ YES
   │     └─→ ✅ USE TIER 2 (Structured Colors)
   │          Examples: alacritty, sway
   │          Template: tier-2-structured-colors.nix
   │
   ├─ Found programs.<app>.settings (freeform attrset)?
   │     ↓ YES
   │     └─→ ✅ USE TIER 3 (Freeform Settings)
   │          Examples: kitty, ghostty, delta
   │          Template: tier-3-freeform-settings.nix
   │
   └─ Only found programs.<app>.extraConfig or similar?
         ↓ YES
         └─→ ⚠️  USE TIER 4 (Raw Config)
              Examples: tmux, gtk, wezterm
              Template: tier-4-raw-config.nix
              Note: Last resort only!
```

**Important:** Never use a lower tier when a higher tier is available. Higher tiers provide better type safety, validation, and maintainability.

## Example Implementations

Learn from these real-world examples in the Signal codebase:

### Tier 1: bat (Native Theme)

**File:** `modules/cli/bat.nix`

**Key features:**
- Uses `programs.bat.themes` option
- Generates tmTheme XML file
- Full type safety
- Forward-compatible

**Excerpt:**
```nix
programs.bat.themes.signal = {
  src = pkgs.writeText "signal.tmTheme" (generateTheme signalColors);
  file = "signal.tmTheme";
};
```

### Tier 2: alacritty (Structured Colors)

**File:** `modules/terminals/alacritty.nix`

**Key features:**
- Uses `programs.alacritty.settings.colors` structured attrset
- Type-safe color options
- Clear namespace separation

**Excerpt:**
```nix
programs.alacritty.settings.colors = {
  primary = {
    background = signalColors.tonal."surface-base".hex;
    foreground = signalColors.tonal."text-primary".hex;
  };
  normal = {
    black = ansiColors.black.hex;
    red = ansiColors.red.hex;
    # ...
  };
};
```

### Tier 3: kitty (Freeform Settings)

**File:** `modules/terminals/kitty.nix`

**Key features:**
- Uses `programs.kitty.settings` freeform attrset
- Full ANSI color support
- Uses `mkTier3Module` helper

**Excerpt:**
```nix
signalLib.mkTier3Module {
  appName = "kitty";
  category = [ "terminals" ];
  
  settingsGenerator = _: {
    foreground = uiColors.text-primary.hex;
    background = uiColors.surface-base.hex;
    color0 = ansiColors.black.hex;
    # ...
  };
}
```

### Tier 4: tmux (Raw Config)

**File:** `modules/multiplexers/tmux.nix`

**Key features:**
- Uses `programs.tmux.extraConfig` string
- Manual config generation
- No type safety (careful testing required)

**Excerpt:**
```nix
programs.tmux.extraConfig = ''
  set -g status-style "bg=${colors.surface-base.hex},fg=${colors.text-primary.hex}"
  set -g message-style "bg=${colors.surface-hover.hex}"
'';
```

## Testing Checklist

Use this checklist to ensure comprehensive testing:

### Static Checks
- [ ] `nix fmt` runs without changes
- [ ] `statix check .` passes with no warnings
- [ ] `deadnix .` finds no dead code
- [ ] `nix flake check` completes successfully
- [ ] `nix eval .#homeManagerModules.default` evaluates

### Module Evaluation
- [ ] Module imports correctly in `modules/common/default.nix`
- [ ] No evaluation errors during Home Manager build
- [ ] Options appear in `theming.signal.<category>.<app>`

### Theme Modes
- [ ] Dark mode applies correct colors
- [ ] Light mode applies correct colors
- [ ] Auto mode works (currently resolves to dark)
- [ ] Colors have sufficient contrast in both modes

### Activation Logic
- [ ] Explicit enable works (`<category>.<app>.enable = true`)
- [ ] AutoEnable works when program is enabled
- [ ] Explicit disable prevents theming (`<app>.enable = false`)
- [ ] Respects category-level targeting

### Application Testing
- [ ] Config file generated in correct location
- [ ] Config file contains Signal colors
- [ ] Application launches without errors
- [ ] Colors appear correctly in application UI
- [ ] No warnings in application logs

### Color Verification
- [ ] Background colors are appropriate for mode
- [ ] Text colors have sufficient contrast
- [ ] ANSI colors work correctly (for terminals)
- [ ] Accent colors match Signal palette
- [ ] Borders/dividers are visible but subtle

### Documentation
- [ ] Module has complete metadata block
- [ ] README.md updated
- [ ] Integration standards updated
- [ ] CHANGELOG.md updated
- [ ] Example created (if applicable)

### Edge Cases
- [ ] Module works when program is not installed
- [ ] Module works with program-specific configuration
- [ ] Module doesn't interfere with other Signal modules
- [ ] Module works on Linux (and macOS if applicable)

## Pull Request Checklist

Before submitting your PR, ensure all items are complete:

### Code Quality
- [ ] Code is formatted with `nix fmt`
- [ ] No anti-patterns detected by `statix`
- [ ] No dead code detected by `deadnix`
- [ ] Follows tier system guidelines
- [ ] Uses semantic color mapping
- [ ] Includes complete metadata block

### Testing
- [ ] All static checks pass
- [ ] Tested in dark mode
- [ ] Tested in light mode
- [ ] Tested with autoEnable
- [ ] Tested in actual application
- [ ] Config files generate correctly

### Documentation
- [ ] Module added to `modules/common/default.nix`
- [ ] README.md updated
- [ ] `docs/integration-standards.md` updated
- [ ] CHANGELOG.md updated
- [ ] Example provided (if complex)

### Git Hygiene
- [ ] Clear, descriptive commit message
- [ ] Commit message follows format (feat:/fix:/etc.)
- [ ] Branch name is descriptive
- [ ] No merge conflicts with main
- [ ] Commits are atomic and logical

### Pull Request
- [ ] PR title is clear and follows format
- [ ] PR description is complete
- [ ] All checklist items in PR template completed
- [ ] Screenshots included (for visual applications)
- [ ] Related issues referenced
- [ ] Ready for review

## Common Pitfalls

Avoid these common mistakes when contributing:

### 1. Using Lower Tier Than Necessary

**❌ Wrong:**
```nix
# Using Tier 4 (raw config) when Tier 3 is available
programs.kitty.extraConfig = ''
  foreground #c5cdd8
  background #1a1b26
'';
```

**✅ Correct:**
```nix
# Using Tier 3 (freeform settings) - proper tier
programs.kitty.settings = {
  foreground = colors.text-primary.hex;
  background = colors.surface-base.hex;
};
```

### 2. Hardcoding Color Values

**❌ Wrong:**
```nix
background = "#1a1b26";  # Hardcoded hex
foreground = "#c5cdd8";  # Won't adapt to theme
```

**✅ Correct:**
```nix
background = signalColors.tonal."surface-base".hex;
foreground = signalColors.tonal."text-primary".hex;
```

### 3. Non-Semantic Color Choices

**❌ Wrong:**
```nix
background = signalColors.accent.danger.Lc75.hex;  # Red background?
text = signalColors.tonal."divider-primary".hex;   # Border color for text?
```

**✅ Correct:**
```nix
background = signalColors.tonal."surface-base".hex;  # Semantic surface
text = signalColors.tonal."text-primary".hex;       # Semantic text
```

### 4. Missing Metadata Block

**❌ Wrong:**
```nix
{
  config,
  lib,
  ...
}:
let
  # Missing metadata!
```

**✅ Correct:**
```nix
{
  config,
  lib,
  signalColors,
  signalLib,
  ...
}:
# CONFIGURATION METHOD: freeform-settings (Tier 3)
# HOME-MANAGER MODULE: programs.kitty.settings
# UPSTREAM SCHEMA: https://sw.kovidgoyal.net/kitty/conf/
# SCHEMA VERSION: 0.32.0
# LAST VALIDATED: 2026-01-18
# NOTES: Uses freeform settings for color configuration
```

### 5. Not Using lib.mkDefault (CRITICAL!)

This is the **#1 cause of user configuration conflicts**. All configuration values MUST use `mkDefault` to allow users to override them.

**❌ Wrong:**
```nix
programs.mpv.config = {
  osd-color = colors.text-primary.hex;  # Will conflict with user settings!
  osd-bar-h = 2;
};
```

**✅ Correct:**
```nix
let
  inherit (lib) mkIf mkDefault;  # Import mkDefault
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.mpv.config = {
      osd-color = mkDefault colors.text-primary.hex;  # User can override
      osd-bar-h = mkDefault 2;
    };
  };
}
```

**Why this matters:**

Without `mkDefault`, Signal's values have the same priority as user values, causing conflicts:
```
error: The option `programs.swaylock.settings.indicator-radius' has conflicting definition values:
- In user config: 110
- In signal-nix: 100
Use `lib.mkForce value` or `lib.mkDefault value` to change the priority
```

With `mkDefault`, user values automatically override Signal's defaults - no conflict!

**See:** [docs/mkDefault-guide.md](docs/mkDefault-guide.md) for complete details.
let
```

### 5. Not Testing Both Modes

**❌ Wrong:**
```nix
# Only tested dark mode
# Light mode might have poor contrast!
```

**✅ Correct:**
```bash
# Test both modes
theming.signal.mode = "dark";  # Test this
home-manager switch --flake .

theming.signal.mode = "light"; # And this
home-manager switch --flake .
```

### 6. Ignoring shouldThemeApp Helper

**❌ Wrong:**
```nix
# Manual activation logic (error-prone)
shouldTheme = cfg.terminals.kitty.enable || cfg.autoEnable;
```

**✅ Correct:**
```nix
# Use the helper (handles edge cases)
shouldTheme = signalLib.shouldThemeApp "kitty" [
  "terminals"
  "kitty"
] cfg config;
```

### 7. Not Using mkAppModule Helpers

**❌ Not ideal:**
```nix
# Manual implementation (127 lines)
let
  cfg = config.theming.signal;
  shouldTheme = # ... manual logic
in {
  config = mkIf (cfg.enable && shouldTheme) {
    programs.kitty.settings = {
      # ... 100+ lines of boilerplate
    };
  };
}
```

**✅ Better:**
```nix
# Using helper (98 lines, 23% reduction)
signalLib.mkTier3Module {
  appName = "kitty";
  category = [ "terminals" ];
  settingsGenerator = _: {
    # ... just the color mappings
  };
}
```

### 8. Incomplete Testing

**❌ Wrong:**
```bash
# Only checking evaluation
nix flake check  # ✓

# But not testing in actual app!
```

**✅ Correct:**
```bash
# Full testing workflow
nix flake check                    # ✓ Static checks
home-manager switch --flake .      # ✓ Build and activate
kitty                              # ✓ Launch and verify colors
```

### 9. Poor Commit Messages

**❌ Wrong:**
```bash
git commit -m "added kitty"
git commit -m "fix"
git commit -m "WIP"
```

**✅ Correct:**
```bash
git commit -m "feat: add kitty terminal support

- Implement Tier 3 freeform settings module
- Full ANSI color support (16 colors)
- Support for dark and light modes
- Uses mkTier3Module helper
- Tested with kitty 0.32.0

Closes #123"
```

### 11. Missing Documentation Updates

**❌ Wrong:**
```bash
# Only created the module file
git add modules/terminals/kitty.nix
git commit -m "feat: add kitty"
```

**✅ Correct:**
```bash
# Complete documentation updates
git add modules/terminals/kitty.nix
git add modules/common/default.nix
git add README.md
git add docs/integration-standards.md
git add CHANGELOG.md
git commit -m "feat: add kitty terminal support"
```

## Getting Help

### Before Asking

1. **Check existing documentation:**
   - [Tier System](docs/tier-system.md)
   - [Template README](templates/README.md)
   - [Integration Standards](docs/integration-standards.md)
   - [Architecture](docs/architecture.md)

2. **Review similar modules:**
   - Find an application in the same tier
   - Check how it implements color mapping
   - Look for patterns you can reuse

3. **Search existing issues:**
   - [GitHub Issues](https://github.com/lewisflude/signal-nix/issues)
   - [GitHub Discussions](https://github.com/lewisflude/signal-nix/discussions)
   - Someone may have asked already!

### When You Need Help

**GitHub Discussions** (preferred for questions):
- [Q&A Category](https://github.com/lewisflude/signal-nix/discussions/categories/q-a)
- Best for: "How do I...?" questions
- Best for: Design/architecture questions
- Best for: General help with contribution

**GitHub Issues** (for bugs/features only):
- [New Issue](https://github.com/lewisflude/signal-nix/issues/new/choose)
- Use the application request template
- Provide all requested information

**What to Include:**

```markdown
## What I'm trying to do
[Describe the application you're adding]

## What I've tried
[Show your research and attempts]

## Where I'm stuck
[Specific question or problem]

## Relevant information
- Application: kitty
- Home Manager options checked: programs.kitty.*
- Tier determined: 3 (freeform settings)
- Template used: tier-3-freeform-settings.nix
- Error message: [if applicable]

## Code snippet
[Show relevant parts of your implementation]
```

### Community Resources

- **Matrix Chat**: [Signal channel]
- **Twitter**: [@lewisflude](https://twitter.com/lewisflude)
- **Reddit**: r/NixOS (for general Nix questions)

---

## Summary

Adding a new application to Signal involves:

1. **Research** - Understand the app's theming and Home Manager options
2. **Choose tier** - Determine the highest available configuration tier
3. **Set up** - Copy appropriate template and update metadata
4. **Implement** - Map Signal colors semantically to app schema
5. **Test** - Verify in both light and dark modes, check config generation
6. **Integrate** - Update imports and documentation
7. **Submit** - Create well-documented pull request

**Key Principles:**

- ✅ Always use the **highest available tier**
- ✅ Map colors **semantically** (not arbitrarily)
- ✅ Test in **both light and dark modes**
- ✅ Use **mkAppModule helpers** for cleaner code
- ✅ Include **complete metadata** block
- ✅ Update **all documentation**

**Resources:**

- Templates: `templates/` directory
- Examples: `modules/` directory (look at similar apps)
- Docs: `docs/` directory
- Help: GitHub Discussions

Thank you for contributing to Signal! Your work helps bring beautiful, consistent theming to the Nix ecosystem. 🎨✨
