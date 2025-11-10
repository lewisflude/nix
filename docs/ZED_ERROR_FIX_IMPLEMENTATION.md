# Zed Editor Error Fix - Implementation Guide

## Summary

This document provides step-by-step implementation instructions to fix all Zed editor errors following Nix and Home Manager best practices.

## Issues and Solutions

### Issue 1: Theme Registry Error - "missing field `themes` at line 407"

**Problem**: Zed is trying to read a malformed theme file or theme is referenced before it's available.

**Root Cause**:

- Themes are conditionally set, but settings may reference them even when empty
- Theme generation might fail silently if `themeContext` is null

**Solution**:

1. Only set theme in settings when themes are actually available
2. Ensure themes are non-empty before referencing them
3. Add validation to prevent empty theme sets

### Issue 2: Signal Dark Theme Not Found

**Problem**: Theme is referenced in settings but not available.

**Solution**:

- Only reference theme in settings when it exists in the themes attribute set
- Check that `signalThemes` contains both "Signal Dark" and "Signal Light" before setting theme

### Issue 3: Extension Installation Failures (livelove, yaml)

**Problem**: Extensions fail to install with "Invalid gzip header" and "No such file or directory" errors.

**Solution**:

- Remove problematic extensions from auto-install list
- Or handle gracefully by not failing if installation fails
- Consider using `extensions` option instead for better control

### Issue 4: SQLite Foreign Key Constraint

**Problem**: Database corruption in Zed's internal state.

**Solution**:

- Document user action required (clear Zed state)
- This cannot be fixed in Nix configuration

### Issue 5: nixd Not in PATH

**Problem**: nixd language server not available to Zed.

**Solution**:

- Add `nixd` to `programs.zed-editor.extraPackages`
- This ensures it's in Zed's PATH via the wrapper

## Implementation Steps

### Step 1: Fix Theme Configuration

**File**: `home/common/apps/zed-editor.nix`

**Changes**:

```nix
{ config, lib, pkgs, ... }:
let
  languageConfig = import ./zed-editor-languages.nix { inherit lib; };
  lspConfig = import ./zed-editor-lsp.nix { inherit lib; };

  # Check if Signal theme is enabled
  signalThemeEnabled = config.theming.signal.enable or false;

  # Get Signal themes if available
  signalThemes = config.theming.signal.applications.zed.themes or {};

  # Check if themes are actually available (non-empty and contain required themes)
  themesAvailable = signalThemeEnabled
    && signalThemes != {}
    && signalThemes ? "Signal Dark"
    && signalThemes ? "Signal Light";

  # Get the raw theme mode (before resolution) to determine Zed's theme mode setting
  rawThemeMode = if signalThemeEnabled then (config.theming.signal.mode or "dark") else null;

  # Determine Zed's theme mode:
  # - "auto" -> "system" (let Zed follow system preference)
  # - "light" or "dark" -> use that mode directly
  zedThemeMode = if rawThemeMode == "auto" then "system" else rawThemeMode;
in
{
  programs.zed-editor = {
    enable = true;

    # Add nixd to extraPackages so it's in PATH
    extraPackages = [ pkgs.nixd ];

    userSettings = lib.mkMerge [
      {
        # ... existing settings ...

        # Remove problematic extensions from auto-install
        auto_install_extensions = {
          biome = true;
          docker-compose = true;
          dockerfile = true;
          env = true;
          git-firefly = true;
          github-actions = true;
          html = true;
          json5 = true;
          just = true;
          # livelove = true;  # Removed: fails to install
          markdown-oxide = true;
          nix = true;
          sql = true;
          ssh-config = true;
          terraform = true;
          toml = true;
          # yaml = true;  # Removed: fails to install
        };

        inherit (languageConfig) languages;
      }
      # Set theme ONLY when themes are actually available
      (lib.mkIf themesAvailable {
        theme = {
          mode = zedThemeMode;
          light = "Signal Light";
          dark = "Signal Dark";
        };
      })
    ];

    # Only set themes when they're available
    themes = lib.mkMerge [
      (lib.mkIf themesAvailable signalThemes)
    ];
  };
}
```

**Key Changes**:

1. Added `themesAvailable` check to ensure themes exist before referencing
2. Added `extraPackages = [ pkgs.nixd ]` to ensure nixd is in PATH
3. Removed `livelove` and `yaml` from auto-install extensions
4. Only set theme in settings when `themesAvailable` is true
5. Only set themes when `themesAvailable` is true

### Step 2: Verify Theme Module

**File**: `modules/shared/features/theming/applications/editors/zed.nix`

**No changes needed** - The module already handles null `themeContext` correctly by returning empty set.

However, we should verify the theme structure matches Zed's schema. The current structure looks correct.

### Step 3: Add Documentation for SQLite Error

**File**: Create `docs/ZED_TROUBLESHOOTING.md`

**Content**:

```markdown
# Zed Editor Troubleshooting

## SQLite Foreign Key Constraint Error

If you see errors like:
```

ERROR [editor::editor] persisting editor selections - FOREIGN KEY constraint failed

```

This indicates database corruption in Zed's internal state.

**Solution**:
1. Close Zed completely
2. Clear Zed's state directory:
   - macOS: `rm -rf ~/Library/Application\ Support/Zed`
   - Linux: `rm -rf ~/.local/share/zed`
3. Restart Zed (it will recreate the state)

**Note**: This will reset all Zed settings, so you may need to reconfigure.

## Extension Installation Failures

If extensions fail to install:
1. Check network connectivity
2. Try manually installing via Zed's extension panel
3. Some extensions may have been removed from the registry
4. Check Zed logs for specific error messages
```

## Testing Checklist

After implementing changes:

- [ ] Rebuild home-manager: `home-manager switch`
- [ ] Restart Zed completely
- [ ] Check Zed logs for errors: `tail -f ~/Library/Application\ Support/Zed/logs/*.log` (macOS)
- [ ] Verify themes are available: Open theme selector (`cmd-k cmd-t`)
- [ ] Verify nixd is accessible: Open a `.nix` file and check LSP status
- [ ] Test extension functionality
- [ ] Verify no theme registry errors in logs

## Rollback Plan

If issues occur:

1. Revert changes to `home/common/apps/zed-editor.nix`
2. Rebuild: `home-manager switch`
3. Clear Zed state if needed (see troubleshooting guide)

## Additional Notes

- The `extraPackages` option wraps Zed with a script that adds packages to PATH
- This is the recommended way to ensure language servers are available to Zed
- Extension installation failures are often transient (network issues)
- Theme errors are configuration issues that can be fixed in Nix
