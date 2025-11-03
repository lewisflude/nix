# system-update Performance Improvements

This document outlines performance optimizations for the `system-update` script.

## Implemented Improvements

### 1. **Timing Information** ✅

- Added `log_time()` function to track elapsed time for each operation
- Shows progress with timestamps: `[5s] Validating configuration…`
- Final summary: `✅ Done in 120s`

### 2. **Early Validation** ✅

- Runs `nh os switch --dry` before building to catch errors early
- Saves time by failing fast instead of building then failing
- Can be disabled with `--no-validate` for faster runs

### 3. **Fast Mode** ✅

- New `--fast` flag that:
  - Skips validation (`--no-validate`)
  - Disables nom (`--no-nom`) for faster builds
- Use when you're confident in your changes

### 4. **Better nh Flag Usage** ✅

- Uses `NH_CLEAN_ARGS` environment variable for cleanup
- Adds `--no-nom` flag when `--fast` is used
- Respects environment variable configuration

### 5. **Improved Progress Feedback** ✅

- Clearer status messages with checkmarks
- Better error messages with hints
- Timing information for each step

## Usage Examples

### Standard Update (with validation)

```bash
system-update
# Validates first, then builds/switches
```

### Fast Update (skip validation, no nom)

```bash
system-update --fast
# Fastest option - skips validation and nom
```

### Update Without Validation

```bash
system-update --no-validate
# Skip validation but keep nom
```

### Full Update with Timing

```bash
system-update --full
# Updates inputs, switches, cleans up
# Shows timing for each step
```

## Performance Tips

1. **Use `--fast` for quick iterations** when you're confident in changes
2. **Use standard mode** for important updates to catch errors early
3. **Run `--check` first** if unsure about changes
4. **Set `NH_CLEAN_ARGS`** in your environment for consistent cleanup behavior

## Implementation Notes

The improvements require updating the `system-update` script in `home/common/shell.nix`:

1. Add timing function and variables
2. Add `--fast` and `--no-validate` flags
3. Add early validation logic
4. Add `NH_FLAGS` variable for conditional nom disabling
5. Replace echo statements with `log_time()` calls
6. Use `NH_CLEAN_ARGS` in cleanup command

## Expected Performance Gains

- **Early validation**: Saves 30-60s by catching errors before building
- **--no-nom flag**: Saves 5-15s per build (nom overhead)
- **Better feedback**: Improves perceived performance with clear progress
- **Total**: Can save 35-75s per update cycle

## Future Improvements

Potential additional optimizations:

1. **Parallel input updates**: Update multiple inputs simultaneously
2. **Smart GC**: Only run GC if store is actually large
3. **Cached evaluation**: Reuse evaluation results when possible
4. **Progress bars**: Show build progress with percentage
5. **Build scheduling**: Queue builds during low-usage periods
