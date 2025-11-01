# Understanding Nix Store Size After Rebuild

## Important: Rebuilding ≠ Cleanup

**Rebuilding your system (`nixos-rebuild switch`)** will:

- ✅ Create a new system generation
- ✅ Keep your old system generation (for rollback)
- ❌ **Does NOT remove old packages automatically**
- 📈 **Store size will INCREASE temporarily** (new generation + new packages)

**Running the cleanup script** will:

- ✅ Remove old/unused package versions
- ✅ Remove duplicate packages
- ✅ Remove debug packages
- ✅ Remove dead paths
- 📉 **Store size will DECREASE**

## Recommended Workflow

### Option 1: Cleanup First (Recommended)

```bash
# 1. Run cleanup to remove old packages
sudo bash ~/.config/nix/scripts/cleanup-duplicates.sh

# 2. Rebuild system
sudo nixos-rebuild switch --flake ~/.config/nix#jupiter

# 3. Verify size reduction
du -sh /nix/store
```

**Result**: You'll see immediate size reduction, then small increase from rebuild.

### Option 2: Rebuild Then Cleanup

```bash
# 1. Rebuild system
sudo nixos-rebuild switch --flake ~/.config/nix#jupiter

# 2. Run cleanup (removes old packages from previous generation)
sudo bash ~/.config/nix/scripts/cleanup-duplicates.sh

# 3. Verify size reduction
du -sh /nix/store
```

**Result**: Temporary size increase, then reduction after cleanup.

### Option 3: Wait for Automatic Cleanup

Your system has automatic maintenance:

- **Weekly GC**: Removes packages older than 7 days
- **Weekly optimization**: Deduplicates packages
- **Monthly cleanup**: Removes duplicate versions (first Monday)

**Result**: Size will decrease gradually over time, but you can speed it up manually.

## What You'll See

### Before Cleanup

```
Store size: ~62GB
- Multiple versions of packages
- Debug packages
- Duplicate CUDA libraries
- Old system generations
```

### After Cleanup

```
Store size: ~52-53GB (estimated 9-10GB reduction)
- One version per package
- No debug packages (unless referenced)
- No duplicate CUDA libraries
- Only current + recent generations
```

### After Rebuild (without cleanup)

```
Store size: ~62-63GB (slightly larger)
- New system generation added
- Old packages still present
- Both old and new package versions
```

## Why Rebuild Doesn't Clean Up

Nix keeps old generations for:

- **Safety**: Rollback if new generation has issues
- **Reproducibility**: Can rebuild exact old state
- **Gradual cleanup**: GC removes old generations after 7 days

## Automatic Cleanup

Your system is configured with:

```nix
nix.gc.automatic = true;
nix.gc.dates = "weekly";
nix.gc.options = "--delete-older-than 7d";
```

This means:

- Old generations are removed after 7 days
- But duplicate versions accumulate until manual cleanup

## Quick Answer

**To see smaller size immediately:**

1. Run cleanup script FIRST
2. Then rebuild if needed

**To see smaller size eventually:**

- Wait for automatic weekly GC (removes old generations)
- Wait for automatic monthly cleanup (removes duplicates)

**Best practice:**

- Run cleanup script before major rebuilds
- Let automatic maintenance handle routine cleanup
- Monitor store size monthly
