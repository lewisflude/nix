# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Breaking Changes

- **`autoEnable` now defaults to `true`**: When you set `theming.signal.enable = true`, Signal will now automatically theme all enabled programs without requiring an additional `autoEnable = true` setting. This makes Signal work "out of the box" with zero configuration.

  **What this means:**
  - Before: `enable = true` did nothing without `autoEnable = true`
  - Now: `enable = true` automatically themes all your programs
  - This is the new recommended default behavior

  **Migration:**
  - Most users: No action needed! This is better default behavior.
  - If you explicitly set `autoEnable = true`: Remove it (now redundant).
  - If you want the old behavior (no auto-theming): Set `autoEnable = false` explicitly.

  **Example - old config:**
  ```nix
  theming.signal = {
    enable = true;
    autoEnable = true;  # ← Was required to theme programs
    mode = "dark";
  };
  ```

  **Example - new config (simpler):**
  ```nix
  theming.signal = {
    enable = true;  # ← Automatically themes programs now!
    mode = "dark";
  };
  ```

  **To opt-out of automatic theming:**
  ```nix
  theming.signal = {
    enable = true;
    autoEnable = false;  # ← Explicitly disable auto-theming
    mode = "dark";

    # Now manually enable each app
    editors.helix.enable = true;
  };
  ```

  See [configuration guide](docs/configuration-guide.md) for details.

### Added

#### Performance Optimizations
- **Vivid Build-Time Caching**: Significantly improved shell startup performance
  - Vivid output is now generated once at build time and cached in `~/.config/vivid/ls-colors-signal`
  - Shell startup reads the cached file instead of executing vivid on every startup
  - **Performance impact**: Saves 20-50ms per shell startup
  - Enabled by default via `theming.signal.cli.vivid.cache = true`
  - Disable caching only if you need runtime theme switching: `cache = false`
  - Applies to all shells: bash, zsh, and fish
  - See [Performance Optimization Guide](docs/performance-optimization.md) for details

#### New Application Support
- **vivid**: LS_COLORS generator with comprehensive file type database
  - Generates LS_COLORS environment variable using RGB hex colors
  - Signal theme dynamically created from color palette
  - 400+ file types supported (far exceeding manual ls-colors implementation)
  - Supports both 24-bit true color and 8-bit terminal modes
  - Automatic shell integration for bash, fish, and zsh
  - Used by ls, tree, fd, eza, bfs, dust, and other file listing tools
  - Preferred replacement for deprecated ls-colors module
  - Example: `examples/vivid-ls-colors.nix`
- **Satty**: Screenshot annotation tool for Wayland
  - TOML configuration with color palette for drawing tools
  - Signal colors mapped to annotation tools (brush, shapes, text, markers)
  - Color palette includes primary (blue), danger (red), warning (yellow), success (green), tertiary (purple), and info (cyan)
  - Configurable general settings (fullscreen, keybinds, font, etc.)
  - Config placed at `~/.config/satty/config.toml`
  - Perfect integration with Wayland screenshot workflows (grim + slurp)
  - Signal now supports 63 applications total

- **Procs**: Modern replacement for `ps` written in Rust
  - TOML configuration with terminal color names (BrightBlue, BrightGreen, etc.)
  - Percentage-based coloring for CPU/memory usage (0-25%, 25-50%, 50-75%, 75-100%, 100%+)
  - Process state coloring (Running=green, Sleeping=blue, Zombie=magenta, etc.)
  - Unit-based coloring for memory sizes (K=blue, M=green, G=yellow, T/P=red)
  - Config placed at `~/.config/procs/config.toml`
  - Signal now supports 63 applications total (including Satty)

- **Zed Editor**: Modern collaborative code editor with complete JSON theme generation
  - Comprehensive syntax highlighting for 40+ language elements
  - Full UI theming (borders, surfaces, scrollbars, status bars)
  - Terminal ANSI color support (16 colors with bright/dim variants)
  - Version control integration colors
  - Collaborative editing cursor colors (8 multiplayer cursors)
  - Theme file placed at `~/.config/zed/themes/signal-{mode}.json`
  - Supports both dark and light modes

#### GTK Theming Enhancement
- **Complete Adwaita Color Palette**: GTK module now defines all 45 Adwaita palette variables (`blue_1` through `dark_5`)
  - Maps Signal accent colors to Adwaita blue, green, yellow, orange, red, and purple palettes
  - Properly themed light and dark grays using Signal tonal colors
  - Fixes GTK applications (like Thunar file manager) that rely on these standard palette colors
  - Ensures consistent theming across all GTK applications, not just modern GTK4 apps

#### Documentation Overhaul
- **New comprehensive guides**:
  - `docs/getting-started.md` - Complete setup guide covering new configs, migration, NixOS, nix-darwin, and non-flake setups
  - `docs/configuration-guide.md` - Full configuration reference with automatic vs manual modes, per-app options, and brand customization
  - `docs/advanced-usage.md` - Power user features including multi-machine configs, brand governance, theme conflicts, and custom color mappings
  - `docs/architecture.md` - Internal architecture documentation with visual diagrams, data flow, and extension patterns
- **Enhanced troubleshooting**:
  - Added diagnostic flowchart at the beginning of troubleshooting guide
  - Quick application checklist for debugging
  - Diagnostic commands for checking configuration state
  - Quick reference table for common issues
- **Restructured main README**:
  - Leading with `autoEnable` as the recommended approach
  - Clear "What is Signal?" section with visual diagrams
  - Simplified Quick Start to 3 clear steps
  - Progressive disclosure: 5-minute → 15-minute → Advanced tiers

#### Example Configurations
- `examples/migrating-existing-config.nix` - Comprehensive guide for adding Signal to existing Home Manager configurations
  - Covers gradual migration approach
  - Multiple migration scenarios (from Catppuccin, stylix, etc.)
  - Reverting instructions
- `examples/multi-machine.nix` - Multi-machine setup patterns
  - Shared config with per-machine overrides
  - Examples for desktop, laptop, work, server, and macOS
  - Automatic machine detection patterns

#### User Experience Improvements
- **Helpful assertions in `modules/common/default.nix`**:
  - Warns if Signal enabled but no applications selected for theming
  - Validates theme mode values with helpful error messages
  - Catches brand governance misconfigurations
  - Provides actionable solutions in error messages
- **Updated `docs/README.md`** with new documentation structure and clear navigation

#### Visual Improvements
- Added ASCII diagrams showing Signal's role in the system
- Flowcharts for troubleshooting and decision-making
- Architecture diagrams for understanding data flow

### Improved
- Documentation now follows progressive disclosure pattern for better onboarding
- Clearer mental model communication: "You enable programs, Signal themes them"
- Better error prevention through assertions and validation

### Deprecated
- **ls-colors module** (`modules/cli/ls-colors.nix`) - Users should migrate to the vivid module
  - The ls-colors module has limited file type coverage (~150 types vs vivid's 400+)
  - Hardcoded 8-bit ANSI color codes instead of RGB hex colors
  - Less maintainable than vivid's YAML-based theme system
  - The ls-colors module will remain available for backward compatibility but won't receive new features
  - Migration: Replace `cli.ls-colors.enable = true;` with `cli.vivid.enable = true;`
  - See `examples/vivid-ls-colors.nix` for migration example

### Fixed
- Theme naming inconsistencies when using `mode = "auto"`. Previously, some modules would try to use non-existent themes like "signal-auto" instead of resolving to "signal-dark" or "signal-light", causing warnings like "Unknown theme 'signal-dark'".
- Added `signalLib.resolveThemeMode` function to standardize theme mode resolution across all modules
- Updated bat, helix, and GTK modules to use resolved theme modes
- Updated color getter in common module to properly resolve "auto" mode before fetching colors

### Added (from previous unreleased)
- Theme resolution validation check in flake checks to prevent future regressions
- Documentation in testing.md about theme validation and common issues
- New library functions: `isValidResolvedMode`, `getThemeName` for consistent theme handling

## [1.0.0] - 2026-01-16

### Added
- Initial stable release of Signal Design System for Nix/Home Manager
- Complete integration with signal-palette v1.0.0
- Supported applications:
  - **Desktop**: Ironbar (3 profiles), GTK3/4, Fuzzel
  - **Editors**: Helix
  - **Terminals**: Ghostty, Zellij
  - **CLI Tools**: bat, fzf, lazygit, yazi
- Brand governance system for managing functional vs decorative colors
- Comprehensive documentation and examples
- Three display profiles for Ironbar (compact/relaxed/spacious)
- MIT license

### Philosophy
- Scientific, OKLCH-based color system
- APCA-compliant accessibility
- Dual-theme support (light/dark)
- Platform-agnostic palette integration

[1.0.0]: https://github.com/lewisflude/signal-nix/releases/tag/v1.0.0
