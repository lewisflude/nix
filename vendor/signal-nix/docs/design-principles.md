# Design Principles

Understanding what Signal does and doesn't do.

## Core Philosophy

Signal follows three fundamental principles:

### 1. Color-Only Scope

**Signal only manages colors. Nothing else.**

```nix
# ✅ Signal does this
programs.helix.settings.theme = "signal";

# ❌ Signal does NOT do this
programs.helix.enable = true;
programs.helix.settings.editor.line-number = "relative";
```

**Why?**
- Clear separation of concerns
- Predictable behavior
- No unexpected side effects
- Works alongside your existing configuration

### 2. Declarative Theming

**All color decisions are explicit and reproducible.**

```nix
# Signal's approach: Explicit, declarative
theming.signal = {
  enable = true;  # Automatically themes all enabled programs
  mode = "dark";
};

# Not Signal's approach: Imperative, hidden
# (No hidden scripts, no runtime detection)
```

**Why?**
- Reproducible builds
- Version control friendly
- Easy to understand and debug
- Nix philosophy alignment

### 3. Scientific Color Design

**Every color is calculated, not chosen aesthetically.**

- **OKLCH color space** for perceptual uniformity
- **APCA contrast** for accessibility
- **Mathematical relationships** between colors
- **Validated against standards**

**Why?**
- Consistent readability across applications
- Accessibility compliance
- Professional design quality
- Predictable color behavior

## What Signal Does

### ✅ Applies Colors

Signal generates color configuration for your applications:

```nix
# You enable programs
programs.kitty.enable = true;

# Signal applies colors
theming.signal.enable = true;

# Result: Kitty gets Signal colors
programs.kitty.settings = {
  foreground = "#c5cdd8";
  background = "#0a0d12";
  # ... more colors
};
```

### ✅ Respects Your Configuration

Signal merges with your existing settings:

```nix
programs.helix = {
  enable = true;
  settings = {
    editor = {
      line-number = "relative";  # Your setting
      cursorline = true;         # Your setting
    };
  };
};

theming.signal.editors.helix.enable = true;

# Result: Your settings + Signal colors
programs.helix.settings = {
  editor = {
    line-number = "relative";    # Preserved
    cursorline = true;           # Preserved
  };
  theme = "signal";              # Added by Signal
};
```

### ✅ Provides Consistent Colors

Same colors across all applications:

```nix
# All these get the same "error red"
- Helix error diagnostics
- Lazygit merge conflicts
- Kitty ANSI red
- GTK error dialogs
```

### ✅ Supports Light and Dark Modes

Scientifically-designed themes for both modes:

```nix
theming.signal.mode = "dark";   # Dark mode
theming.signal.mode = "light";  # Light mode
```

Both modes are equally well-designed, not adaptations.

### ✅ Works with Home Manager

Integrates seamlessly with Home Manager:

```nix
{
  imports = [ signal.homeManagerModules.default ];

  # Signal works alongside Home Manager
  programs.helix.enable = true;
  theming.signal.enable = true;
}
```

## What Signal Doesn't Do

### ❌ Doesn't Install Programs

You control program installation:

```nix
# Signal does NOT do this
programs.helix.enable = true;  # You must do this

# Signal only does this
theming.signal.editors.helix.enable = true;  # Colors only
```

### ❌ Doesn't Change Program Behavior

Signal never modifies non-color settings:

```nix
# Signal will NEVER change these
programs.helix.settings.editor.line-number = "relative";
programs.kitty.settings.font_size = 12;
programs.bat.config.pager = "less -FR";
```

### ❌ Doesn't Override Your Themes

You can disable Signal for specific programs:

```nix
theming.signal = {
  enable = true;  # autoEnable is true by default

  # Keep my custom Neovim theme
  editors.neovim.enable = false;
};
```

### ❌ Doesn't Require All-or-Nothing

Use Signal for some programs, not others:

```nix
theming.signal = {
  enable = true;
  editors.helix.enable = true;    # Use Signal
  terminals.kitty.enable = true;  # Use Signal
  # Everything else: use your own themes
};
```

### ❌ Doesn't Depend on Runtime Detection

No hidden magic or runtime detection:

```nix
# Signal does NOT do this:
# - Detect your terminal at runtime
# - Check environment variables
# - Modify behavior based on system state

# Signal IS purely declarative:
theming.signal.mode = "dark";  # Explicit, reproducible
```

## Design Patterns

### Pattern: Separation of Concerns

**Program Management (You)**
```nix
programs = {
  helix.enable = true;
  kitty.enable = true;
  bat.enable = true;
};
```

**Color Management (Signal)**
```nix
theming.signal = {
  enable = true;  # Automatically themes all enabled programs
  mode = "dark";
};
```

### Pattern: Explicit Over Implicit

**Good: Explicit mode**
```nix
theming.signal.mode = "dark";  # Clear intent
```

**Avoid: Implicit assumptions**
```nix
# Signal doesn't guess or detect
# You must explicitly set the mode
```

### Pattern: Composable Configuration

**Layer your configuration:**

```nix
# Base configuration
imports = [ ./base.nix ];

# Program installation
programs.helix.enable = true;

# Program configuration
programs.helix.settings = { /* your settings */ };

# Color theming
theming.signal.editors.helix.enable = true;
```

Each layer is independent and composable.

## Architecture Decisions

### Why Home Manager?

- **User-level theming** - Colors belong to user config
- **Cross-platform** - Works on NixOS, nix-darwin, standalone
- **Rich ecosystem** - Many programs already have modules
- **Declarative** - Fits Nix philosophy

### Why Separate signal-palette?

- **Platform-agnostic** - Use Signal colors outside Nix
- **Stable versioning** - Colors version independently
- **Reusability** - Other projects can use Signal colors
- **Single source of truth** - Colors defined once

### Why autoEnable defaults to true?

- **Reduces boilerplate** - Don't repeat yourself
- **Sensible default** - "Theme my programs" is the common use case
- **Still flexible** - Can disable specific programs or opt-out entirely
- **Zero-config** - Works immediately for most users

### Why Not Runtime Detection?

- **Reproducibility** - Same config = same result
- **Debuggability** - No hidden behavior
- **Nix philosophy** - Declarative, not imperative
- **Simplicity** - Easier to understand and maintain

## Comparison with Other Themes

### Signal vs Traditional Themes

| Aspect | Signal | Traditional Themes |
|--------|--------|-------------------|
| **Color Selection** | Calculated (OKLCH, APCA) | Aesthetic choices |
| **Consistency** | Mathematically guaranteed | Best effort |
| **Accessibility** | APCA-validated | Varies |
| **Light Mode** | Equally designed | Often adapted |
| **Platform** | Nix-first | Generic |
| **Scope** | Colors only | Often includes fonts, icons, etc. |

### Signal vs Catppuccin-nix

| Aspect | Signal | Catppuccin-nix |
|--------|--------|----------------|
| **Philosophy** | Scientific | Aesthetic |
| **Colors** | OKLCH-based | RGB-based |
| **Accessibility** | APCA standards | Visual appeal |
| **Approach** | Calculated | Curated |
| **Variants** | Light/Dark | 4 flavors + light/dark |

Both are excellent. Choose based on your priorities:
- **Signal** - Science, accessibility, consistency
- **Catppuccin** - Aesthetics, warmth, community

## Best Practices

### Do: Use the default behavior

```nix
theming.signal = {
  enable = true;  # Automatic theming enabled by default
  mode = "dark";
};
```

Disable specific programs as needed using `<app>.enable = false`.

### Do: Keep Signal Updated

```bash
nix flake update signal
```

Get the latest color improvements and bug fixes.

### Do: Report Color Issues

If a color is hard to read or looks wrong, report it. Signal's colors are scientifically designed but may need adjustments.

### Don't: Mix Color Sources

```nix
# Avoid mixing Signal with other themes
theming.signal.editors.helix.enable = true;
programs.helix.settings.theme = "gruvbox";  # Conflicts!
```

Choose one theme system per program.

### Don't: Hardcode Colors

```nix
# Don't do this
programs.kitty.settings.foreground = "#c5cdd8";

# Do this
theming.signal.terminals.kitty.enable = true;
```

Let Signal manage colors.

### Don't: Expect Non-Color Changes

Signal only changes colors. For other customizations, use standard Home Manager options.

## Future Directions

### Planned Features

- **Auto mode** - Detect system theme preference
- **Theme variants** - High contrast, color-blind friendly
- **More applications** - Expanding support
- **Color customization** - Override specific colors

### Not Planned

- **Font management** - Use Home Manager's font options
- **Icon themes** - Use GTK/Qt icon options
- **Window decorations** - Use WM-specific options
- **Program installation** - Use Home Manager's program options

## Contributing

When contributing to Signal, follow these principles:

1. **Colors only** - Don't change non-color settings
2. **Use semantic bridge** - Don't hardcode colors
3. **Test both modes** - Light and dark
4. **Follow tier system** - Use highest available tier
5. **Document your work** - Clear comments and metadata

See [CONTRIBUTING.md](../CONTRIBUTING.md) for details.

## Questions?

- **"Why doesn't Signal install programs?"** - Separation of concerns. You control installation, Signal handles colors.
- **"Can I use Signal with other themes?"** - Yes, disable Signal for specific programs.
- **"Why OKLCH instead of HSL?"** - Perceptual uniformity. HSL doesn't match human perception.
- **"Is Signal opinionated?"** - About colors: yes. About everything else: no.

## Next Steps

- **[Architecture](architecture.md)** - How Signal works internally
- **[Configuration Guide](configuration-guide.md)** - All configuration options
- **[Contributing](../CONTRIBUTING.md)** - Add new applications
- **[Signal Palette Philosophy](https://github.com/lewisflude/signal-palette/blob/main/docs/philosophy.md)** - Color system design
