# macOS Performance Guide - M4 Pro Optimizations

This guide documents performance optimizations specifically for macOS systems, with special focus on Apple Silicon (M4 Pro) MacBook Pro.

## Hardware Specifications

**MacBook Pro (2024)**
- Chip: Apple M4 Pro
- Memory: 24 GB unified memory
- Storage: NVMe SSD

## Applied Optimizations

### 1. Nix Build Performance

**Location**: `modules/darwin/nix.nix`

#### Network and Parallelism Settings

```nix
http-connections = 128           # Maximizes parallel downloads (was 64)
max-substitution-jobs = 64       # Optimized for M4 Pro cores (was 28)
download-buffer-size = 524288000 # Large buffer for fast downloads
connect-timeout = 5              # Quick failure detection
```

**Expected Impact**: 2-4x faster binary cache downloads and substitutions.

#### Build Resilience

```nix
keep-going = true               # Continue building on single failures
always-allow-substitutes = true # Use caches aggressively
builders-use-substitutes = true # Remote builders use caches directly
```

**Expected Impact**: Better parallel build utilization and fewer rebuilds.

### 2. UI Responsiveness

**Location**: `modules/darwin/system-preferences.nix`

#### Animation Disabling

```nix
NSAutomaticWindowAnimationsEnabled = false  # Instant window operations
NSWindowResizeTime = 0.001                  # Near-instant resize
NSUseAnimatedFocusRing = false              # No focus ring animation
```

**Expected Impact**: Instantly responsive UI, no animation lag.

#### Text Input Performance

```nix
NSAutomaticTextCompletionEnabled = false     # Disable autocomplete lag
NSAutomaticSpellingCorrectionEnabled = false # No spell-check delays
NSAutomaticInlinePredictionEnabled = false   # No prediction overhead
```

**Expected Impact**: Immediate text input response, especially in code editors.

### 3. Dock Performance

**Location**: `modules/darwin/dock-preferences.nix`

```nix
autohide = true
autohide-delay = 0.0              # Instant dock appearance (was 0.0)
autohide-time-modifier = 0.0      # Instant animation (was 0.5)
expose-animation-duration = 0.1   # Fast Mission Control (was 0.5)
launchanim = false                # No app launch animation
```

**Expected Impact**: Instant Dock interactions and faster app switching.

### 4. System-Wide Performance

**Location**: `modules/darwin/performance.nix` (NEW)

#### Visual Effects Reduction

```nix
reduceTransparency = true  # Reduce GPU load
reduceMotion = true        # Minimal animations system-wide
```

**Expected Impact**: Reduced GPU usage, especially on external displays.

#### Application Performance

```nix
NSDisableAutomaticTermination = true  # Keep apps responsive
NSQuitAlwaysKeepsWindows = false      # Disable resume (faster launch)
```

**Expected Impact**: Apps stay in memory, faster switching and reopening.

#### System Service Optimizations

Via activation scripts:
- Disabled sudden motion sensor (not needed on SSD)
- Disabled hibernation (faster sleep/wake)
- Removed sleep image file
- Disabled boot sound effects
- Disabled Notification Center
- Optimized standby delay

**Expected Impact**: Faster sleep/wake cycles, reduced background CPU usage.

### 5. File System Performance

**Location**: `modules/darwin/system.nix`

```nix
launchaemon.limit-maxfiles = {
  command = "/bin/launchctl limit maxfiles 65536 200000";
  # Increased file descriptor limits for development
}
```

**Expected Impact**: Better performance for development tools and build systems.

### 6. Finder Performance

**Location**: `modules/darwin/finder-preferences.nix`

```nix
_FXSortFoldersFirst = true            # Faster file listing
FXPreferredViewStyle = "Nlsv"         # List view (fastest)
FXRemoveOldTrashItems = true          # Auto-cleanup
```

**Expected Impact**: Faster file browsing, especially in large directories.

## Additional Manual Optimizations

### System Settings (Not in Nix Config)

1. **Energy Saver** (Settings → Battery):
   - Prevent Mac from automatically sleeping: When display is off
   - Enable "Put hard disks to sleep when possible": OFF

2. **Accessibility** (Settings → Accessibility):
   - Display → Reduce transparency: ON (handled by Nix)
   - Display → Reduce motion: ON (handled by Nix)

3. **Desktop & Dock** (Settings → Desktop & Dock):
   - Minimize windows using: Scale effect (handled by Nix)
   - Automatically hide and show the Dock: ON (handled by Nix)

### Application-Specific Settings

#### Terminal/ITerm2
- Disable terminal bell
- Use GPU acceleration
- Reduce scrollback buffer if not needed

#### VS Code/Cursor
```json
{
  "editor.smoothScrolling": false,
  "workbench.list.smoothScrolling": false,
  "terminal.integrated.smoothScrolling": false,
  "editor.cursorSmoothCaretAnimation": "off"
}
```

#### Chrome/Brave
- Disable hardware acceleration if experiencing UI lag
- Clear cache regularly
- Limit number of extensions

## Performance Monitoring

### System Performance

```bash
# CPU usage
top -l 1 | grep "CPU usage"

# Memory pressure
memory_pressure

# Disk I/O
iostat -d 1 5

# Network activity
nettop -n -l 1
```

### Nix Build Performance

```bash
# Time a rebuild
time darwin-rebuild switch --flake ~/.config/nix#mercury

# Check store size
du -sh /nix/store

# Analyze derivation count
nix-store --query --requisites /run/current-system | wc -l

# Monitor substitution speed
nix build --print-build-logs --show-trace
```

### Baseline Metrics (Update after rebuild)

```bash
# Store before optimization
du -sh /nix/store
# Expected: ~40-60GB depending on usage

# Rebuild time
time darwin-rebuild switch --flake ~/.config/nix#mercury
# Expected: 30-60s for full rebuild with cache hits
```

## Performance Validation

After applying these optimizations, you should notice:

1. **Immediate UI Response**:
   - Windows snap to position instantly
   - Dock appears/hides with no delay
   - Mission Control is near-instant
   - No lag when typing

2. **Faster Builds**:
   - 2-4x faster Nix substitutions
   - Better parallel build utilization
   - Reduced wait time for binary cache queries

3. **System Responsiveness**:
   - Apps launch faster
   - Switching between apps is instant
   - No stuttering or animation lag
   - Better external display performance

## Troubleshooting

### If UI feels sluggish after changes:

```bash
# Restart Dock
killall Dock

# Restart Finder
killall Finder

# Clear system caches
sudo rm -rf /Library/Caches/*
rm -rf ~/Library/Caches/*

# Reset SMC (if needed)
# Shutdown, wait 30s, boot
```

### If Nix builds are slow:

```bash
# Check binary cache connectivity
nix store ping

# Verify cache priorities
nix show-config | grep substituters

# Test download speed
curl -o /dev/null https://cache.nixos.org/nix-cache-info
```

### If apps are misbehaving:

Some apps don't handle disabled animations well. You can selectively re-enable animations per-app:

```bash
# Re-enable animations for specific app
defaults write com.example.app NSAutomaticWindowAnimationsEnabled -bool true
```

## Benchmarking

### Before Optimization Baseline

Document your baseline performance before applying changes:

```bash
# System info
system_profiler SPHardwareDataType SPSoftwareDataType

# Nix store size
du -sh /nix/store > ~/performance-baseline-$(date +%Y%m%d).txt

# Rebuild time
time darwin-rebuild switch --flake ~/.config/nix#mercury 2>&1 | tee -a ~/performance-baseline-$(date +%Y%m%d).txt
```

### After Optimization Metrics

Compare after applying changes:

```bash
# Compare store size
du -sh /nix/store

# Compare rebuild time
time darwin-rebuild switch --flake ~/.config/nix#mercury

# Check for improvements
# Expected: 20-40% faster rebuilds
# Expected: Similar or smaller store size (due to optimizations)
```

## Additional Resources

- [macOS Performance Guide (Apple)](https://support.apple.com/guide/mac-help/welcome/mac)
- [Nix Performance Tuning](../PERFORMANCE_TUNING.md)
- [Darwin Module Options](https://daiderd.com/nix-darwin/manual/index.html)

## Rollback Instructions

If you experience issues with these optimizations, you can disable them:

```nix
# In hosts/mercury/configuration.nix
host.features.performance.enable = false;
```

Then rebuild:

```bash
darwin-rebuild switch --flake ~/.config/nix#mercury
```

## Contributing

If you discover additional macOS performance optimizations, please:
1. Test thoroughly on your system
2. Document the change and expected impact
3. Add to this guide with clear instructions
4. Submit via pull request or issue
