# Large Files Refactoring Analysis

This document identifies large files (>250 lines) that should be split into smaller, more organized modules for better maintainability and professional structure.

## Analysis Criteria

Files were evaluated based on:

- **Line count** (>250 lines)
- **Multiple concerns** (violates single responsibility)
- **Repetitive patterns** (could use helper functions)
- **Logical grouping** (clear boundaries for splitting)

## Files Recommended for Splitting

### 1. `home/darwin/keyboard/layouts/mnk88.nix` (730 lines)

**Priority: Medium**

**Current Structure:**

- Single large JSON structure with repetitive key definitions

**Recommendation:**
Split into helper functions:

- `home/darwin/keyboard/layouts/mnk88/rows.nix` - Row definitions
- `home/darwin/keyboard/layouts/mnk88/helpers.nix` - Helper functions for key generation
- `home/darwin/keyboard/layouts/mnk88/default.nix` - Main layout composition

**Rationale:**
The file contains highly repetitive key matrix definitions that could be generated programmatically. This would reduce maintenance burden and make it easier to add new layouts.

---

### 2. `modules/shared/features/theming/applications/desktop/ironbar-home/css.nix` (512 lines)

**Priority: High**

**Current Structure:**

- Single file with all CSS generation logic

**Recommendation:**
Split into logical sections:

- `modules/shared/features/theming/applications/desktop/ironbar-home/css/base.nix` - Base CSS
- `modules/shared/features/theming/applications/desktop/ironbar-home/css/theme.nix` - Theme colors
- `modules/shared/features/theming/applications/desktop/ironbar-home/css/widgets.nix` - Widget styling
- `modules/shared/features/theming/applications/desktop/ironbar-home/css/layout.nix` - Layout and spacing
- `modules/shared/features/theming/applications/desktop/ironbar-home/css/default.nix` - Composition

**Rationale:**
The CSS file has clear logical sections (base, theme, widgets, layout) that are already separated in comments. Splitting would improve maintainability and make it easier to modify specific aspects without affecting others.

---

### 3. `modules/nixos/services/containers-supplemental/services/calcom.nix` (462 lines)

**Priority: High**

**Current Structure:**

- Options definition
- Container configuration
- SOPS integration
- Assertions

**Recommendation:**
Split into:

- `modules/nixos/services/containers-supplemental/services/calcom/options.nix` - All option definitions
- `modules/nixos/services/containers-supplemental/services/calcom/containers.nix` - Container definitions (db + app)
- `modules/nixos/services/containers-supplemental/services/calcom/sops.nix` - SOPS secrets and templates
- `modules/nixos/services/containers-supplemental/services/calcom/assertions.nix` - Validation assertions
- `modules/nixos/services/containers-supplemental/services/calcom/default.nix` - Main composition

**Rationale:**
This file handles multiple concerns (options, containers, secrets, validation) that should be separated. The pattern is already established in other services (e.g., `qbittorrent/` directory structure).

---

### 4. `modules/shared/features/theming/applications/desktop/gtk.nix` (423 lines)

**Priority: Medium**

**Current Structure:**

- CSS generation function
- GTK configuration

**Recommendation:**
Split into:

- `modules/shared/features/theming/applications/desktop/gtk/css.nix` - CSS generation (large function)
- `modules/shared/features/theming/applications/desktop/gtk/config.nix` - GTK3/GTK4 configuration
- `modules/shared/features/theming/applications/desktop/gtk/default.nix` - Main composition

**Rationale:**
The CSS generation function is large (300+ lines) and could be split further by component (dialogs, menus, entries, etc.). The GTK configuration is separate and could be its own file.

---

### 5. `home/common/apps/claude-code.nix` (411 lines)

**Priority: Medium**

**Current Structure:**

- Commands definition
- Hooks definition
- Settings configuration
- MCP servers reference

**Recommendation:**
Split into:

- `home/common/apps/claude-code/commands.nix` - All command definitions
- `home/common/apps/claude-code/hooks.nix` - Pre/post hooks
- `home/common/apps/claude-code/settings.nix` - JSON settings configuration
- `home/common/apps/claude-code/default.nix` - Main composition with MCP reference

**Rationale:**
Each section (commands, hooks, settings) is substantial and serves a distinct purpose. Splitting would make it easier to maintain and extend each component independently.

---

### 6. `hosts/jupiter/default.nix` (347 lines)

**Priority: Low**

**Current Structure:**

- Feature flags configuration
- Service-specific settings

**Recommendation:**
Consider splitting into:

- `hosts/jupiter/features.nix` - Feature flags
- `hosts/jupiter/services.nix` - Service-specific configuration (qbittorrent, calcom, etc.)
- `hosts/jupiter/default.nix` - Main composition

**Rationale:**
While the file is reasonably organized, it's getting large. Splitting would make it easier to navigate and maintain. However, this is lower priority as host configs are often meant to be comprehensive in one place.

---

### 7. `modules/shared/features/theming/applications/editors/helix.nix` (320 lines)

**Priority: Low**

**Current Structure:**

- Theme generation function with syntax and UI colors

**Recommendation:**
Split into:

- `modules/shared/features/theming/applications/editors/helix/syntax.nix` - Syntax highlighting colors
- `modules/shared/features/theming/applications/editors/helix/ui.nix` - UI element colors
- `modules/shared/features/theming/applications/editors/helix/default.nix` - Composition

**Rationale:**
The theme has clear sections (syntax vs UI) that could be separated. However, this is lower priority as the file is reasonably organized and not overly complex.

---

### 8. `modules/nixos/features/gaming.nix` (235 lines)

**Priority: Medium**

**Current Structure:**

- Steam configuration
- Gamescope configuration
- Gamemode configuration
- Udev rules
- Firewall rules
- Bluetooth configuration

**Recommendation:**
Split into:

- `modules/nixos/features/gaming/steam.nix` - Steam and Steam-related packages
- `modules/nixos/features/gaming/gamescope.nix` - Gamescope compositor
- `modules/nixos/features/gaming/gamemode.nix` - Gamemode service
- `modules/nixos/features/gaming/hardware.nix` - Udev rules and hardware configuration
- `modules/nixos/features/gaming/network.nix` - Firewall and Bluetooth
- `modules/nixos/features/gaming/default.nix` - Main composition

**Rationale:**
The gaming feature handles multiple distinct concerns (Steam, compositor, performance, hardware, networking). Splitting would align with the pattern already established in other features (e.g., `vr/`, `desktop/audio/`).

---

### 9. `lib/system-builders.nix` (272 lines)

**Priority: Low**

**Current Structure:**

- Darwin system builder
- NixOS system builder
- Shared helpers

**Recommendation:**
Split into:

- `lib/system-builders/darwin.nix` - Darwin-specific builder
- `lib/system-builders/nixos.nix` - NixOS-specific builder
- `lib/system-builders/helpers.nix` - Shared helper functions
- `lib/system-builders/default.nix` - Main exports

**Rationale:**
The file handles two distinct platforms. Splitting would improve clarity, though the current structure is acceptable.

---

## Files That Are Acceptable As-Is

These files are large but have good reasons to remain single files:

- **`tests/evaluation.nix`** (431 lines) - Test files are often comprehensive
- **`tests/theming.nix`** (343 lines) - Test files are often comprehensive
- **`pkgs/pog-scripts/calculate-qbittorrent-config.nix`** (343 lines) - Script logic that benefits from being in one place
- **`home/darwin/karabiner.nix`** (308 lines) - Configuration that benefits from being in one place
- **`modules/shared/features/theming/applications/editors/zed/properties/syntax.nix`** (223 lines) - Theme definition that's logically cohesive

---

## Implementation Priority

1. ### High Priority (Multiple concerns, clear boundaries):
   - `ironbar-home/css.nix`
   - `calcom.nix`

2. ### Medium Priority (Would benefit from splitting):
   - `mnk88.nix` (keyboard layout)
   - `gtk.nix`
   - `claude-code.nix`
   - `gaming.nix`

3. ### Low Priority (Acceptable but could be improved):
   - `jupiter/default.nix`
   - `helix.nix`
   - `system-builders.nix`

---

## Refactoring Guidelines

When splitting files:

1. **Maintain backward compatibility** - Ensure the public API (exports) remains the same
2. **Use clear naming** - File names should indicate their purpose
3. **Follow existing patterns** - Look at similar modules (e.g., `qbittorrent/`, `vr/`, `caddy/`) for structure
4. **Keep related code together** - Don't split too aggressively
5. **Document the structure** - Add comments explaining the organization

---

## Benefits of Splitting

- **Easier navigation** - Find specific configuration faster
- **Better maintainability** - Changes are isolated to relevant files
- **Improved readability** - Smaller files are easier to understand
- **Parallel editing** - Multiple contributors can work on different aspects
- **Clearer responsibilities** - Each file has a single, clear purpose
