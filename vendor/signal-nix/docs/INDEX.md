# Signal Documentation Index

Complete documentation index for the Signal Nix theming system.

---

## Quick Start

| Need | Document | Description |
|------|----------|-------------|
| **Install Signal** | [Getting Started](getting-started.md) | Setup for NixOS, nix-darwin, Home Manager |
| **Configure Signal** | [Configuration Guide](configuration-guide.md) | All configuration options |
| **Real Examples** | [Examples](../examples/) | Working configurations |
| **Fix Issues** | [Troubleshooting](troubleshooting.md) | Common problems and solutions |

---

## Documentation by Audience

### 🎯 For Users

#### Getting Started
- **[Getting Started](getting-started.md)** - Installation and setup
- **[Configuration Guide](configuration-guide.md)** - Complete options reference
- **[NixOS Modules](nixos-modules.md)** - System-level theming (boot, login, console)

#### Using Signal
- **[Theming Reference](theming-reference.md)** - All 64 supported applications
- **[Vivid Integration](vivid-ls-colors.md)** - Modern LS_COLORS (400+ file types)
- **[Performance Optimization](performance-optimization.md)** - Shell startup optimization
- **[Troubleshooting](troubleshooting.md)** - Common issues and solutions
- **[Examples](../examples/)** - Real-world configurations

#### Understanding Signal
- **[Architecture](architecture.md)** - How Signal works internally
- **[Design Principles](design-principles.md)** - What Signal does and doesn't do
- **[Color System Overview](color-system-overview.md)** - Signal's color system
- **[Advanced Usage](advanced-usage.md)** - Power user features

### 👨‍💻 For Contributors

#### Contributing
- **[Contributing Guide](../CONTRIBUTING.md)** - How to contribute
- **[Application Guide](../CONTRIBUTING_APPLICATIONS.md)** - Adding new applications (step-by-step)
- **[Tier System](tier-system.md)** - Configuration method hierarchy

#### Development
- **[Semantic Bridge Guide](semantic-bridge-guide.md)** - Using Signal colors in modules
- **[Signal Palette Integration](signal-palette-integration.md)** - How colors are imported
- **[Ironbar Integration](ironbar-integration.md)** - Ironbar theming
- **[Notifications Integration](notifications-integration.md)** - Complete notification styling
- **[Testing Guide](TESTING_GUIDE.md)** - Running and writing tests
- **[Syntax Validation](SYNTAX_VALIDATION.md)** - Preventing syntax errors

---

## Signal Palette Documentation

**Source of Truth:** All color specifications are defined in the [signal-palette repository](https://github.com/lewisflude/signal-palette).

| Document | Description |
|----------|-------------|
| [Philosophy](https://github.com/lewisflude/signal-palette/blob/main/docs/philosophy.md) | Design principles and reasoning |
| [OKLCH Explained](https://github.com/lewisflude/signal-palette/blob/main/docs/oklch-explained.md) | Color space explanation |
| [Accessibility](https://github.com/lewisflude/signal-palette/blob/main/docs/accessibility.md) | APCA contrast standards |
| [Technical Specification](https://github.com/lewisflude/signal-palette/blob/main/docs/technical-specification.md) | Mathematical constraints |
| [Color System Reference](https://github.com/lewisflude/signal-palette/blob/main/docs/color-system-reference.md) | Complete palette guide |
| [Semantic Bridge](https://github.com/lewisflude/signal-palette/blob/main/docs/semantic-bridge.md) | UI concept mappings |

---

## By Use Case

### "I want to install Signal"
1. [Getting Started](getting-started.md) - Choose your platform
2. [Configuration Guide](configuration-guide.md) - Configure Signal
3. [Examples](../examples/) - See real configurations

### "I want to theme a specific application"
1. [Theming Reference](theming-reference.md) - Check if supported
2. [Configuration Guide](configuration-guide.md) - Enable theming
3. [Troubleshooting](troubleshooting.md) - Fix issues

### "I want to theme system components (NixOS)"
1. [NixOS Modules](nixos-modules.md) - System-level theming
2. [Examples](../examples/nixos-complete.nix) - Complete example

### "I want to understand how Signal works"
1. [Design Principles](design-principles.md) - Philosophy
2. [Architecture](architecture.md) - Internal workings
3. [Color System Overview](color-system-overview.md) - Color system
4. [Signal Palette Philosophy](https://github.com/lewisflude/signal-palette/blob/main/docs/philosophy.md) - Deep dive

### "I want to add a new application"
1. [Application Guide](../CONTRIBUTING_APPLICATIONS.md) - Step-by-step instructions
2. [Tier System](tier-system.md) - Choose configuration method
3. [Semantic Bridge Guide](semantic-bridge-guide.md) - Access colors
4. [Testing Guide](TESTING_GUIDE.md) - Write tests

### "I want to optimize shell startup performance"
1. [Performance Optimization](performance-optimization.md) - Shell startup optimization
2. [Vivid Integration](vivid-ls-colors.md) - Caching configuration
3. [Configuration Guide](configuration-guide.md) - Fine-tune settings

### "I'm having issues"
1. [Troubleshooting](troubleshooting.md) - Common issues
2. [GitHub Issues](https://github.com/lewisflude/signal-nix/issues) - Report bugs
3. [Examples](../examples/) - Working configurations

---

## Quick Reference

### Basic Configuration

```nix
{
  imports = [ signal.homeManagerModules.default ];

  theming.signal = {
    enable = true;
    autoEnable = true;  # Automatically theme all enabled programs
    mode = "dark";      # "light", "dark", or "auto"
  };

  programs = {
    helix.enable = true;
    kitty.enable = true;
    bat.enable = true;
  };
}
```

### Using Colors in Modules

```nix
{ signalLib, semantic, ... }:

let
  mode = signalLib.resolveThemeMode cfg.mode;  # "light" or "dark"
in {
  background = (semantic.core "background" mode).hex;
  foreground = (semantic.core "foreground" mode).hex;
  error = (semantic.status "error" mode).hex;
  success = (semantic.status "success" mode).hex;
}
```

See [Semantic Bridge Guide](semantic-bridge-guide.md) for complete reference.

---

## Documentation Conventions

### Code Examples
- **Nix syntax** for configuration
- **Bash** for command-line operations
- **Comments** to explain non-obvious code

### File Paths
- Relative: `docs/getting-started.md`
- Absolute: `/etc/nixos/configuration.nix`
- Home: `~/.config/helix/config.toml`

### Placeholders
- `yourusername` - Your username
- `yourhostname` - Your hostname
- `<app>` - Application name

---

## Getting Help

### Documentation Issues
If you find documentation issues:
1. Check if already reported on [GitHub Issues](https://github.com/lewisflude/signal-nix/issues)
2. Open a new issue with the `documentation` label

### Questions
For questions:
1. Check [Troubleshooting](troubleshooting.md)
2. Search [existing issues](https://github.com/lewisflude/signal-nix/issues)
3. Open a new issue with the `question` label

### Contributing to Docs
To improve documentation:
1. Fork the repository
2. Edit documentation in `docs/`
3. Submit a pull request with `documentation` label

See [Contributing Guide](../CONTRIBUTING.md) for details.

---

## Documentation Status

### Complete ✅
- User guides (Getting Started, Configuration, NixOS Modules)
- Technical documentation (Architecture, Design Principles)
- Contributor guides (Contributing, Application Guide)
- Testing documentation (Testing Guide, Syntax Validation)
- Reference documentation (Theming Reference, Semantic Bridge Guide)

### Maintained 🔄
- Examples (updated as new applications added)
- Theming Reference (updated with new applications)
- Troubleshooting (updated with common issues)

---

**Last Updated:** 2026-01-21
**Documentation Version:** 1.0.1
