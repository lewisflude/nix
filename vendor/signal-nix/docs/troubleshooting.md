# Troubleshooting Guide

This guide covers common issues and solutions when using Signal with NixOS and Home Manager.

## Quick Diagnostic Flowchart

```
Is Signal enabled?
├─ No → Set theming.signal.enable = true
└─ Yes ↓

Are programs enabled?
├─ No → Set programs.<app>.enable = true
└─ Yes ↓

Is autoEnable true (default) OR app explicitly enabled?
├─ No → Remove autoEnable = false or set <category>.<app>.enable = true
└─ Yes ↓

Did you rebuild?
├─ No → Run: home-manager switch
└─ Yes ↓

Does Signal support this program?
├─ No → Check Supported Applications list
└─ Yes ↓

Is config file generated?
├─ No → Check evaluation errors (see below)
└─ Yes ↓

Did you restart the application?
├─ No → Restart application or reload config
└─ Yes ↓

Still not working?
└─ See detailed troubleshooting sections below
```

## Common Issues at a Glance

| Issue | Quick Fix |
|-------|-----------|
| Program not themed | Enable both program AND Signal theming |
| Colors not showing | Restart application, check true color support |
| Flake not found | Enable flakes: `nix.settings.experimental-features = ["flakes"]` |
| Evaluation error | Run with `--show-trace` to see exact error |
| Config not updated | Run `home-manager switch` |
| Ironbar not changing | Run `ironbar reload` or restart service |

## Table of Contents

- [Installation Issues](#installation-issues)
- [Flake Issues](#flake-issues)
- [Module Evaluation Errors](#module-evaluation-errors)
- [Application-Specific Issues](#application-specific-issues)
- [Color Display Issues](#color-display-issues)
- [Performance Issues](#performance-issues)
- [Getting Help](#getting-help)

## Installation Issues

### Error: "flake 'github:lewisflude/signal-nix' not found"

**Cause**: Flakes are not enabled in your Nix configuration.

**Solution**: Enable flakes in your configuration:

```nix
# /etc/nixos/configuration.nix (NixOS)
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

Or enable flakes temporarily:

```bash
nix --experimental-features 'nix-command flakes' flake show github:lewisflude/signal-nix
```

### Error: "signal-palette" dependency fails to fetch

**Cause**: Network issues or outdated flake lock.

**Solution**: Update your flake lock:

```bash
cd /path/to/your/config
nix flake update signal
nix flake lock --update-input signal-palette
```

If network issues persist, check your internet connection or proxy settings.

### Home Manager module not found

**Cause**: Module not properly imported or input not added.

**Solution**: Verify your flake setup:

```nix
{
  inputs = {
    signal.url = "github:lewisflude/signal-nix";
    # Ensure other inputs are present too
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { self, nixpkgs, home-manager, signal, ... }: {
    homeConfigurations.yourname = home-manager.lib.homeManagerConfiguration {
      # ...
      modules = [
        signal.homeManagerModules.default
        # Your other modules
      ];
    };
  };
}
```

## Flake Issues

### Error: "infinite recursion encountered"

**Cause**: Circular dependency in module imports or option definitions.

**Solution**: Check your configuration for circular references:

```nix
# Bad: Creates circular dependency
theming.signal.customColors = config.theming.signal.colors;

# Good: Use direct values
theming.signal.customColors = {
  primary = "#ff0000";
};
```

If you didn't create any custom logic, this might be a bug - please report it!

### Error: "attribute 'signal' missing"

**Cause**: Module not imported or typo in configuration.

**Solution**:

1. Verify the module is imported:
   ```nix
   imports = [signal.homeManagerModules.default];
   ```

2. Check for typos:
   ```nix
   # Correct
   theming.signal.enable = true;

   # Wrong
   theme.signal.enable = true;  # Wrong namespace
   theming.signals.enable = true;  # Typo
   ```

### Flake check fails with "derivation does not produce output"

**Cause**: Module evaluation error or incorrect check setup.

**Solution**: Run flake check with verbose output:

```bash
nix flake check --show-trace
```

This will show exactly where the error occurs. Common causes:
- Missing required options
- Type mismatches
- Invalid color values

## Module Evaluation Errors

### Error: "value is a set while a string was expected"

**Cause**: Option type mismatch, usually from passing a color object instead of a string.

**Solution**: Check your configuration:

```nix
# Wrong: Passing entire color object
theming.signal.customColor = config.theming.signal.colors;

# Correct: Pass specific color string
theming.signal.customColor = config.theming.signal.colors.text.primary;
```

### Error: "The option 'theming.signal.xyz' does not exist"

**Cause**: Typo or option not available in your Signal version.

**Solution**:

1. Check for typos in option names
2. Verify available options:
   ```bash
   nix eval .#homeManagerModules.default --apply 'x: builtins.attrNames x.options.theming.signal'
   ```

3. Check if you're using the latest version:
   ```bash
   nix flake update signal
   ```

### Error: "assertion failed"

**Cause**: Invalid configuration combination or constraint violation.

**Solution**: Read the assertion message carefully. Common assertions:

```nix
# Example: Brand governance policy requires decorative colors
theming.signal.brandGovernance = {
  policy = "integrated";
  # This will fail if decorativeBrandColors is not set
  decorativeBrandColors = {
    brand-primary = "#5a7dcf";  # Required
  };
};
```

## Application-Specific Issues

### Quick Application Checklist

Before diving into specific issues, verify these basics:

```
✓ Program enabled: programs.<app>.enable = true
✓ Signal enabled: theming.signal.enable = true
✓ Theming enabled: autoEnable = true (default)
  OR theming.signal.<category>.<app>.enable = true
✓ System rebuilt: home-manager switch completed
✓ Application restarted: Closed and reopened
```

### Diagnostic Commands

```bash
# Check if Signal thinks it should theme the app
nix eval .#homeConfigurations.user.config.theming.signal.<category>.<app>.enable

# Check if program is enabled
nix eval .#homeConfigurations.user.config.programs.<app>.enable

# Check generated config location
ls -la ~/.config/<app>/

# View Home Manager generation
home-manager generations | head -n 1
```

### Ironbar not reflecting Signal colors

**Cause**: Ironbar config not reloaded or service not restarted.

**Solution**:

1. Reload Ironbar:
   ```bash
   ironbar reload
   ```

2. Or restart the service:
   ```bash
   systemctl --user restart ironbar
   ```

3. Check Ironbar logs:
   ```bash
   journalctl --user -u ironbar -f
   ```

### GTK theme not applying

**Cause**: GTK theme not activated or gsettings not updated.

**Solution**:

1. Verify GTK configuration is enabled:
   ```nix
   theming.signal.gtk.enable = true;
   ```

2. Check GTK settings:
   ```bash
   gsettings get org.gnome.desktop.interface gtk-theme
   gsettings get org.gnome.desktop.interface color-scheme
   ```

3. Try logging out and back in (GTK themes sometimes need session restart)

4. For GTK 4 apps, verify the config location:
   ```bash
   ls -la ~/.config/gtk-4.0/gtk.css
   ```

5. **For GTK applications like Thunar**: Signal now includes the complete Adwaita color palette (45 palette variables). If you're experiencing issues with older GTK apps not picking up colors:
   - Ensure you're using the latest version of signal-nix
   - Restart the application completely (kill all processes)
   - Check that `~/.config/gtk-3.0/gtk.css` includes `@define-color blue_1`, `green_2`, etc.

### Helix colors not showing

**Cause**: Helix config not updated or terminal doesn't support true color.

**Solution**:

1. Verify Helix module is enabled:
   ```nix
   theming.signal.editors.helix.enable = true;
   ```

2. Check terminal true color support:
   ```bash
   echo $COLORTERM  # Should output "truecolor" or "24bit"
   ```

3. Test Helix theme:
   ```bash
   helix --health
   ```

4. Manually check theme file:
   ```bash
   cat ~/.config/helix/themes/signal-dark.toml
   ```

### Ghostty theme not loading

**Cause**: Config file not generated or Ghostty not restarted.

**Solution**:

1. Check config file exists:
   ```bash
   cat ~/.config/ghostty/config
   ```

2. Restart Ghostty completely (not just new window)

3. Verify Signal theme is referenced in config

### CLI tools (bat, fzf) colors wrong

**Cause**: Environment variables not set or shell not reloaded.

**Solution**:

1. Reload your shell:
   ```bash
   exec $SHELL
   ```

2. Check environment variables:
   ```bash
   echo $BAT_THEME
   echo $FZF_DEFAULT_OPTS
   ```

3. For bat, verify theme:
   ```bash
   bat --list-themes | grep -i signal
   ```

4. Try manual config:
   ```bash
   bat --theme="Signal Dark" yourfile
   ```

## Color Display Issues

### Colors look wrong or washed out

**Cause**: Terminal or display doesn't support true color (24-bit).

**Solution**:

1. Check terminal true color support:
   ```bash
   # Should show smooth gradient
   curl -s https://raw.githubusercontent.com/JohnMorales/dotfiles/master/colors/24-bit-color.sh | bash
   ```

2. Enable true color in terminal:
   ```nix
   # For Ghostty
   programs.ghostty.settings.term = "xterm-256color";
   ```

3. Check TERM environment variable:
   ```bash
   echo $TERM  # Should be xterm-256color or better
   ```

### Light mode looks wrong

**Cause**: Light mode is less tested and may have contrast issues.

**Solution**:

1. Report specific issues on GitHub with screenshots
2. Try dark mode temporarily
3. Adjust specific colors:
   ```nix
   theming.signal = {
     mode = "light";
     # Override specific problematic colors
     colorOverrides = {
       surface.primary = "#ffffff";
     };
   };
   ```

### Colors don't match between applications

**Cause**: Some apps use cached colors or have independent theme systems.

**Solution**:

1. Rebuild completely:
   ```bash
   home-manager switch --flake .# --recreate-lock-file
   ```

2. Clear application caches:
   ```bash
   rm -rf ~/.cache/gtk-*
   rm -rf ~/.cache/helix
   ```

3. Restart affected applications

### OKLCH colors display differently than expected

**Cause**: Display not calibrated or color management issues.

**Solution**:

OKLCH is perceptually uniform, but:
- Display calibration affects color appearance
- Color management must be enabled in compositor
- sRGB displays have limited gamut

For accurate colors:
1. Enable color management in your compositor (Wayland)
2. Calibrate your display if possible
3. Use wide-gamut display for best results

## Performance Issues

### Slow rebuild times

**Cause**: Module evaluation overhead or network fetching.

**Solution**:

1. Use binary caches:
   ```nix
   nix.settings = {
     substituters = ["https://cache.nixos.org/"];
     trusted-public-keys = ["cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="];
   };
   ```

2. Pin Signal version to avoid refetching:
   ```nix
   inputs.signal.url = "github:lewisflude/signal-nix/v1.0.0";  # Pin to version
   ```

3. Use `nix flake archive` to pre-fetch dependencies

### High memory usage during build

**Cause**: Large number of string concatenations in module evaluation.

**Solution**:

1. Enable evaluation caching:
   ```nix
   nix.settings.eval-cache = true;
   ```

2. Disable unused applications:
   ```nix
   theming.signal = {
     enable = true;
     # Only enable what you actually use
     ironbar.enable = true;
     # Leave others disabled
   };
   ```

3. If memory issues persist, report as bug

## Common Configuration Mistakes

### Mistake: Enabling Signal but no applications

```nix
# This does nothing visible!
theming.signal.enable = true;
```

**Fix**: Enable at least one application:
```nix
theming.signal = {
  enable = true;
  gtk.enable = true;  # Enable something
};
```

### Mistake: Wrong color format

```nix
# Wrong: OKLCH values
theming.signal.customColor = "oklch(0.5 0.1 240)";

# Correct: Hex colors
theming.signal.customColor = "#5a7dcf";
```

Signal handles OKLCH internally; users provide hex colors.

### Mistake: Modifying palette directly

```nix
# Wrong: Don't modify palette input
signal-palette.palette.dark.text.primary = "#ffffff";

# Correct: Use color overrides
theming.signal.colorOverrides = {
  text.primary = "#ffffff";
};
```

### Mistake: Not specifying mode

```nix
# This defaults to dark mode
theming.signal.enable = true;
```

**Best practice**: Always specify mode explicitly:
```nix
theming.signal = {
  enable = true;
  mode = "dark";  # or "light"
};
```

## Debugging Tips

### Enable verbose logging

For Home Manager:
```bash
home-manager switch --flake .# -vvv
```

For NixOS:
```bash
nixos-rebuild switch --show-trace
```

### Check generated configuration

For Ironbar:
```bash
cat ~/.config/ironbar/config.json
cat ~/.config/ironbar/style.css
```

For Helix:
```bash
cat ~/.config/helix/themes/signal-dark.toml
```

For GTK:
```bash
cat ~/.config/gtk-4.0/gtk.css
cat ~/.config/gtk-3.0/gtk.css
```

### Test module in isolation

Create a test configuration:

```nix
# test.nix
{
  imports = [signal.homeManagerModules.default];

  theming.signal = {
    enable = true;
    mode = "dark";
    gtk.enable = true;
  };
}
```

Evaluate:
```bash
nix eval --file test.nix config.gtk.gtk3.extraCss
```

### Compare palette versions

Check which palette version you're using:
```bash
nix flake metadata signal-palette
```

List available versions:
```bash
nix flake show github:lewisflude/signal-palette
```

## Getting Help

### Before asking for help

1. Check this troubleshooting guide
2. Search existing [GitHub Issues](https://github.com/lewisflude/signal-nix/issues)
3. Read the [documentation](https://github.com/lewisflude/signal-nix#documentation)
4. Try with a minimal configuration

### When reporting issues

Include:

1. **System information:**
   ```bash
   nixos-version  # or sw_vers on macOS
   nix --version
   home-manager --version
   ```

2. **Signal versions:**
   ```bash
   nix flake metadata signal
   nix flake metadata signal-palette
   ```

3. **Minimal configuration** that reproduces the issue

4. **Error messages** (full output with `--show-trace`)

5. **Screenshots** if visual issue

### Where to get help

- **GitHub Issues**: [Report bugs](https://github.com/lewisflude/signal-nix/issues/new/choose)
- **Discussions**: [Ask questions](https://github.com/lewisflude/signal-nix/discussions)
- **NixOS Discourse**: [Community help](https://discourse.nixos.org/)
- **Twitter/X**: [@lewisflude](https://twitter.com/lewisflude)

## Known Issues

### OKLCH in terminal emulators

**Issue**: Most terminals use sRGB color space, not OKLCH.

**Impact**: Colors are converted to hex/RGB for terminal output. Perceptual uniformity is preserved in the palette design, but terminals can't render native OKLCH.

**Workaround**: None needed - conversion is automatic and correct.

### GTK 3 vs GTK 4 theming differences

**Issue**: GTK 3 and GTK 4 use different CSS formats.

**Impact**: Minor visual differences between GTK 3 and GTK 4 apps.

**Solution**: Enable both versions:
```nix
theming.signal.gtk.version = "both";
```

### macOS color management

**Issue**: macOS color management may affect color appearance.

**Impact**: Colors may look slightly different than on Linux.

**Workaround**: Disable color management in specific apps or adjust display settings.

## Still Stuck?

If you've tried everything here and still have issues:

1. Create a [minimal reproducible example](https://stackoverflow.com/help/minimal-reproducible-example)
2. Open a [GitHub Issue](https://github.com/lewisflude/signal-nix/issues/new/choose)
3. Include all information from the "When reporting issues" section

We'll help you troubleshoot! 🎨✨
