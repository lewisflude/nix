# Build Profiling Guide

This guide covers tools and techniques for analyzing what takes the most time when building your NixOS/nix-darwin configuration.

## Quick Start

**Profile your current build:**

```bash
./scripts/utils/profile-build.sh --full
```

**Find which modules are slow:**

```bash
./scripts/utils/profile-modules.sh
```

**Track performance over time:**

```bash
./scripts/utils/benchmark-rebuild.sh
```

## Available Tools

### 1. `profile-build.sh` - Comprehensive Profiling ⭐

The main profiling tool that combines multiple analysis techniques.

**Quick Profile:**

```bash
./scripts/utils/profile-build.sh
```

Shows:

- Evaluation time
- Number of derivations to build
- Quick summary

**Full Profile:**

```bash
./scripts/utils/profile-build.sh --full
```

Additionally shows:

- Build planning time
- Largest derivations by closure size
- Module import counts
- Common package patterns
- Store statistics
- Performance recommendations

**Profile Specific Config:**

```bash
./scripts/utils/profile-build.sh nixosConfigurations.jupiter --full
./scripts/utils/profile-build.sh darwinConfigurations.$(hostname -s) --full
```

### 2. `benchmark-rebuild.sh` - Historical Tracking

Tracks build performance over time with historical data.

```bash
./scripts/utils/benchmark-rebuild.sh
```

Results saved to `.benchmark-history/` directory with:

- Timestamp
- Evaluation time
- Build planning time
- Package count
- Git commit info

View historical trends:

```bash
ls -lh .benchmark-history/
jq . .benchmark-history/*.json | less
```

### 3. `profile-modules.sh` - Module-Level Profiling ⭐

Analyze which modules take the most time to evaluate.

```bash
./scripts/utils/profile-modules.sh [config-name]
```

Shows:

- Modules with most imports
- Largest modules by line count
- Evaluation time comparison
- Function call tracing
- Dependency visualization tips

**Example:**

```bash
./scripts/utils/profile-modules.sh nixosConfigurations.jupiter
```

### 4. `nix-monitor.sh` - System Monitoring

Monitor system and build performance.

```bash
~/.config/nix/scripts/build/nix-monitor.sh performance
```

Shows:

- Recent build times
- Average build time
- Slowest builds today

## Standard Nix Tools

### Evaluation Time

```bash
# Simple timing
time nix eval --raw .#nixosConfigurations.jupiter.config.system.build.toplevel

# With trace (see what's being evaluated)
nix eval --show-trace .#nixosConfigurations.jupiter.config.system.build.toplevel
```

### Build Planning (Dry-Run)

```bash
# See what would be built
nix build .#nixosConfigurations.jupiter --dry-run --json | jq .

# Count derivations
nix build .#nixosConfigurations.jupiter --dry-run --json | \
  jq '[.[] | .drvPath] | length'

# List all derivation paths
nix build .#nixosConfigurations.jupiter --dry-run --json | \
  jq -r '.[] | .drvPath'
```

### Derivation Size Analysis

```bash
# Get closure sizes
nix build .#nixosConfigurations.jupiter --dry-run --json | \
  jq -r '.[] | .outputs.out // .drvPath' | \
  xargs -I {} nix path-info -S {} | \
  sort -k2 -rn | head -20

# Visualize dependencies
nix profile install nixpkgs#nix-tree
nix-tree .#nixosConfigurations.jupiter
```

### Build Time Analysis

```bash
# Build with detailed logs
nix build .#nixosConfigurations.jupiter \
  --log-format bar-with-logs \
  --max-jobs 1 2>&1 | tee build.log

# Find slowest builds from log
grep -E "building|done" build.log | \
  awk '/building/ {start=$0} /done/ {print start " -> " $0}' | \
  sort -k2 -rn | head -10
```

## Understanding the Output

### Evaluation Time

- **< 2 seconds**: Excellent
- **2-5 seconds**: Good
- **5-10 seconds**: Acceptable
- **> 10 seconds**: Consider optimization

Slow evaluation usually indicates:

- Too many module imports
- Heavy computation during evaluation
- Large package sets being evaluated

### Derivation Count

- **< 100**: Very small config
- **100-500**: Small to medium
- **500-1000**: Medium to large
- **> 1000**: Large config (many packages)

### Build Planning Time

- **< 1 second**: Excellent
- **1-3 seconds**: Good
- **> 3 seconds**: Consider optimization

## Common Optimizations

### 1. Reduce Module Imports

```nix
# Instead of importing entire directories
imports = [ ./modules ];

# Import only what you need
imports = [
  ./modules/core
  ./modules/services/nginx.nix
];
```

### 2. Use Cachix

```bash
# Set up Cachix for binary cache
nix run .#setup-cachix
cachix use lewisflude-nix
```

### 3. Optimize Package Sets

```nix
# Instead of large package sets
environment.systemPackages = with pkgs; [ /* many packages */ ];

# Use smaller, focused sets
environment.systemPackages = [
  pkgs.vim
  pkgs.git
  # etc.
];
```

### 4. Clean Dead Paths

```bash
# Remove unused packages
nix-collect-garbage -d

# Optimize store (deduplication)
nix store optimise
```

### 5. Parallel Builds

Check your `nix.conf`:

```bash
max-jobs = auto  # Use all CPU cores
cores = 0        # Use all cores per job
```

## Troubleshooting Slow Builds

### Step 1: Identify the Bottleneck

```bash
# Run full profile
./scripts/utils/profile-build.sh --full
```

### Step 2: Check Evaluation Time

If evaluation is slow:

- Look for heavy imports
- Check for expensive computations in modules
- Review module structure

### Step 3: Check Build Time

If builds are slow:

- Check derivation count
- Identify largest derivations
- Verify Cachix is working: `cachix watch-store`
- Check if packages are being built vs downloaded

### Step 4: Analyze Dependencies

```bash
# Visualize dependency tree
nix-tree .#nixosConfigurations.jupiter

# See what depends on what
nix-store --query --tree $(nix build .#nixosConfigurations.jupiter --dry-run --json | jq -r '.[0].drvPath')
```

## Performance Benchmarks

Track your configuration's performance over time:

```bash
# Before changes
./scripts/utils/benchmark-rebuild.sh > baseline.txt

# After changes
./scripts/utils/benchmark-rebuild.sh > after.txt

# Compare
diff baseline.txt after.txt
```

## Advanced Profiling

### Function Call Tracing

```bash
nix-instantiate --trace-function-calls /dev/null -E '
  with import <nixpkgs> {};
  (import ./flake.nix).nixosConfigurations.jupiter.config.system.build.toplevel
' 2>&1 | head -100
```

### Profile Specific Modules

```bash
# Time a specific module evaluation
time nix eval --raw .#nixosConfigurations.jupiter.config.services.nginx.enable
```

### Module-Level Profiling ⭐

**Find which modules take the most time:**

```bash
./scripts/utils/profile-modules.sh [config-name]
```

This tool provides several methods to identify slow modules:

1. **Module dependency analysis** - Shows which modules import the most dependencies
2. **Evaluation time comparison** - Measures overall evaluation time
3. **Function call tracing** - Traces which modules/functions are being called
4. **Visualization** - Uses nix-tree to see module impact

**Manual module profiling:**

Since Nix evaluates modules lazily and merges them together, direct per-module timing isn't available. However, you can:

1. **Compare evaluation times:**

   ```bash
   # Baseline
   time nix eval --raw .#nixosConfigurations.jupiter.config.system.build.toplevel

   # Temporarily comment out module imports in hosts/*/configuration.nix
   # Re-measure and compare
   ```

2. **Profile individual module files:**

   ```bash
   # Create a test file
   cat > test-module.nix <<EOF
   { config, lib, pkgs, ... }:
   import ./modules/nixos/services/your-module.nix
   EOF

   # Time its evaluation
   time nix-instantiate --eval -E 'import ./test-module.nix'
   ```

3. **Use function call tracing:**

   ```bash
   nix-instantiate --trace-function-calls -E '
     with import <nixpkgs> {};
     (import ./flake.nix).nixosConfigurations.jupiter.config.system.build.toplevel
   ' 2>&1 | grep -E "trace:|call" | head -50
   ```

4. **Analyze module complexity:**

   ```bash
   # Find modules with most imports
   find modules -name "*.nix" -exec sh -c '
     echo "$(grep -cE "^[[:space:]]*import|^[[:space:]]*imports[[:space:]]*=" "$1" 2>/dev/null || echo 0) $1"
   ' _ {} \; | sort -rn | head -20
   ```

### Build Log Analysis

```bash
# Capture build log
nix build .#nixosConfigurations.jupiter 2>&1 | tee build.log

# Analyze timing
grep -E "building|done" build.log | \
  awk '{
    if (/building/) {
      drv=$NF; start=NR
    }
    if (/done/) {
      print drv " took " (NR-start) " lines"
    }
  }' | sort -k3 -rn
```

## External Tools

### `nix-time`

```bash
nix profile install nixpkgs#nix-time
nix-time nix eval .#nixosConfigurations.jupiter.config.system.build.toplevel
```

### `nix-tree`

```bash
nix profile install nixpkgs#nix-tree
nix-tree .#nixosConfigurations.jupiter
```

## Tips

1. **Run profiles regularly** - Track performance trends
2. **Profile before/after changes** - See impact of modifications
3. **Use Cachix** - Dramatically speeds up builds
4. **Clean periodically** - Remove dead paths and optimize store
5. **Monitor module count** - Too many modules can slow evaluation

## Related Documentation

- [Nix Manual - Performance](https://nixos.org/manual/nix/stable/advanced-topics/performance-tuning.html)
- [NixOS Manual - Optimization](https://nixos.org/manual/nixos/stable/index.html#sec-optimise-store)
- [Cachix Setup Guide](../CACHIX_FLAKEHUB_SETUP.md)
