# Zed Editor Error Fix Plan

## Overview

This document outlines a comprehensive plan to fix all errors and warnings from Zed editor logs, following Nix and Home Manager best practices.

## Issues Identified

### 1. Theme Registry Error (CRITICAL)

**Error**: `ERROR [theme::registry] missing field 'themes' at line 407 column 1`

**Root Cause**:

- The error occurs when Zed tries to load a theme file that's malformed or missing required fields
- Home Manager's `zed-editor` module expects `themes` as an attribute set where keys are theme names
- The Signal theme module generates themes correctly, but there may be an issue with how they're merged or written

**Solution**:

- Verify theme structure matches Zed's schema (v0.2.0)
- Ensure themes are properly converted to JSON format
- Check that theme files are written to `~/.config/zed/themes/` correctly
- Add validation to ensure themes are only set when properly configured

### 2. Signal Dark Theme Not Found

**Error**: `ERROR [theme] theme not found: Signal Dark`

**Root Cause**:

- Theme is referenced in settings but not available when Zed starts
- May be a timing issue where settings reference theme before it's written
- Or theme generation failed silently

**Solution**:

- Ensure theme generation happens before settings reference it
- Add conditional logic to only set theme in settings if themes are actually available
- Verify theme files are created with correct names

### 3. Extension Installation Failures

**Errors**:

- `ERROR [extension_host::extension_host] failed to iterate over archive` (Invalid gzip header)
- `ERROR [extension_host::extension_host] failed to load livelove extension.toml`
- `ERROR [extension_host::extension_host] failed to load yaml extension.toml`

**Root Cause**:

- Extensions `livelove` and `yaml` are failing to download/install
- Corrupted downloads or network issues
- Extensions may not exist or have been removed from Zed's extension registry

**Solution**:

- Remove problematic extensions from `auto_install_extensions` if they're not essential
- Or handle installation failures gracefully by not auto-installing them
- Verify extension names match those in Zed's extension registry
- Consider using `extensions` option instead of `auto_install_extensions` for better control

### 4. SQLite Foreign Key Constraint

**Error**: `ERROR [editor::editor] persisting editor selections` - `FOREIGN KEY constraint failed`

**Root Cause**:

- Database corruption in Zed's internal SQLite database
- This is a runtime issue, not a configuration issue

**Solution**:

- Document the fix: Clear Zed's state directory
- Add a note in configuration about how to reset Zed if this occurs
- This is a user action, not something we can fix in Nix config

### 5. nixd Language Server Not in PATH

**Error**: `ERROR [project::lsp_store] Failed to start language server "nixd"` - not available in PATH

**Root Cause**:

- `nixd` is in `lib/package-sets.nix` but may not be in user's PATH when Zed runs
- Zed needs access to language servers in its PATH

**Solution**:

- Add `nixd` to `programs.zed-editor.extraPackages` to ensure it's in Zed's PATH
- Or ensure `nixd` is in `home.packages` and available system-wide
- Verify `nixd` is actually installed and available

## Implementation Plan

### Step 1: Fix Theme Configuration

**File**: `home/common/apps/zed-editor.nix`

**Changes**:

1. Ensure themes are only set when they're actually available
2. Add validation to prevent empty or malformed theme sets
3. Ensure theme names match exactly (case-sensitive)

**File**: `modules/shared/features/theming/applications/editors/zed.nix`

**Changes**:

1. Verify theme structure matches Zed's schema
2. Ensure all required fields are present
3. Add null checks for themeContext

### Step 2: Fix Extension Configuration

**File**: `home/common/apps/zed-editor.nix`

**Changes**:

1. Remove `livelove` and `yaml` from `auto_install_extensions` if they're problematic
2. Or move them to manual installation
3. Consider using `extensions` option for better control

### Step 3: Fix nixd PATH Issue

**File**: `home/common/apps/zed-editor.nix`

**Changes**:

1. Add `nixd` to `programs.zed-editor.extraPackages`
2. This ensures nixd is in Zed's PATH via the wrapper

### Step 4: Add Documentation

**File**: Create or update documentation

**Content**:

- How to reset Zed if SQLite errors occur
- How to manually install extensions if auto-install fails
- Theme troubleshooting guide

## Best Practices Applied

1. **Use `extraPackages` for language servers**: Ensures tools are in Zed's PATH via wrapper
2. **Conditional theme configuration**: Only set themes when they're actually available
3. **Graceful extension handling**: Don't fail if extensions can't be installed
4. **Proper Nix attribute merging**: Use `lib.mkMerge` and `lib.mkIf` correctly
5. **Validation**: Add checks to prevent configuration errors

## Testing

After implementing fixes:

1. Rebuild home-manager configuration
2. Restart Zed
3. Check logs for remaining errors
4. Verify themes are available and working
5. Verify nixd is accessible
6. Test extension functionality

## Notes

- SQLite errors require manual intervention (clearing Zed state)
- Extension installation failures may be transient (network issues)
- Theme errors are configuration issues that can be fixed in Nix
