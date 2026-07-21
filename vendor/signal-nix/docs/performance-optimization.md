# Performance Optimization Guide

This guide explains the performance optimizations built into signal-nix modules and how to configure them for optimal shell startup times.

## Overview

Signal-nix includes several optimizations to minimize shell startup latency, particularly for tools that generate configuration at runtime. The most significant optimization is **build-time caching** of expensive operations.

## Vivid LS_COLORS Caching

### The Problem

The `vivid` tool generates comprehensive `LS_COLORS` for file listings. While it provides excellent theming capabilities with hundreds of file type mappings, running `vivid generate` on every shell startup adds **20-50ms** of latency.

Traditional integration (without caching):
```nix
programs.vivid = {
  enable = true;
  enableZshIntegration = true;
}
```

This causes vivid to execute on every shell startup:
```bash
$ strace -e execve zsh -ic exit 2>&1 | grep vivid
execve("/nix/store/.../bin/vivid", ["vivid", "-m", "24-bit", "generate", "signal"], ...)
```

### The Solution: Build-Time Caching

Signal-nix implements **build-time caching** by default. The vivid output is generated once during `nix build` and stored in a file. Shell startup simply reads this cached file using `cat`, which is orders of magnitude faster.

```nix
theming.signal.cli.vivid = {
  enable = true;
  cache = true;  # Default: enabled
  enableZshIntegration = true;
};
```

### How It Works

1. **Build Time**: During `home-manager` build, vivid generates LS_COLORS and stores it:
   ```nix
   home.file.".config/vivid/ls-colors-signal".source =
     pkgs.runCommand "vivid-ls-colors-signal" {} ''
       ${pkgs.vivid}/bin/vivid -m 24-bit generate signal > $out
     '';
   ```

2. **Runtime**: Shell startup reads the pre-generated file:
   ```bash
   export LS_COLORS="$(cat $XDG_CONFIG_HOME/vivid/ls-colors-signal)"
   ```

### Performance Impact

| Configuration | First Command Lag | Improvement |
|--------------|-------------------|-------------|
| Uncached vivid | ~110-130ms | Baseline |
| Cached vivid | ~70-90ms | **20-50ms faster** |

### When to Disable Caching

Caching is enabled by default and recommended for most users. Disable it only if:

- You frequently modify vivid themes manually and need runtime regeneration
- You're debugging theme issues and want to see changes without rebuilding
- You use a vivid theme switcher script

To disable caching:
```nix
theming.signal.cli.vivid = {
  enable = true;
  cache = false;  # Use runtime generation
  enableZshIntegration = true;
};
```

## General Performance Best Practices

### 1. Shell Prompt Optimization

Even with cached colors, shell startup includes prompt initialization. The most common culprits:

- **Powerlevel10k**: ~30-40ms (tty, uname, getconf, mkfifo syscalls)
- **Oh-My-Zsh**: Can add 50-200ms depending on plugins
- **Starship**: ~15-25ms (much faster than P10k)

Consider using a simpler prompt like Starship for faster startup, or use Powerlevel10k's instant prompt feature.

### 2. Defer Non-Essential Operations

Use zsh's built-in deferred loading for tools you don't need immediately:

```nix
programs.zsh.initExtra = ''
  # Defer gpg-agent connection check
  zsh-defer gpg-connect-agent /bye
'';
```

### 3. Profile Your Shell Startup

Signal-nix works best with profiling tools to identify bottlenecks:

```bash
# Using zsh-bench
~/zsh-bench/zsh-bench

# Using strace
strace -e execve -f zsh -ic exit 2>&1 | grep execve

# Using zsh's built-in profiling
zsh -xv 2>&1 | ts -i %.s | head -50
```

### 4. Cache Other Expensive Operations

The same caching pattern used for vivid can be applied to other tools:

```nix
# Cache fzf color generation
home.file.".config/fzf/colors".text = ''
  export FZF_DEFAULT_OPTS='${generateFzfColors}'
'';

programs.zsh.initExtra = ''
  source ~/.config/fzf/colors
'';
```

## Benchmarking

To measure the impact of these optimizations:

1. **Before optimization**: Benchmark with uncached config
   ```bash
   theming.signal.cli.vivid.cache = false;
   nh home switch && exec zsh && ~/zsh-bench/zsh-bench
   ```

2. **After optimization**: Benchmark with cached config
   ```bash
   theming.signal.cli.vivid.cache = true;
   nh home switch && exec zsh && ~/zsh-bench/zsh-bench
   ```

3. **Compare results**: Look at `first_command_lag` metric

## Realistic Startup Time Goals

With all optimizations enabled:

| Shell Configuration | Target First Command Lag |
|--------------------|--------------------------|
| Minimal (bash + starship) | 20-40ms |
| Standard (zsh + starship + basic plugins) | 50-70ms |
| Full-featured (zsh + P10k + many plugins) | 80-120ms |

Signal-nix's caching optimizations help you stay in the lower end of these ranges for your chosen configuration.

## Future Optimizations

Planned improvements for signal-nix performance:

- [ ] Cache generation for fzf colors
- [ ] Cache generation for eza colors
- [ ] Compile-time color preprocessing for all modules
- [ ] Optional lazy-loading wrappers for heavy integrations
- [ ] Profile-guided optimization recommendations

## Related Documentation

- [Configuration Guide](configuration-guide.md) - General signal-nix configuration
- [Vivid Integration](vivid-ls-colors.md) - Detailed vivid module documentation
- [Shell Modules](../modules/shells/) - Shell-specific configurations

## Questions or Issues?

If you experience shell startup performance issues:

1. Run `zsh-bench` or similar profiling tools
2. Check which processes are being executed with `strace`
3. Open an issue with your benchmark results
4. Consider contributing additional optimizations!
