# Contributing to Nix Configuration

Thank you for your interest in contributing! This document provides guidelines and best practices for contributing to this repository.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Commit Guidelines](#commit-guidelines)
- [Code Review](#code-review)
- [Module Development](#module-development)
- [Testing](#testing)
- [Documentation](#documentation)

## Getting Started

### Prerequisites

- Nix with flakes enabled
- Git
- Basic understanding of Nix language

### Setting Up Development Environment

1. **Clone the repository:**

   ```bash
   git clone https://github.com/yourusername/nix-config.git
   cd nix-config
   ```

2. **Enter development shell:**

   ```bash
   nix develop
   ```

   This will:
   - Install all required tools
   - Set up pre-commit hooks
   - Configure git commit template
   - Set up helpful aliases

3. **Verify setup:**

   ```bash
   # Run checks
   nix flake check

   # Format code (recommended)
   nix fmt
   # or format all file types
   treefmt
   ```

## Development Workflow

### 1. Create a Branch

```bash
git checkout -b feat/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 2. Make Changes

- Keep changes focused and atomic
- Follow existing code style
- Update documentation as needed
- Add tests when appropriate

### 3. Format and Lint

```bash
# Format Nix files
nixfmt .

# Lint Nix files
statix check .

# Run all checks
nix flake check

# Run pre-commit hooks
pre-commit run --all-files
```

### 4. Commit Changes

Follow [Conventional Commits](https://www.conventionalcommits.org/) standard:

```bash
git add -p  # Stage changes interactively
git commit  # Template will guide you
```

See [docs/examples/conventional-commit-examples.md](docs/examples/conventional-commit-examples.md) for examples.

### 5. Test Your Changes

**For NixOS changes:**

```bash
# Build configuration
nix build .#nixosConfigurations.jupiter.config.system.build.toplevel

# Test in VM (if applicable)
# Or ask maintainer to build
```

**For Darwin changes:**

```bash
# Build configuration
nix build .#darwinConfigurations.mercury.system
```

**For Home-Manager changes:**

```bash
# Build home configuration
nix build .#homeConfigurations.lewis@jupiter.activationPackage
```

### 6. Push and Create PR

```bash
git push origin feat/your-feature-name
```

Then create a Pull Request on GitHub.

## Commit Guidelines

We use [Conventional Commits](https://www.conventionalcommits.org/) for all commit messages.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation only
- `style` - Formatting, missing semicolons, etc.
- `refactor` - Code change that neither fixes a bug nor adds a feature
- `perf` - Performance improvement
- `test` - Adding or updating tests
- `chore` - Maintenance tasks, dependency updates
- `ci` - CI/CD changes
- `build` - Build system or external dependencies
- `revert` - Reverts a previous commit

### Scopes

Common scopes:

- `nixos` - NixOS-specific changes
- `darwin` - macOS/Darwin-specific changes
- `home` - Home-manager configuration
- `modules` - Module system changes
- `lib` - Library functions
- `shells` - Development shells
- `docs` - Documentation
- `ci` - CI/CD configuration

### Examples

```bash
feat(nixos): add media management services

fix(darwin): resolve keyboard shortcut conflicts

docs: update installation instructions

chore: update flake inputs
```

See [docs/examples/conventional-commit-examples.md](docs/examples/conventional-commit-examples.md) for more examples.

## Code Review

We use [Conventional Comments](https://conventionalcomments.org/) for code reviews.

### Labels

- `blocking:` - Must be addressed before merging
- `nitpick:` - Minor suggestion, not required
- `suggestion:` - Proposed improvement
- `issue:` - Problem that needs discussion
- `question:` - Asking for clarification
- `praise:` - Acknowledging good work

### Examples

```
blocking: This function needs error handling for network failures.
```

```
suggestion (non-blocking): Consider extracting this into a helper function for reusability.
```

```
praise: Excellent abstraction! This makes the code much more maintainable.
```

See [docs/CONVENTIONAL_COMMENTS.md](docs/CONVENTIONAL_COMMENTS.md) for detailed guidelines.

## Module Development

### Using Templates

Generate a new module using templates:

```bash
nix run .#new-module
```

### Module Structure

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.category.modulename;
in {
  options.modules.category.modulename = {
    enable = lib.mkEnableOption "description of module";

    # Add your options here
  };

  config = lib.mkIf cfg.enable {
    # Add your configuration here
  };
}
```

### Module Guidelines

1. **Use `mkEnableOption`** for enable flags
2. **Provide good descriptions** in options
3. **Use `lib.mkIf`** for conditional configuration
4. **Follow existing naming conventions**
5. **Add documentation** in module options
6. **Consider cross-platform compatibility**

### Module Categories

- `modules/nixos/` - NixOS-only modules
- `modules/darwin/` - macOS-only modules
- `modules/shared/` - Cross-platform modules
- `modules/nixos/features/` - Feature bundles for NixOS
- `modules/nixos/services/` - Service definitions

## Testing

### Flake Checks

```bash
# Run all checks
nix flake check

# Check specific output
nix build .#checks.x86_64-linux.pre-commit-check
```

### Build Tests

```bash
# Test NixOS configuration builds
nix build .#nixosConfigurations.jupiter.config.system.build.toplevel

# Test Darwin configuration builds
nix build .#darwinConfigurations.mercury.system

# Test home-manager configuration builds
nix build .#homeConfigurations.lewis@jupiter.activationPackage
```

### Integration Tests

For NixOS modules, consider adding integration tests:

```bash
# Run tests
nix build .#checks.x86_64-linux.nixosTests-<testname>
```

## Documentation

### What to Document

1. **Module options** - Use `description` field
2. **Complex configurations** - Add inline comments
3. **Architecture decisions** - Update docs/reference/architecture.md
4. **Usage examples** - Add to relevant docs
5. **Breaking changes** - Update CHANGELOG and migration guides

### Documentation Style

- **Use Markdown** for all documentation
- **Be concise** but thorough
- **Provide examples** when helpful
- **Update existing docs** when changing functionality
- **Use proper formatting** (headings, lists, code blocks)

### Documentation Structure

```
docs/
├── DX_GUIDE.md             # Developer experience guide
├── CONVENTIONAL_COMMENTS.md # Code review guidelines
├── UPDATING.md             # Update procedures
├── examples/
│   ├── conventional-commit-examples.md
│   └── updating-example.md
└── reference/
    ├── architecture.md     # System architecture
    └── ...                 # Other reference documentation
```

## Pull Request Guidelines

### Before Submitting

- [ ] Code is formatted (`nixfmt .`)
- [ ] Code is linted (`statix check .`)
- [ ] All checks pass (`nix flake check`)
- [ ] Pre-commit hooks pass (`pre-commit run --all-files`)
- [ ] Configuration builds successfully
- [ ] Documentation is updated
- [ ] Commit messages follow conventional commits
- [ ] Changes are tested

### PR Description

Include:

1. **Summary** - What does this PR do?
2. **Motivation** - Why is this change needed?
3. **Testing** - How was this tested?
4. **Breaking Changes** - Are there any breaking changes?
5. **Screenshots** - If relevant (UI changes, etc.)
6. **Related Issues** - Link to related issues/PRs

### Example PR Description

```markdown
## Summary
Add media management services (Radarr, Sonarr, Prowlarr) as containerized services.

## Motivation
Simplifies deployment of media management stack with consistent configuration
and automatic updates.

## Testing
- Built NixOS configuration successfully
- Tested container deployment on jupiter host
- Verified inter-container networking
- Confirmed services accessible via web UI

## Breaking Changes
None

## Related Issues
Closes #123
```

## Getting Help

If you need help:

1. **Check documentation** - Read relevant docs first
2. **Search issues** - Someone may have asked before
3. **Ask in PR/issue** - Start a discussion
4. **Review existing code** - See how similar things are done

## Code of Conduct

- Be respectful and considerate
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Assume good intentions
- Keep discussions on-topic

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

## Questions?

If you have questions about contributing:

1. Check this guide and other documentation
2. Look at existing PRs and commits for examples
3. Open an issue for discussion

Thank you for contributing! 🎉
