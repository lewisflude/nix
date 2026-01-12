# Automatic Immersed VR Updates

This guide explains how to keep Immersed VR automatically updated to the latest version.

## Overview

The Immersed VR updater system provides three ways to update:

1. **Manual updates** - Run `nix run .#update-immersed` when you want to check for updates
2. **Integrated with `update-all`** - Updates happen when you run `nix run .#update-all`
3. **Automatic timer** - Enable a systemd timer to check for updates automatically

## Manual Updates

### Update Immersed Only

```bash
# Check for and install Immersed updates
nix run .#update-immersed

# Dry-run to see what would change
nix run .#update-immersed -- --dry-run

# Update a different platform (if cross-compiling)
nix run .#update-immersed -- --platform aarch64-linux
```

### Update with Other Dependencies

The `update-all` script now includes Immersed updates by default:

```bash
# Update everything (flake, plugins, overlays, AND Immersed)
nix run .#update-all

# Update everything except Immersed
nix run .#update-all -- --skip-immersed

# Dry-run to see what would update
nix run .#update-all -- --dry-run
```

## Automatic Updates

Enable the systemd timer to automatically check for Immersed updates:

### Basic Setup

Add to your host configuration (`hosts/jupiter/configuration.nix`):

```nix
{
  # Enable automatic Immersed VR updates
  services.auto-update-immersed = {
    enable = true;
    interval = "daily"; # Check once per day
  };
}
```

### Advanced Configuration

```nix
{
  services.auto-update-immersed = {
    enable = true;

    # How often to check for updates
    # Uses systemd OnCalendar format
    interval = "Mon,Thu *-*-* 00:00:00"; # Monday and Thursday at midnight

    # Path to your Nix configuration
    configPath = /home/lewis/.config/nix;

    # Automatically commit updates (careful!)
    autoCommit = true;

    # Automatically rebuild the system after updating (very careful!)
    autoRebuild = false; # Recommended: keep this false
  };
}
```

### Check Timer Status

```bash
# Check if timer is active
systemctl status update-immersed.timer

# View timer schedule
systemctl list-timers update-immersed

# Manually trigger an update check
sudo systemctl start update-immersed.service

# View update logs
journalctl -u update-immersed.service -f
```

### Safety Recommendations

**⚠️ Important Safety Notes:**

1. **Don't enable `autoRebuild`** unless you're very confident
   - System rebuilds can fail if there are syntax errors
   - Better to review changes manually first

2. **`autoCommit` is safer** but still creates commits without review
   - Useful for keeping a clean git history
   - You can always revert with `git reset HEAD~1`

3. **Recommended workflow:**

   ```nix
   services.auto-update-immersed = {
     enable = true;
     interval = "daily";
     autoCommit = false;  # Review changes manually
     autoRebuild = false; # Rebuild manually
   };
   ```

4. **Check for updates manually:**

   ```bash
   # See if there are new changes
   cd ~/.config/nix
   git status

   # Review the hash change
   git diff overlays/default.nix

   # Build and test
   nh os build

   # Apply if everything looks good
   nh os switch

   # Commit the change
   git commit -am "chore(vr): update Immersed to latest version"
   ```

## How It Works

### Update Process

1. **Download**: Fetches the latest Immersed AppImage from `https://static.immersed.com/dl/`
2. **Hash**: Calculates the SHA256 hash of the downloaded file
3. **Compare**: Checks if the hash has changed from the current version
4. **Update**: If changed, updates the hash in `overlays/default.nix`
5. **Format**: Runs `nix fmt` to format the updated file
6. **Optional**: Creates a git commit (if `autoCommit = true`)
7. **Optional**: Rebuilds the system (if `autoRebuild = true`)

### Files Modified

When an update is found, the updater modifies:

- `overlays/default.nix` - Updates the `immersed-latest` overlay with the new hash

### Version Detection

The updater doesn't know the exact version number (Immersed doesn't provide this in a machine-readable way). Instead, it:

1. Uses the content hash to detect changes
2. Labels the version as `11.0.0-latest` in the overlay
3. Relies on hash changes to trigger updates

## Troubleshooting

### Update Failed

```bash
# Check the logs
journalctl -u update-immersed.service -n 50

# Common issues:
# 1. Network failure - Immersed download unavailable
# 2. Git conflicts - Uncommitted changes in overlays/default.nix
# 3. Permission errors - Service can't write to config path
```

### Hash Mismatch After Update

If you see build errors about hash mismatches:

```bash
# Re-run the updater to recalculate
nix run .#update-immersed

# Or manually download and calculate:
curl -L https://static.immersed.com/dl/Immersed-x86_64.AppImage -o /tmp/immersed.AppImage
nix hash file /tmp/immersed.AppImage

# Update overlays/default.nix with the new hash
```

### Timer Not Running

```bash
# Check timer is enabled
systemctl status update-immersed.timer

# Enable it if needed
sudo systemctl enable update-immersed.timer
sudo systemctl start update-immersed.timer

# Check for errors
sudo systemctl status update-immersed.service
```

## Disabling Automatic Updates

To disable the automatic timer:

```nix
{
  services.auto-update-immersed.enable = false;
}
```

Then rebuild:

```bash
nh os switch
```

The timer will be stopped and disabled.

## Integration with CI/CD

If you use GitHub Actions or similar CI/CD:

```yaml
name: Update Immersed
on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight
  workflow_dispatch:  # Manual trigger

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: cachix/install-nix-action@v20
      - name: Update Immersed
        run: nix run .#update-immersed
      - name: Create Pull Request
        if: ${{ success() }}
        uses: peter-evans/create-pull-request@v4
        with:
          title: "chore(vr): update Immersed to latest version"
          commit-message: "chore(vr): auto-update Immersed"
          branch: auto-update-immersed
```

## Manual Hash Update

If you prefer to update manually without the script:

1. Download the latest AppImage:

   ```bash
   curl -L https://static.immersed.com/dl/Immersed-x86_64.AppImage -o /tmp/immersed.AppImage
   ```

2. Calculate the hash:

   ```bash
   nix hash file /tmp/immersed.AppImage
   ```

3. Update `overlays/default.nix`:
   - Find the `immersed-latest` overlay
   - Update the `hash = "sha256-..."` line for x86_64-linux
   - Save the file

4. Format:

   ```bash
   nix fmt overlays/default.nix
   ```

5. Test and apply:

   ```bash
   nh os build
   nh os switch
   ```

## See Also

- [Overlays README](../overlays/README.md) - Overview of all overlays
- [VR Setup Guide](VR_SETUP_GUIDE.md) - Complete VR configuration
- [Update All Script](../pkgs/pog-scripts/update-all.nix) - Source code for update-all
- [Update Immersed Script](../pkgs/pog-scripts/update-immersed.nix) - Source code for update-immersed
