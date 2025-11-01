# Additional Optimization Recommendations

## Found Optimization Opportunities

### 1. Debug Packages (~750MB)

Found large debug packages that can be removed if not needed:

- `cmake-3.31.7-debug`: 454MB
- `vulkan-validation-layers-debug`: 111MB
- `clippy-1.88.0-debug`: 65MB
- `systemd-debug`: 51MB
- `git-debug`: 50MB
- `valgrind-debug`: 45MB
- `postgresql-debug`: 28MB

**Action**: These are automatically cleaned by the enhanced cleanup script.

### 2. Duplicate CUDA Libraries (~1.3GB)

Found duplicate `libcublas` packages:

- Two identical 672MB packages (same version, different build variants)

**Action**: Cleanup script now removes duplicates.

### 3. Large Source Tarballs (~1.2GB)

Source archives that might not be needed after builds:

- `rustc-1.88.0-src.tar.gz`: 584MB
- Various source packages: ~640MB

**Note**: These are kept by default for rebuilds. Only remove if you never rebuild from source.

### 4. Configuration Optimizations

#### Consider Using rustup Instead of Multiple rustc Versions

Your config uses `rustup` which is good, but old `rustc` versions might still be in the store.

**Current**: Multiple rustc versions (1.78, 1.88, 1.89) taking ~1.5GB
**Recommendation**: Use `rustup` in devShells only, remove global rustc installations

#### Development Tools in DevShells

Consider moving development tools to `devShells` instead of global packages:

- ✅ Already doing this for Rust, Python, Node.js
- Consider: cmake, gnumake, pkg-config (if only needed for development)

#### Optional Services Review

You have many services enabled. Consider if all are needed:

- **Media Management**: All services enabled (large but intentional)
- **AI Tools**: Ollama + Open WebUI (large but needed)
- **Home Assistant**: 345MB (large but needed)
- **Cal.com**: Enabled (consider if actively used)

### 5. Nix Store Settings

Already optimized:

- ✅ `auto-optimise-store = true`
- ✅ `keep-outputs = true`
- ✅ `keep-derivations = true`
- ✅ Weekly automatic GC
- ✅ Weekly optimization

### 6. Additional Cleanup Options

#### Remove Build Dependencies After Builds

If you never rebuild from source, you can be more aggressive:

```nix
# In nix-optimization.nix, add:
nix.settings.keep-outputs = false;  # Don't keep outputs after builds
nix.settings.keep-derivations = false;  # Don't keep .drv files
```

**Warning**: This makes rebuilds slower but saves space.

#### Remove Old Generations More Aggressively

Your current GC keeps 7 days. Consider reducing:

```nix
nix.gc.options = "--delete-older-than 3d";  # Keep only 3 days
```

### 7. Estimated Total Savings

After enhanced cleanup:

- **Duplicate packages**: ~7-8GB
- **Debug packages**: ~750MB
- **Duplicate CUDA**: ~672MB
- **Total**: ~9-10GB potential savings

## Quick Wins

1. **Run enhanced cleanup script** (now includes debug packages)
2. **Review debug packages**: Remove if not debugging system components
3. **Review CUDA duplicates**: Keep only one version
4. **Consider rustup-only**: Remove global rustc if using rustup

## Long-term Optimizations

1. **Move dev tools to devShells**: Already doing this, continue trend
2. **Review service usage**: Disable unused services
3. **Use binary caches**: Already configured, ensure they're working
4. **Regular cleanup**: Automated monthly cleanup will handle this
