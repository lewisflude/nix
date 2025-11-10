# Zed Editor Troubleshooting Guide

This guide helps resolve common issues with Zed editor configuration.

## SQLite Foreign Key Constraint Error

### Symptom

```
ERROR [editor::editor] persisting editor selections for editor <id>, workspace <id>
Caused by: Sqlite call failed with code 787 and message: Some("FOREIGN KEY constraint failed")
```

### Cause

Database corruption in Zed's internal SQLite database. This can occur after crashes or improper shutdowns.

### Solution

1. **Close Zed completely** - Ensure all Zed windows and processes are closed
2. **Clear Zed's state directory**:
   - **macOS**: `rm -rf ~/Library/Application\ Support/Zed`
   - **Linux**: `rm -rf ~/.local/share/zed`
   - **Windows**: `rm -rf %APPDATA%\Zed`
3. **Restart Zed** - It will recreate the state directory with fresh database

**Note**: This will reset all Zed settings, workspace state, and editor history. You may need to reconfigure some settings.

## Extension Installation Failures

### Symptom

```
ERROR [extension_host::extension_host] failed to iterate over archive
Caused by: Invalid gzip header
```

or

```
ERROR [extension_host::extension_host] failed to load <extension> extension.toml
Caused by: No such file or directory (os error 2)
```

### Cause

- Network issues during download
- Corrupted extension archive
- Extension removed from registry
- Extension name mismatch

### Solution

1. **Check network connectivity** - Ensure you have internet access
2. **Try manual installation**:
   - Open Zed's extension panel (`cmd-shift-x` / `ctrl-shift-x`)
   - Search for the extension
   - Install manually
3. **Remove problematic extensions** from `auto_install_extensions` in your Nix config
4. **Check extension registry** - Verify the extension still exists at <https://zed.dev/extensions>

### Known Problematic Extensions

- `livelove` - May fail to install due to archive issues
- `yaml` - May fail to install due to archive issues

These have been removed from auto-install in the configuration. Install manually if needed.

## Theme Not Found Error

### Symptom

```
ERROR [theme] theme not found: Signal Dark
```

### Cause

- Theme referenced in settings but not available
- Theme file not written correctly
- Theme generation failed

### Solution

1. **Check theme configuration**:
   - Verify `theming.signal.enable = true` in your config
   - Verify `theming.signal.applications.zed.enable = true`
   - Check that theme files exist in `~/.config/zed/themes/`

2. **Rebuild configuration**:

   ```bash
   home-manager switch
   ```

3. **Check theme files**:
   - macOS/Linux: `ls ~/.config/zed/themes/`
   - Should see `Signal Dark.json` and `Signal Light.json`

4. **If themes are missing**:
   - Check that Signal theme module is properly imported
   - Verify `themeContext` is available to the theme module
   - Check Nix evaluation for errors: `nix eval .#homeConfigurations.<host>.config.programs.zed-editor.themes`

## Language Server Not Found

### Symptom

```
ERROR [project::lsp_store] Failed to start language server "nixd"
The Nix language server (nixd) is not available in your environment (PATH)
```

### Cause

Language server not in PATH when Zed runs.

### Solution

1. **Verify nixd is installed**:

   ```bash
   which nixd
   ```

2. **Check configuration**:
   - Ensure `programs.zed-editor.extraPackages = [ pkgs.nixd ]` is set
   - Rebuild: `home-manager switch`

3. **Verify PATH**:
   - Zed should have access to packages in `extraPackages`
   - Check Zed's environment: Look at process environment in Activity Monitor/Task Manager

4. **Manual PATH fix** (if needed):
   - Add nixd to system PATH
   - Or use `home.packages = [ pkgs.nixd ]` as alternative

## Theme Registry Error

### Symptom

```
ERROR [theme::registry] missing field `themes` at line 407 column 1
```

### Cause

- Malformed theme JSON file
- Theme file missing required fields
- Theme structure doesn't match Zed's schema

### Solution

1. **Check theme file structure**:
   - Open `~/.config/zed/themes/<theme-name>.json`
   - Verify it matches [Zed's theme schema](https://zed.dev/schema/themes/v0.2.0.json)

2. **Validate JSON**:

   ```bash
   cat ~/.config/zed/themes/<theme-name>.json | jq .
   ```

3. **Rebuild themes**:

   ```bash
   home-manager switch
   ```

4. **Check Nix configuration**:
   - Ensure theme generation produces valid JSON
   - Verify all required fields are present

## General Debugging Steps

1. **Check Zed logs**:
   - macOS: `tail -f ~/Library/Application\ Support/Zed/logs/*.log`
   - Linux: `tail -f ~/.local/share/zed/logs/*.log`

2. **Verify Nix configuration**:

   ```bash
   nix eval .#homeConfigurations.<host>.config.programs.zed-editor --json
   ```

3. **Check for evaluation errors**:

   ```bash
   nix-instantiate --eval -E 'import <nixpkgs> {}'
   ```

4. **Rebuild and restart**:

   ```bash
   home-manager switch
   # Then completely restart Zed
   ```

## Getting Help

If issues persist:

1. Check [Zed documentation](https://zed.dev/docs)
2. Review [Zed GitHub issues](https://github.com/zed-industries/zed/issues)
3. Check your Nix configuration for syntax errors
4. Verify all dependencies are available
