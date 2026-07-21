# Contributing to Signal Design System

Thank you for your interest in contributing to Signal! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Application Integration Guide](#application-integration-guide)
- [Philosophy Guidelines](#philosophy-guidelines)

## Code of Conduct

By participating in this project, you agree to maintain a respectful, inclusive, and welcoming environment for all contributors. We follow the principles of:

- **Respect**: Treat all contributors with respect and professionalism
- **Inclusivity**: Welcome contributors of all skill levels and backgrounds
- **Collaboration**: Work together constructively to improve the project
- **Quality**: Prioritize code quality, documentation, and user experience

## Getting Started

### Prerequisites

- **Nix**: Install Nix with flakes enabled ([DeterminateSystems installer](https://github.com/DeterminateSystems/nix-installer) recommended)
- **Git**: Basic familiarity with Git and GitHub
- **Nix Language**: Understanding of Nix syntax and module system
- **Home Manager**: Familiarity with Home Manager configuration (helpful but not required)

### Useful Resources

- [Nix Pills](https://nixos.org/guides/nix-pills/) - Learn Nix fundamentals
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - NixOS documentation
- [Home Manager Manual](https://nix-community.github.io/home-manager/) - Home Manager docs
- [Signal Philosophy](https://github.com/lewisflude/signal-palette/blob/main/docs/philosophy.md) - Our design principles
- [OKLCH Explained](https://github.com/lewisflude/signal-palette/blob/main/docs/oklch-explained.md) - Color space overview

## Development Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/signal-nix.git
cd signal-nix

# Add upstream remote
git remote add upstream https://github.com/lewisflude/signal-nix.git
```

### 2. Set Up Git Hooks

```bash
# Configure Git to use project hooks
git config core.hooksPath .githooks

# Verify hooks are executable
chmod +x .githooks/*
```

This enables:
- **Pre-commit**: Syntax validation before each commit
- **Commit-msg**: Conventional commits validation

### 3. Enter Development Environment

```bash
# Enter the development shell with all tools
nix develop

# Or use direnv for automatic loading
echo "use flake" > .envrc
direnv allow
```

The development shell includes:
- `nixfmt-rfc-style` - Code formatter
- `statix` - Nix linter
- `deadnix` - Dead code detection
- `nil` - Nix language server

### 4. Test Your Setup

```bash
# Check flake validity
nix flake check

# Format code
nix fmt

# Run linters
statix check .
deadnix .
```

## How to Contribute

### Types of Contributions

We welcome various types of contributions:

1. **🐛 Bug Fixes**: Fix issues in existing integrations
2. **✨ New Applications**: Add support for new applications
3. **📚 Documentation**: Improve docs, guides, and examples
4. **🎨 Color Refinements**: Improve color tokens (requires accessibility validation)
5. **♻️ Refactoring**: Improve code quality and maintainability
6. **⚡ Performance**: Optimize module evaluation or build times
7. **✅ Testing**: Add tests or improve CI/CD

### Finding Work

- Check [Issues](https://github.com/lewisflude/signal-nix/issues) for open tasks
- Look for issues labeled `good first issue` or `help wanted`
- Browse [Discussions](https://github.com/lewisflude/signal-nix/discussions) for ideas
- Propose new features or applications (create an issue first)

## Coding Standards

### Nix Style Guide

We follow the [RFC 166](https://github.com/NixOS/rfcs/blob/master/rfcs/0166-nix-formatting.md) formatting style:

```nix
# Good: Consistent formatting
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options = {
    myOption = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable my option";
    };
  };
}

# Bad: Inconsistent formatting
{ config, lib, pkgs, ... }:
{
options = {
  myOption = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable my option"; };
};
}
```

**Key principles:**
- Use 2 spaces for indentation
- Format with `nix fmt` before committing
- Keep lines under 100 characters when possible
- Use descriptive variable names
- Add comments for complex logic

### Module Structure

Follow this structure for new application modules:

```nix
# modules/category/app-name.nix
{
  config,
  lib,
  pkgs,
  palette,  # Signal palette
  ...
}:

let
  cfg = config.theming.signal.category.appName;
  inherit (lib) mkOption mkEnableOption mkIf types;
in
{
  options.theming.signal.category.appName = {
    enable = mkEnableOption "Signal theme for AppName";
    
    # Add application-specific options here
  };

  config = mkIf cfg.enable {
    # Configuration goes here
  };
}
```

### File Organization

```
signal-nix/
├── modules/
│   ├── common/           # Core module system
│   ├── desktop/          # Desktop applications (launchers, bars, etc.)
│   ├── editors/          # Text and code editors
│   ├── terminals/        # Terminal emulators and multiplexers
│   ├── cli/              # Command-line tools
│   ├── gtk/              # GTK theming
│   └── ironbar/          # Ironbar (complex, gets own directory)
├── lib/                  # Library functions
├── examples/             # Example configurations
└── docs/                 # Documentation
```

## Testing

Signal uses a comprehensive testing approach with both unit and integration tests.

> **📖 For detailed testing guidance, see [docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md)**

### Quick Testing Commands

```bash
# Run all tests
nix flake check

# Run specific test
nix build .#checks.x86_64-linux.unit-lib-resolveThemeMode

# Use the test runner script
./run-tests.sh --all           # All tests
./run-tests.sh --category unit # Unit tests only
./run-tests.sh test-name       # Specific test
./run-tests.sh --list          # List all tests
```

### Test Types

**Unit Tests** (`tests/unit/`) - Fast, pure Nix tests for library functions  
**Integration Tests** (`tests/integration/`) - Module validation and example checks

See [TESTING_GUIDE.md](docs/TESTING_GUIDE.md) for:
- When to use each test type
- Writing tests for new modules
- Test templates and examples
- Debugging test failures

### Local Testing

1. **Test module evaluation:**
   ```bash
   nix eval .#homeManagerModules.default
   ```

2. **Test with example configs:**
   ```bash
   nix eval --expr 'import ./examples/basic.nix'
   ```

3. **Build with Home Manager:**
   ```bash
   # Add to your home-manager config temporarily
   home-manager switch --flake .
   ```

4. **Test all examples:**
   ```bash
   for example in examples/*.nix; do
     echo "Testing $example..."
     nix-instantiate --parse "$example" > /dev/null || exit 1
   done
   ```

### CI Testing

All PRs are automatically tested with GitHub Actions:

- ✅ Flake checks on all platforms
- ✅ Format validation
- ✅ Linting (statix, deadnix)
- ✅ Example builds
- ✅ Unit and integration tests
- ✅ Module structure validation
- ✅ Module evaluation

View CI results in the "Actions" tab of your PR.

## Submitting Changes

### 1. Create a Branch

```bash
# Update your fork
git checkout main
git pull upstream main

# Create a feature branch
git checkout -b feature/my-new-feature
# or
git checkout -b fix/issue-123
```

Branch naming conventions:
- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation changes
- `refactor/description` - Code refactoring

### 2. Make Your Changes

```bash
# Make changes
$EDITOR modules/editors/my-editor.nix

# Format code
nix fmt

# Run linters
statix check .
deadnix .

# Test changes
nix flake check
```

### 3. Commit Your Changes

Write clear, descriptive commit messages:

```bash
# Good commit messages
git commit -m "feat: add helix editor integration"
git commit -m "fix: correct gtk theme colors in light mode"
git commit -m "docs: add troubleshooting guide for ironbar"

# Commit message format
<type>: <description>

Types: feat, fix, docs, style, refactor, test, chore
```

For larger changes, use a detailed commit message:

```
feat: add zellij terminal multiplexer support

- Add zellij module with Signal color scheme
- Support both dark and light modes
- Include keybinding theme integration
- Add example configuration to docs

Closes #123
```

### 4. Push and Create Pull Request

```bash
# Push to your fork
git push origin feature/my-new-feature

# Create PR on GitHub
# Fill out the PR template completely
```

### 5. Respond to Feedback

- Be responsive to review comments
- Make requested changes promptly
- Update your PR with new commits or force-push if needed
- Ask questions if feedback is unclear

## Application Integration Guide

### 🎯 NEW: Step-by-Step Application Guide

**Want to add a new application to Signal?** We have a comprehensive guide just for you!

📖 **[CONTRIBUTING_APPLICATIONS.md](CONTRIBUTING_APPLICATIONS.md)** - Complete step-by-step guide for adding applications

This guide includes:
- ✅ Detailed walkthrough from research to submission
- ✅ Decision tree for choosing the right configuration tier
- ✅ Example implementations for each tier
- ✅ Testing checklist and common pitfalls
- ✅ Pull request template and best practices

**Perfect for first-time contributors!**

### Using Module Templates (Recommended)

**Module templates make it easy** to add new applications with consistent structure:

- **[Template Directory](templates/)**: Four ready-to-use templates (one per tier)
- **[Template README](templates/README.md)**: Complete guide with tier selection, usage instructions, and best practices

**Quick Start:**
```bash
# 1. Copy the appropriate template
cp templates/tier-3-freeform-settings.nix modules/terminals/my-terminal.nix

# 2. Fill in placeholders (marked with UPPERCASE_PLACEHOLDER)
# 3. Implement color mapping
# 4. Test and submit!
```

Available templates:
- `tier-1-native-theme.nix` - For apps with native theme support
- `tier-2-structured-colors.nix` - For apps with structured color options
- `tier-3-freeform-settings.nix` - For apps with freeform settings
- `tier-4-raw-config.nix` - For apps requiring raw config generation

### Integration Standards

**Before adding any new application**, review these key documents:

- **[Application Contribution Guide](CONTRIBUTING_APPLICATIONS.md)**: Complete step-by-step guide (START HERE!)
- **[Module Templates](templates/README.md)**: Ready-to-use templates for all tiers
- **[Tier System](docs/tier-system.md)**: Four-tier configuration hierarchy (native themes → raw config)
- **[Integration Roadmap](docs/integration-standards.md)**: Programs to integrate and their priority
- **Module Metadata**: Required documentation standard (see templates or guide)

### Quick Integration Checklist

Use this condensed checklist when adding a new application. For detailed explanations, see [Integration Standards](docs/integration-standards.md).

#### 1. Research Phase

- [ ] Identify config format (TOML, YAML, JSON, etc.)
- [ ] Locate config file paths
- [ ] Review upstream theming documentation
- [ ] Check Home-Manager source for existing module
- [ ] Note stable/current version

#### 2. Determine Configuration Method (Tier)

**Check in priority order** (see [Tier System](docs/tier-system.md) for details):

- [ ] **Tier 1**: Native theme options (`programs.X.themes`)
  - If exists → **USE THIS** (best)
- [ ] **Tier 2**: Structured color options (`programs.X.colors`)
  - If exists → **USE THIS** (good)
- [ ] **Tier 3**: Freeform settings attrset (`programs.X.settings`)
  - If exists → **USE THIS** (acceptable)
- [ ] **Tier 4**: Raw config strings (last resort only)
  - Document why no better option exists

#### 3. Implementation Phase

- [ ] Create module in appropriate `modules/category/`
- [ ] **Add metadata comment block** (see template below)
- [ ] Map Signal colors to app schema
- [ ] Implement dark and light modes
- [ ] Use `signalLib.shouldThemeApp` for conditional theming
- [ ] Format with `nix fmt`
- [ ] Check with `statix check` and `deadnix`

**Metadata Template** (required at top of every module):

```nix
{
  config,
  lib,
  signalColors,
  signalLib,
  ...
}:
# CONFIGURATION METHOD: <native-theme|structured-colors|freeform-settings|raw-config>
# HOME-MANAGER MODULE: programs.<app>.<option>
# UPSTREAM SCHEMA: <url-to-official-docs>
# SCHEMA VERSION: <version-number>
# LAST VALIDATED: <YYYY-MM-DD>
# NOTES: <why-this-tier-chosen, any-caveats>
let
  # ... implementation
```

#### 4. Testing Phase

- [ ] Evaluate: `nix eval .#homeManagerModules.default`
- [ ] Visual test: dark mode
- [ ] Visual test: light mode
- [ ] Check application logs for errors
- [ ] Verify accessibility (contrast)
- [ ] Test on target platforms

#### 5. Documentation & Integration

- [ ] Update `modules/common/default.nix` imports
- [ ] Create example in `examples/`
- [ ] Update README.md with app listing
- [ ] Add screenshots if visual
- [ ] Update CHANGELOG.md
- [ ] Run `nix flake check`

### Adding a New Application (Detailed)

#### Quick Start with mkAppModule Helpers (Recommended)

**NEW**: Signal provides `mkAppModule` helpers that reduce boilerplate by ~25%. Use these for new modules:

```nix
# modules/terminals/my-terminal.nix
{
  config,
  lib,
  signalColors,
  signalLib,
  ...
}:
# CONFIGURATION METHOD: freeform-settings (Tier 3)
# HOME-MANAGER MODULE: programs.myTerminal.settings
# UPSTREAM SCHEMA: https://example.com/my-terminal/config
# SCHEMA VERSION: 1.0.0
# LAST VALIDATED: 2026-01-18
# NOTES: Uses mkTier3Module helper for reduced boilerplate
let
  # Use standard color helpers
  ansiColors = signalLib.makeAnsiColors signalColors;
  uiColors = signalLib.makeUIColors signalColors;
in
signalLib.mkTier3Module {
  appName = "myTerminal";
  category = [ "terminals" ];
  
  settingsGenerator = _: {
    foreground = uiColors.text-primary.hex;
    background = uiColors.surface-base.hex;
    cursor = uiColors.accent-secondary.hex;
    
    # ANSI colors
    color0 = ansiColors.black.hex;
    color1 = ansiColors.red.hex;
    # ... etc
  };
}
```

**Available Helpers:**

- `mkTier3Module` - For `programs.<app>.settings` (most common)
- `mkTier2Module` - For structured color options
- `mkTier4Module` - For raw config strings
- `makeAnsiColors` - Standard 16-color ANSI palette
- `makeUIColors` - Common UI colors (surface, text, accent, semantic)

**Benefits:**
- ✅ 20-30% less boilerplate code
- ✅ Automatic theme activation logic
- ✅ Consistent patterns across modules
- ✅ Standard color mapping helpers
- ✅ Less maintenance burden

See `templates/README.md` for full documentation and examples.

#### Manual Implementation (Advanced)

For complex cases requiring custom logic, you can still implement modules manually:

#### 1. Research the Application

- **Configuration format**: TOML, YAML, JSON, etc.
- **Config location**: Where does it store its config?
- **Theming support**: How does it handle colors?
- **Platform support**: Linux, macOS, or both?
- **Home Manager**: Does a module already exist? What options?

#### 2. Create the Module

Create a new file in the appropriate category:

```nix
# modules/editors/my-editor.nix
{
  config,
  lib,
  pkgs,
  palette,
  ...
}:

let
  cfg = config.theming.signal.editors.myEditor;
  inherit (lib) mkOption mkEnableOption mkIf types;
  
  # Access palette colors
  colors = palette.${config.theming.signal.mode};
in
{
  options.theming.signal.editors.myEditor = {
    enable = mkEnableOption "Signal theme for MyEditor";
  };

  config = mkIf cfg.enable {
    programs.myEditor = {
      enable = true;
      settings = {
        colors = {
          foreground = colors.text.primary;
          background = colors.surface.primary;
          # ... more colors
        };
      };
    };
  };
}
```

#### 3. Color Mapping Strategy

Map Signal's semantic colors to the application's color scheme:

**UI Elements:**
- `colors.surface.primary` → Background
- `colors.surface.secondary` → Secondary background
- `colors.surface.tertiary` → Tertiary background
- `colors.text.primary` → Foreground text
- `colors.text.secondary` → Dimmed text
- `colors.border.subtle` → Borders

**Syntax Highlighting (Editors):**
- `colors.syntax.keyword` → Keywords
- `colors.syntax.function` → Functions
- `colors.syntax.string` → Strings
- `colors.syntax.comment` → Comments
- `colors.syntax.constant` → Constants

**Status:**
- `colors.status.success` → Success/OK
- `colors.status.warning` → Warnings
- `colors.status.danger` → Errors
- `colors.status.info` → Info

#### 4. Add to Main Module

Update `modules/common/default.nix` to include your module:

```nix
imports = [
  # ... existing imports
  ../editors/my-editor.nix
];
```

#### 5. Create an Example

Add an example to `examples/`:

```nix
# examples/my-editor-example.nix
{
  theming.signal = {
    enable = true;
    mode = "dark";
    
    editors.myEditor.enable = true;
  };
}
```

#### 6. Document It

Update the README:

```markdown
### Editors

- **Helix** - Modern modal editor
- **MyEditor** - Your editor description
```

#### 7. Test Thoroughly

- Test in both dark and light modes
- Test on Linux and macOS (if applicable)
- Verify all colors are correct
- Check for regressions in other modules

#### 8. Submit PR

Create a PR with:
- The module file
- Example configuration
- README updates
- Screenshots (if visual changes)

### Color Selection Guidelines

When mapping colors, follow these principles:

1. **Semantic meaning**: Use colors that match their semantic purpose
2. **Consistency**: Similar elements should use similar colors across apps
3. **Accessibility**: Ensure sufficient contrast (APCA standards)
4. **Hierarchy**: Use the palette's built-in hierarchy (primary > secondary > tertiary)

**Example mapping:**

```nix
# Good: Semantic and hierarchical
background = colors.surface.primary;
sidebar = colors.surface.secondary;
statusbar = colors.surface.tertiary;
text = colors.text.primary;
dimmedText = colors.text.secondary;

# Bad: Random or non-semantic
background = colors.surface.tertiary;  # Wrong hierarchy
sidebar = colors.accent.primary;      # Wrong semantic meaning
text = colors.border.subtle;          # Wrong category
```

## Philosophy Guidelines

Signal is built on three core principles:

### 1. Scientific Approach

- Every color choice must have a functional justification
- Use OKLCH color space for perceptual uniformity
- Rely on calculated contrast (APCA) over subjective judgment
- Document the reasoning behind color decisions

### 2. Accessibility First

- All text must meet APCA contrast requirements
- Interactive elements must be distinguishable
- Support both light and dark modes equally well
- Consider color blindness and other visual impairments

### 3. Perceptual Uniformity

- Maintain consistent perceived lightness across hues
- Use OKLCH's perceptual properties for gradients
- Ensure smooth transitions between theme modes
- Respect the color space's mathematical properties

**When contributing:**

- ✅ Do: Propose changes that enhance these principles
- ✅ Do: Provide scientific justification for color changes
- ✅ Do: Test accessibility with tools like [APCA Calculator](https://www.myndex.com/APCA/)
- ❌ Don't: Make purely aesthetic changes without functional reason
- ❌ Don't: Reduce contrast or accessibility
- ❌ Don't: Break perceptual uniformity

## Documentation

### Updating Documentation

When making changes, update relevant documentation:

- **README.md**: User-facing features and options
- **CHANGELOG.md**: Notable changes for each version
- **examples/**: Add or update example configurations
- **Code comments**: Explain complex logic
- **Commit messages**: Describe the "why" not just the "what"

### Writing Good Documentation

**Good documentation:**
- Clear and concise
- Includes examples
- Explains the "why" and "when"
- Covers edge cases
- Uses proper formatting

**Example:**

```markdown
## Brand Governance

Signal separates functional colors (for UI) from brand colors (for identity).
This prevents brand colors from compromising accessibility.

### Policies

- `functional-override`: Functional colors always win (safest)
- `separate-layer`: Brand colors exist alongside functional colors
- `integrated`: Brand colors can replace functional colors (must meet accessibility)

### Example

\`\`\`nix
theming.signal.brandGovernance = {
  policy = "functional-override";
  decorativeBrandColors = {
    brand-primary = "#5a7dcf";
  };
};
\`\`\`
```

## Questions?

- **Issues**: [GitHub Issues](https://github.com/lewisflude/signal-nix/issues)
- **Discussions**: [GitHub Discussions](https://github.com/lewisflude/signal-nix/discussions)
- **Twitter**: [@lewisflude](https://twitter.com/lewisflude)

Thank you for contributing to Signal! 🎨✨
