# Remaining Zed Issues - Analysis

## Current Issues (2025-11-10T15:27:34)

### 1. ? FIXED: nixd Language Server

- **Status**: No longer appears in logs
- **Fix**: `extraPackages = [ pkgs.nixd ]` is working

### 2. ? STILL PRESENT: Extension Installation

**Errors**:

- `installing extension livelove latest version`
- `installing extension yaml latest version`
- `ERROR [extension_host::extension_host] failed to iterate over archive` (Invalid gzip header)
- `ERROR [extension_host::extension_host] failed to load livelove extension.toml`
- `ERROR [extension_host::extension_host] failed to load yaml extension.toml`

**Root Cause**:

- Configuration changes haven't been applied yet (need to rebuild)
- OR cached `settings.json` still contains old extension list
- Home Manager's `mutableUserSettings = true` (default) merges with existing file

**Solution**:

1. Rebuild: `home-manager switch`
2. If still persists, clear stale settings:
   - macOS: `rm ~/Library/Application\ Support/Zed/settings.json`
   - Then rebuild again

### 3. ? STILL PRESENT: Theme Registry Error

**Error**: `ERROR [theme::registry] missing field 'themes' at line 407 column 1`

**Root Cause**:

- Malformed JSON in a theme file or settings.json
- Possibly a stale `themes` field in settings.json (themes should be in separate files)
- OR a theme file is missing required structure

**Solution**:

1. Check for stale `themes` field in settings.json:

   ```bash
   cat ~/Library/Application\ Support/Zed/settings.json | jq '.themes'
   ```

   If this returns something (not null), remove it - themes should be in separate files

2. Check theme files:

   ```bash
   ls -la ~/.config/zed/themes/
   cat ~/.config/zed/themes/*.json | jq . | head -50
   ```

3. Clear and rebuild:

   ```bash
   rm ~/Library/Application\ Support/Zed/settings.json
   home-manager switch
   ```

### 4. ? STILL PRESENT: Signal Dark Theme Not Found

**Error**: `ERROR [theme] theme not found: Signal Dark`

**Root Cause**:

- Themes not being generated (themeContext is null)
- OR themes not being written to disk
- OR theme names don't match

**Solution**:

1. Verify Signal theme is enabled:

   ```bash
   nix eval .#homeConfigurations.<host>.config.theming.signal.enable
   ```

2. Check if themes are generated:

   ```bash
   nix eval .#homeConfigurations.<host>.config.theming.signal.applications.zed.themes
   ```

3. Verify theme files exist after rebuild:

   ```bash
   ls -la ~/.config/zed/themes/Signal*.json
   ```

## Action Items

### Immediate (User Action Required)

1. **Rebuild configuration**:

   ```bash
   home-manager switch
   ```

2. **If issues persist, clear stale settings**:

   ```bash
   # Backup first
   cp ~/Library/Application\ Support/Zed/settings.json ~/Library/Application\ Support/Zed/settings.json.backup

   # Remove stale settings
   rm ~/Library/Application\ Support/Zed/settings.json

   # Rebuild
   home-manager switch
   ```

3. **Restart Zed completely** (close all windows)

### If Theme Issues Persist

1. Check theme generation:

   ```bash
   nix eval .#homeConfigurations.<host>.config.programs.zed-editor.themes
   ```

2. Verify Signal theme module is imported and enabled

3. Check themeContext is available:

   ```bash
   nix eval .#homeConfigurations.<host>.config.theming.signal.applications.zed.enable
   ```

## Expected Behavior After Fix

- ? No extension installation errors (livelove, yaml removed)
- ? No theme registry errors
- ? Signal Dark theme available
- ? nixd language server working (already fixed)
