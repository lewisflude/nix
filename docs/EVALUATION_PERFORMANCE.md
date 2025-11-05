# Evaluation Performance Analysis

## Understanding the Metrics

Your profiling script measures **evaluation complexity**, not build time. Understanding the difference is crucial:

### Evaluation Time vs Build Time

- **Evaluation Time**: The time Nix takes to parse, evaluate, and merge all your Nix modules into a single configuration. This happens **before** any packages are built.
- **Build Time**: The time it takes to actually build/download packages from caches. This happens **after** evaluation.

Your metrics primarily affect **evaluation time**, which is typically much shorter than build time.

## How These Metrics Impact Performance

### 1. Module Complexity (imports × lines)

**What it measures:**

- Number of module imports per file
- File size (line count)
- Complexity score = imports × lines

**Impact on evaluation:**

- **High import count**: More modules to merge during evaluation
- **Large files**: More code for Nix to parse and type-check
- **Combined effect**: Multiplicative - files with many imports AND many lines are the worst

**Your top offenders:**

```
688 complexity: containers-supplemental/default.nix (8 imports, 86 lines)
555 complexity: containers/default.nix (5 imports, 111 lines)
475 complexity: media-management/default.nix (19 imports, 25 lines)
```

**Why this matters:**

- Each import triggers evaluation of another module
- Modules with many imports create a dependency graph that Nix must traverse
- Large option definition files (like `host-options.nix`) are evaluated once but can slow down the initial evaluation

### 2. Large Option Definition Files (>300 lines)

**What it measures:**

- Files with more than 300 lines of code

**Your large files:**

```
720 lines: modules/shared/host-options.nix (already split!)
450 lines: modules/shared/host-options/services.nix
559 lines: modules/nixos/services/containers/media-management.nix
526 lines: modules/nixos/services/media-management/qbittorrent.nix
474 lines: modules/nixos/services/containers-supplemental/services/calcom.nix
```

**Impact on evaluation:**

- More option definitions to type-check
- Larger module merge operations
- More memory usage during evaluation
- Slower option resolution

**Why this matters:**

- Nix evaluates option definitions eagerly during module system evaluation
- Large option trees take longer to construct and validate
- Type checking happens during evaluation, not build

## Real-World Impact

### Typical Evaluation Times

Based on your configuration complexity:

- **Expected evaluation time**: 2-10 seconds
- **Your baseline**: (Check your profiling output)
- **Acceptable range**: < 10 seconds for most configurations

### What's Actually Slow?

1. **High-complexity modules** (688, 555, 475 complexity):
   - These are **moderate** complexity, not extreme
   - Impact: +0.5-2 seconds each potentially
   - **Not a major concern** unless evaluation is > 10 seconds

2. **Large option files** (450-720 lines):
   - `services.nix` (450 lines) - **moderate**, mostly option definitions
   - `qbittorrent.nix` (526 lines) - **moderate**, option definitions + configuration
   - `calcom.nix` (474 lines) - **moderate**, many nested options
   - **Impact**: +0.5-3 seconds total potentially
   - **Not a major concern** unless evaluation is > 10 seconds

3. **Home Assistant** (344 lines, 1 import):
   - Large inline configuration
   - Many extraComponents and customComponents
   - Complex script definitions
   - **Impact**: +0.5-1 second potentially
   - **Not a major concern** unless evaluation is > 10 seconds

## When to Worry

### Red Flags 🚩

1. **Evaluation time > 10 seconds**: Something is genuinely slow
2. **Very high complexity scores (>1000)**: Indicates deeply nested imports
3. **Files with >50 imports**: Excessive module coupling
4. **Files with >1000 lines**: Should definitely be split

### Your Current State ✅

Based on your metrics:

- **Max complexity**: 688 (moderate)
- **Max imports**: 19 (reasonable)
- **Max file size**: 720 lines (large, but already split)
- **Most files**: <500 lines (acceptable)

**Verdict**: Your configuration is **within acceptable ranges**. Unless your evaluation time is > 10 seconds, no optimization is urgently needed.

## Optimization Strategies

### If Evaluation Time is Slow (>10 seconds)

#### 1. Split Large Option Files Further

**Current state:**

- `host-options.nix` (720 lines) → Already split into:
  - `core.nix`
  - `features.nix`
  - `services.nix` (450 lines)

**Further optimization:**

```nix
# Split services.nix (450 lines) into:
modules/shared/host-options/services/
  - media-management.nix
  - ai-tools.nix
  - containers-supplemental.nix
```

**Expected improvement**: 0.5-1 second

#### 2. Reduce Module Imports

**High-complexity modules:**

- `media-management/default.nix` (19 imports)
- `nixos/default.nix` (18 imports)
- `darwin/default.nix` (16 imports)

**Strategy:**

- Use conditional imports where possible
- Lazy-load modules that aren't always needed
- Combine related modules

**Example:**

```nix
# Instead of:
imports = [ ./service1 ./service2 ./service3 ... ./service19 ];

# Use conditional:
imports =
  lib.optionals cfg.enable [
    ./service1
    ./service2
  ] ++
  lib.optionals cfg.enableAdvanced [
    ./service3
    ./service4
  ];
```

**Expected improvement**: 0.5-2 seconds

#### 3. Optimize Option Definitions

**Large option files:**

- `services.nix` (450 lines) - mostly options
- `qbittorrent.nix` (526 lines) - options + config

**Strategy:**

- Move option definitions to separate files
- Keep implementations in implementation files
- Use `types.submodule` for complex nested structures

**Example:**

```nix
# options.nix - only option definitions
options.host.features.mediaManagement.qbittorrent = {
  enable = mkEnableOption "...";
  webUI = mkOption { ... };
  # etc.
};

# qbittorrent.nix - implementation
config = mkIf cfg.qbittorrent.enable {
  # actual service configuration
};
```

**Expected improvement**: 0.3-1 second

#### 4. Lazy Evaluation Patterns

**For large inline configurations:**

- `home-assistant.nix` (344 lines) - large inline config

**Strategy:**

- Move large config blocks to separate files
- Use `import` for complex configurations
- Defer evaluation until needed

**Example:**

```nix
# home-assistant.nix
config = {
  services.home-assistant.config = import ./home-assistant-config.nix;
};

# home-assistant-config.nix
{
  # Large configuration here
}
```

**Expected improvement**: 0.2-0.5 seconds

## Measurement

### Check Your Baseline

```bash
# Run the profiling script
./scripts/utils/profile-evaluation.sh nixosConfigurations.jupiter

# Check the baseline evaluation time
# If < 10 seconds: No urgent optimization needed
# If > 10 seconds: Apply optimizations above
```

### Measure Impact of Changes

```bash
# Before optimization
time nix eval --raw .#nixosConfigurations.jupiter.config.system.build.toplevel

# Make changes, then:
time nix eval --raw .#nixosConfigurations.jupiter.config.system.build.toplevel

# Compare times
```

## Build Time Impact

**Important**: These metrics affect **evaluation time**, not build time.

- **Evaluation time**: 2-10 seconds (typically)
- **Build time**: Minutes to hours (depends on packages)

**Your module complexity does NOT affect:**

- Package build time
- Binary cache download speed
- Closure size
- Build parallelism

**It ONLY affects:**

- Initial configuration evaluation
- Module system merge time
- Option type checking

## Recommendations

### Immediate Actions (if evaluation > 10s)

1. ✅ **Already done**: Split `host-options.nix` into multiple files
2. Consider splitting `services.nix` (450 lines) further
3. Review high-import modules for conditional loading opportunities
4. Move large inline configs to separate files

### Long-term Optimizations

1. **Module consolidation**: Combine related modules
2. **Lazy loading**: Only import modules when features are enabled
3. **Option organization**: Keep options separate from implementations
4. **Configuration externalization**: Move large configs to separate files

### Monitoring

Track evaluation time over time:

```bash
# Add to CI or periodic checks
./scripts/utils/profile-evaluation.sh > evaluation-stats.txt
```

## Conclusion

Your configuration complexity is **within acceptable ranges**. The metrics indicate:

- ✅ **Moderate complexity** (max 688)
- ✅ **Reasonable file sizes** (max 720 lines, already split)
- ✅ **Manageable import counts** (max 19)

**Unless your evaluation time is > 10 seconds, these optimizations are optional.** Focus on:

1. **Build time optimizations** (Cachix, parallel builds) - bigger impact
2. **Package set reductions** - reduces both evaluation and build time
3. **Module organization** - improves maintainability, minor performance gain

**Bottom line**: Your profiling shows good organization. The "large" files are mostly option definitions, which is expected for a comprehensive configuration. Only optimize if evaluation time is actually slow.
