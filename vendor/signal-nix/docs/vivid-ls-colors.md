# Vivid Integration: Modern LS_COLORS with Signal

This guide explains Signal's vivid integration and how it improves upon the legacy ls-colors module.

## What is vivid?

[Vivid](https://github.com/sharkdp/vivid) is a modern LS_COLORS generator that provides:

- **Comprehensive file type database**: 400+ file extensions vs ~150 in ls-colors
- **RGB hex color themes**: Uses `#RRGGBB` colors with automatic terminal translation
- **Flexible architecture**: Separates file types from themes (YAML-based)
- **Industry standard**: Used by fd, eza, tree, bfs, dust, and many other tools
- **Active maintenance**: Regular updates with new file types

## Signal's Vivid Integration

Signal generates a custom vivid theme from the Signal color palette at build time:

```nix
{
  theming.signal = {
    enable = true;
    cli.vivid = {
      enable = true;
      colorMode = "24-bit";  # or "8-bit" for older terminals

      # Cache output for faster shell startup (default: true)
      # Saves ~20-50ms per shell startup
      cache = true;

      # Automatic shell integration
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
    };
  };
}
```

### Performance: Build-Time Caching

By default, Signal caches the vivid output at build time, improving shell startup performance:

- **With caching (default)**: LS_COLORS is generated once during `nix build` and stored in a file
- **Without caching**: vivid runs on every shell startup, adding 20-50ms of latency

See [Performance Optimization Guide](performance-optimization.md) for details.

## Color Mapping

Signal maps its functional colors to vivid's theme structure:

| Vivid Category | Signal Color | Purpose |
|----------------|--------------|---------|
| `directory` | `primary` | Directories (bold) |
| `symlink` | `cyan` | Symbolic links |
| `executable_file` | `success` | Executable files |
| `archives` | `warning` | Compressed files (.zip, .tar.gz, etc.) |
| `media.image` | `categorical5` | Image files (.png, .jpg, etc.) |
| `media.video` | `categorical6` | Video files (.mp4, .mkv, etc.) |
| `media.audio` | `categorical4` | Audio files (.mp3, .flac, etc.) |
| `text` | `info` | Documents (.pdf, .doc, etc.) |
| `programming` | `secondary` | Source code files |
| `broken_symlink` | `error` | Broken symbolic links |

## Comparison: vivid vs ls-colors

### File Type Coverage

**vivid (400+ types):**
- Comprehensive programming languages (Rust, Go, TypeScript, Haskell, etc.)
- Modern formats (webp, avif, zstd, wasm, etc.)
- Development tools (Dockerfile, .gitignore, package.json, etc.)
- Specialized formats (CAD, 3D models, databases, etc.)

**ls-colors (~150 types):**
- Basic archives, images, videos, audio
- Common programming languages
- Standard documents

### Theme System

**vivid:**
```yaml
colors:
  primary: "5a7dcf"
  success: "4ade80"

core:
  directory:
    foreground: "primary"
    font-style: "bold"
```
- RGB hex colors
- Hierarchical YAML structure
- Easy to customize and maintain

**ls-colors:**
```nix
"di" = "01;34";  # directory - bold blue
"ex" = "01;32";  # executable - bold green
```
- ANSI escape codes
- Flat key-value pairs
- Harder to modify

### Terminal Compatibility

**vivid:**
- Automatic detection of terminal capabilities
- Can output both 24-bit and 8-bit color codes
- Graceful degradation for older terminals

**ls-colors:**
- Fixed 8-bit ANSI codes only
- No automatic terminal detection

## Migration from ls-colors

If you're currently using the ls-colors module:

### Before (deprecated)
```nix
{
  theming.signal = {
    enable = true;
    cli.ls-colors.enable = true;
  };
}
```

### After (recommended)
```nix
{
  theming.signal = {
    enable = true;
    cli.vivid.enable = true;
  };
}
```

### Shell Integration

With vivid, you get automatic shell integration:

**Bash/Zsh (with caching enabled - default):**
```bash
# Automatically added when enableBashIntegration = true
# Reads from pre-generated cache for fast startup
export LS_COLORS="$(cat $XDG_CONFIG_HOME/vivid/ls-colors-signal)"
```

**Bash/Zsh (without caching):**
```bash
# Generates LS_COLORS at runtime (slower)
export LS_COLORS="$(vivid generate signal)"
```

**Fish (with caching enabled - default):**
```fish
# Automatically added when enableFishIntegration = true
set -gx LS_COLORS (cat $XDG_CONFIG_HOME/vivid/ls-colors-signal)
```

**Fish (without caching):**
```fish
# Generates LS_COLORS at runtime (slower)
set -gx LS_COLORS (vivid generate signal)
```

## Advanced Usage

### 8-bit Color Mode

For terminals without true color support:

```nix
{
  theming.signal.cli.vivid = {
    enable = true;
    colorMode = "8-bit";  # 256 color mode
  };
}
```

### Selective Shell Integration

Enable only for specific shells:

```nix
{
  theming.signal.cli.vivid = {
    enable = true;
    enableBashIntegration = false;  # Manually manage in bash
    enableZshIntegration = true;    # Auto-enable in zsh
    enableFishIntegration = true;   # Auto-enable in fish
  };
}
```

### Using with autoEnable

When using `autoEnable`, vivid is automatically enabled:

```nix
{
  theming.signal = {
    enable = true;
    autoEnable = true;  # Enables vivid automatically
  };

  # Override vivid settings if needed
  theming.signal.cli.vivid.colorMode = "8-bit";
}
```

## Tools That Use LS_COLORS

When vivid is enabled, these tools automatically use Signal colors:

- **ls** - Standard directory listing
- **tree** - Directory tree visualization
- **fd** - Fast file finder (alternative to find)
- **bfs** - Breadth-first file search
- **dust** - Disk usage visualization
- **eza** - Modern ls replacement (also uses EZA_COLORS)
- **Shell completions** - File type colors in bash/zsh/fish completion menus
- **File managers** - Many TUI file managers respect LS_COLORS

## Troubleshooting

### Colors not showing

1. **Check LS_COLORS is set:**
   ```bash
   echo $LS_COLORS
   ```
   Should show a long string of color codes.

2. **Verify shell integration:**
   ```bash
   # Should show vivid is installed
   which vivid

   # Test color output
   vivid generate signal
   ```

3. **Test terminal true color support:**
   ```bash
   # If this shows gradients, your terminal supports 24-bit color
   vivid -m 24-bit generate signal | head -n 5
   ```

### Cache not working

If you're experiencing slow shell startup despite caching being enabled:

1. **Verify cache file exists:**
   ```bash
   ls -lh ~/.config/vivid/ls-colors-signal
   cat ~/.config/vivid/ls-colors-signal | head -c 100
   ```
   Should show a file with ANSI color codes.

2. **Check shell integration:**
   ```bash
   # For Zsh/Bash
   grep "vivid" ~/.zshrc ~/.bashrc

   # Should show either:
   # - "cat ...vivid/ls-colors-signal" (cached)
   # - "vivid generate signal" (uncached)
   ```

3. **Profile shell startup:**
   ```bash
   # Use strace to see what's being executed
   strace -e execve zsh -ic exit 2>&1 | grep -E "(vivid|cat)"

   # With caching: should only see "cat"
   # Without caching: will see "vivid" executable
   ```

4. **Force cache rebuild:**
   ```bash
   # Rebuild home-manager configuration
   nh home switch
   # Or: home-manager switch

   # Verify the file was updated
   ls -l ~/.config/vivid/ls-colors-signal
   ```

### Using custom vivid themes

Signal's vivid module generates a `signal` theme automatically, but you can use any vivid theme:

```nix
{
  programs.vivid = {
    enable = true;
    # Use built-in vivid theme instead of Signal theme
    activeTheme = "molokai";  # or "snazzy", "ayu", etc.
  };
}
```

Note: This bypasses Signal's theme integration.

## Why Deprecate ls-colors?

The ls-colors module served its purpose but has fundamental limitations:

1. **Maintenance burden**: Adding new file types requires manual ANSI code management
2. **Limited coverage**: Can't keep up with vivid's comprehensive database
3. **No RGB colors**: Stuck with 8-bit ANSI codes
4. **Less flexible**: Flat structure vs vivid's hierarchical themes

Vivid provides a superior foundation for file type coloring while maintaining full Signal integration.

## See Also

- [vivid GitHub repository](https://github.com/sharkdp/vivid)
- [Example configuration](../examples/vivid-ls-colors.nix)
- [Signal color palette documentation](https://github.com/lewisflude/signal-palette)
