# nh Progress Display Guide

## Why Progress Isn't Showing

### The Problem

When you run `nh os switch`, you're not seeing progress output because:

1. **`nom` (nix-output-monitor) is not installed** - `nh` uses `nom` to show nice progress bars
2. **Nix falls back to basic output** - Without `nom`, you only see basic Nix output
3. **Output may be suppressed** - Some terminals or configurations suppress output

### Solution: Install nix-output-monitor

I've added `nix-output-monitor` to your packages. After your next rebuild:

```bash
nh home switch
# or
nh os switch
```

Then `nh` will automatically use `nom` to show progress like:

```
[1/5] Building NixOS configuration...
[2/5] Downloading packages...
[3/5] Building packages...
[4/5] Activating new generation...
[5/5] Done!
```

## Alternative Progress Options

### Option 1: Use `--no-nom` Flag (If nom causes issues)

If `nom` causes problems (cursor issues, slow builds), you can disable it:

```bash
# Disable nom via environment variable
export NH_NOM=0
nh os switch

# Or disable permanently in home/common/nh.nix:
home.sessionVariables = {
  NH_NOM = "0";  # Disable nom
};
```

### Option 2: Use Nix's Built-in Progress

Without `nom`, you can still get progress using Nix's built-in options:

```bash
# Verbose output with progress
nh os switch -- --option log-lines 50

# Or set in nix.conf
```

### Option 3: Manual Progress with Separate Commands

See what's happening at each step:

```bash
# 1. See what will be built
nix build .#nixosConfigurations.jupiter.config.system.build.toplevel --dry-run

# 2. Build with verbose output
nix build .#nixosConfigurations.jupiter.config.system.build.toplevel --print-build-logs

# 3. Activate manually
sudo nixos-rebuild switch --flake ~/.config/nix#jupiter
```

### Option 4: Use `nix build` Directly

For more control:

```bash
# Build with progress bars (requires nom or nix-output-monitor)
nix build .#nixosConfigurations.jupiter.config.system.build.toplevel

# Then activate
sudo nixos-rebuild switch --flake ~/.config/nix#jupiter
```

## Verifying Installation

After rebuilding, verify `nom` is available:

```bash
which nom
# Should show: /nix/store/.../bin/nom or ~/.nix-profile/bin/nom

nom --version
# Should show version info
```

## Troubleshooting

### If `nom` Still Doesn't Show Progress

1. **Check if nom is in PATH**:

   ```bash
   which nom
   ```

2. **Check if nh detects nom**:

   ```bash
   nh os switch --verbose
   # Look for "Using nix-output-monitor" message
   ```

3. **Check NH_NOM environment variable**:

   ```bash
   echo $NH_NOM
   # Should be empty or unset (not "0")
   ```

4. **Try running nom directly**:

   ```bash
   nom nix build .#nixosConfigurations.jupiter.config.system.build.toplevel
   ```

### If Progress Shows But Is Slow

`nom` adds ~5-15 seconds overhead. If builds are slow:

```bash
# Disable nom for faster builds
NH_NOM=0 nh os switch
```

### If Terminal Doesn't Support Progress

Some terminals or configurations don't show progress bars properly. Try:

```bash
# Use plain text output
NH_NOM=0 nh os switch
```

## Configuration

### Enable/Disable nom Permanently

Edit `home/common/nh.nix`:

```nix
home.sessionVariables = {
  # Disable nom (set to "0")
  # NH_NOM = "0";

  # Or leave unset/commented to use nom (default)
};
```

### Custom nom Configuration

Create `~/.config/nom/config.toml`:

```toml
[display]
# Show progress bars
progress = true

# Update frequency
refresh_rate = 10  # milliseconds

# Colors
colors = true
```

## Expected Output

### With `nom` (Good Progress)

```
> Building NixOS configuration
[████████████████████] 100% (5/5)
[1/5] Evaluating configuration...
[2/5] Downloading packages (12/34)...
[3/5] Building packages (8/12)...
[4/5] Activating new generation...
[5/5] Done!
⏱ 1m44s
```

### Without `nom` (Basic Output)

```
> Building NixOS configuration
building '/nix/store/...'
downloading 'https://...'
building '/nix/store/...'
⏱ 1m44s
```

## Summary

**Problem**: `nom` (nix-output-monitor) wasn't installed, so `nh` couldn't show progress.

**Solution**: Added `nix-output-monitor` to your packages. After rebuilding, you'll see nice progress bars.

**Next Steps**:

1. Run `nh home switch` to get `nom` installed
2. Run `nh os switch` again - you should see progress
3. If you don't want progress (for speed), set `NH_NOM=0`

**Note**: `nom` adds ~5-15 seconds overhead but provides much better feedback. For fastest builds, disable it with `NH_NOM=0`.
