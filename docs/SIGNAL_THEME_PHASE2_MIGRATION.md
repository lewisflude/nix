# Signal Theme Phase 2 Migration Guide

This document describes the changes made in Phase 2 of the Signal theme architecture refactoring and how to migrate if needed.

## Overview

Phase 2 reorganizes application modules by type (editors, terminals, desktop, cli) rather than by platform (nixos/home). This improves maintainability and makes it easier to find and manage application themes.

## What Changed

### 1. Application Organization

Applications are now organized in `modules/shared/features/theming/applications/` by category:

- **Editors**: `editors/` (cursor, helix, zed)
- **Terminals**: `terminals/` (ghostty, zellij)
- **Desktop**: `desktop/` (gtk, mako, swaync, fuzzel, ironbar, swappy)
- **CLI Tools**: `cli/` (bat, fzf, lazygit, yazi)

### 2. Application Registry

A new registry system (`registry.nix`) provides metadata about all applications:

- Platform (nixos/home/both)
- Category
- Dependencies
- Description

### 3. Standard Interface

All application modules now follow a standard interface pattern:

- Accept `themeContext` (preferred) or `signalPalette` (backward compatible)
- Use semantic tokens via `theme.colors` or `theme.semantic`
- Support both NixOS and Home Manager contexts

### 4. Updated Imports

Platform modules now import from shared locations:

- NixOS: `modules/shared/features/theming/applications/desktop/*.nix`
- Home Manager: `modules/shared/features/theming/applications/{editors,terminals,desktop,cli}/*.nix`

## Migration Steps

### For Users

**No action required!** The changes are backward compatible. Your existing configuration will continue to work.

### For Developers

If you're creating new application modules or modifying existing ones:

1. **Use the new shared locations**: Place modules in the appropriate category directory
2. **Follow the standard interface**: Accept `themeContext` and use `theme.colors`
3. **Register in registry.nix**: Add your application to the registry with metadata

### Example: Creating a New Application Module

```nix
# modules/shared/features/theming/applications/editors/myeditor.nix
{
  config,
  lib,
  pkgs,
  themeContext ? null,
  signalPalette ? null,  # Backward compatibility
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  # Use themeContext if available, otherwise fall back to signalPalette
  theme = themeContext.theme or signalPalette;
  colors = theme.colors or theme.semantic;
in
{
  config = mkIf (cfg.enable && cfg.applications.myeditor.enable && theme != null) {
    # Your theme configuration here
    programs.myeditor = {
      theme = {
        background = colors."surface-base".hex;
        foreground = colors."text-primary".hex;
      };
    };
  };
}
```

Then:

1. Add to registry in `registry.nix`
2. Add option to platform module (`options.theming.signal.applications.myeditor`)
3. Import in platform module's `imports` list

## File Locations

### Old Locations (Still Work, But Deprecated)

- `modules/nixos/features/theming/applications/*.nix`
- `home/common/theming/applications/*.nix`

### New Locations (Preferred)

- `modules/shared/features/theming/applications/editors/*.nix`
- `modules/shared/features/theming/applications/terminals/*.nix`
- `modules/shared/features/theming/applications/desktop/*.nix`
- `modules/shared/features/theming/applications/cli/*.nix`

## Benefits

1. **Better Organization**: Find applications by type, not platform
2. **Easier Maintenance**: Shared modules reduce duplication
3. **Consistent Interface**: All applications follow the same pattern
4. **Discoverability**: Registry makes it easy to see all available applications
5. **Future-Proof**: Foundation for dynamic application loading

## Backward Compatibility

- Old `signalPalette` parameter still works (with deprecation)
- Old file locations still work (imports updated)
- Existing configurations continue to function
- No breaking changes for end users

## Next Steps

Phase 3 will add:

- Validation layer (contrast checking, accessibility)
- Testing infrastructure
- Enhanced theme factory patterns

Phase 4 will add:

- Theme variants (high contrast, etc.)
- Advanced brand governance
- Documentation generation

Phase 5 will:

- Remove deprecated patterns
- Final cleanup and polish
