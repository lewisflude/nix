# Nix Store Optimization Guide

Your Nix store optimization is now automated! Here's how to manage it:

## Quick Commands

```bash
# Check current store size
nix-size

# Quick cleanup (immediate space recovery)
nix-clean

# Full optimization (runs weekly automatically)
nix-optimize

# Analyze store usage and find large packages
nix-analyze
```

## What's Automated

### 🔄 **Automatic Optimization**
- **Store deduplication**: Runs automatically on builds
- **Garbage collection**: Every Monday at 3:15 AM (removes >7 day old items)
- **Full optimization**: Every Monday at 3:30 AM
- **Profile cleanup**: Automatically removes old profile generations

### ⚙️ **Build Optimization**
- **Multi-core builds**: Uses all available CPU cores
- **Binary caches**: Pre-built packages from nixpkgs.org, nix-community, and Determinate Systems
- **Smart GC**: Starts cleanup when disk space < 1GB, stops at 3GB free

### 📊 **Space Management**
- **Before optimization**: Your store was ~61GB
- **Target**: Expect 20-40GB after optimization
- **Monitoring**: Use `nix-size` to track usage

## Manual Optimization

### Emergency Cleanup
```bash
# Nuclear option - removes everything not currently referenced
sudo nix-collect-garbage -d

# Remove specific generations
sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system
```

### Analysis Tools
```bash
# Find largest packages
nix path-info --recursive --size /run/current-system | sort -nk2 | tail -10

# Visualize dependencies
nix-tree /run/current-system

# Check what's keeping packages alive
nix-store --gc --print-roots
```

## Optimization Schedule

| Time | Action | Purpose |
|------|--------|---------|
| **Every build** | Store deduplication | Automatic space saving |
| **Monday 3:15 AM** | Garbage collection | Remove old generations |
| **Monday 3:30 AM** | Full optimization | Complete store cleanup |
| **On-demand** | Manual cleanup | Emergency space recovery |

## Expected Results

After running the full optimization:
- **Immediate**: 20-50% size reduction from deduplication
- **Weekly**: Consistent cleanup of unused packages
- **Long-term**: Stable ~20-40GB store size for development workload

## Troubleshooting

### Store Still Large?
1. Check what's consuming space: `nix-analyze`
2. Look for old system generations: `sudo nix-env --list-generations --profile /nix/var/nix/profiles/system`
3. Remove old generations: `sudo nix-env --delete-generations +5 --profile /nix/var/nix/profiles/system`

### Build Performance Issues?
- Check cache settings in `/etc/nix/nix.conf`
- Verify binary substituters are working: `nix store ping`
- Monitor build cores: System should use all available cores

### Logs
- Optimization logs: `/var/log/nix-optimization.log`
- Error logs: `/var/log/nix-optimization-error.log`