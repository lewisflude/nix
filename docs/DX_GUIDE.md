# Developer Experience (DX) Guide

This guide outlines the developer experience tooling and best practices for this Nix configuration repository.

## Table of Contents

- [Getting Started](#getting-started)
- [Conventional Commits](#conventional-commits)
- [Conventional Comments](#conventional-comments)
- [Code Quality Tools](#code-quality-tools)
- [Pre-commit Hooks](#pre-commit-hooks)
- [Editor Configuration](#editor-configuration)
- [Formatting and Linting](#formatting-and-linting)
- [Best Practices](#best-practices)

## Getting Started

Enter the development environment to get access to all DX tooling:

```bash
nix develop
```

This will automatically:

- Install all required tools
- Set up pre-commit hooks
- Configure your shell with helpful aliases

## Conventional Commits

We use [Conventional Commits](https://www.conventionalcommits.org/) for all commit messages.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that don't affect code meaning (formatting, etc.)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Changes to build process, dependencies, etc.
- **ci**: Changes to CI configuration
- **build**: Changes to build system or external dependencies
- **revert**: Reverts a previous commit

### Examples

```bash
# Feature with scope
feat(darwin): add keyboard shortcuts for window management

# Bug fix
fix(nixos): resolve audio crackling in pipewire

# Documentation
docs: update installation instructions for macOS

# Refactoring
refactor(home): extract common shell aliases

# Multiple changes (body)
feat(containers): add media management services

Add Radarr, Sonarr, and Prowlarr as containerized services.
Configure automatic monitoring and downloads.

Closes #123
```

### Commit Message Template

A commit message template is provided to help you write conventional commits:

```bash
# Configure git to use the template (happens automatically in dev shell)
git config commit.template .gitmessage
```

### Enforcement

Conventional commits are enforced through:

- Pre-commit hooks (commitizen)
- CI checks
- The commit template guide

## Conventional Comments

We use [Conventional Comments](https://conventionalcommits.org/) for code reviews. See [CONVENTIONAL_COMMENTS.md](./CONVENTIONAL_COMMENTS.md) for detailed guidelines.

### Quick Reference

| Label | Meaning | Blocks Merge? |
|-------|---------|---------------|
| `blocking` | Must be addressed | Yes |
| `nitpick` | Minor suggestion | No |
| `suggestion` | Proposed improvement | No |
| `issue` | Problem to discuss | Maybe |
| `question` | Needs clarification | No |
| `praise` | Acknowledgment | No |
| `thought` | Thinking out loud | No |

### Example

```
blocking: This function needs error handling for network failures.
```

```
suggestion (non-blocking): Consider extracting this into a helper function.
```

```
praise: Excellent abstraction! This will make testing much easier.
```

## Code Quality Tools

### Nix-specific Tools

- **nixfmt**: Nix formatter
- **deadnix**: Find and remove dead Nix code
- **statix**: Linter and suggestions for Nix
- **nixpkgs-fmt**: Alternative formatter (available but not default)

### Usage

```bash
# Format all Nix files
nixfmt .

# Find dead code
deadnix

# Run linter
statix check .

# Visualize dependencies
nix-tree .#nixosConfigurations.jupiter.config.system.build.toplevel

# Compare configurations
nix-diff result-1 result-2
```

## Pre-commit Hooks

Pre-commit hooks run automatically before each commit. They ensure code quality and consistency.

### Enabled Hooks

1. **Nix Formatting & Linting**
   - `nixfmt`: Format Nix files
   - `deadnix`: Check for dead code
   - `statix`: Lint Nix files

2. **Conventional Commits**
   - `commitizen`: Enforce conventional commit format

3. **General Code Quality**
   - `trailing-whitespace`: Remove trailing whitespace
   - `end-of-file-fixer`: Ensure files end with newline
   - `mixed-line-ending`: Ensure consistent line endings

4. **File-specific**
   - `check-yaml`: Validate YAML syntax
   - `markdownlint`: Format and lint Markdown files

### Manual Execution

```bash
# Run all hooks on all files
pre-commit run --all-files

# Run specific hook
pre-commit run nixfmt --all-files

# Skip hooks (not recommended)
git commit --no-verify
```

### Hook Configuration

Pre-commit hooks are configured in `lib/output-builders.nix` using the `pre-commit-hooks.nix` flake input.

## Editor Configuration

We use [EditorConfig](https://editorconfig.org/) for consistent code style across editors.

### Supported Editors

- VSCode/Cursor (with EditorConfig extension)
- JetBrains IDEs (built-in)
- Vim/Neovim (with editorconfig-vim)
- Emacs (with editorconfig-emacs)
- Sublime Text (with EditorConfig package)

### Configuration

The `.editorconfig` file defines:

- Indentation style (spaces/tabs)
- Indentation size per language
- Line endings (LF)
- Trailing whitespace rules
- Character encoding (UTF-8)

## Formatting and Linting

### Nix Files

```bash
# Format
nixfmt .

# Lint
statix check .

# Both
nix flake check
```

### Markdown Files

```bash
# Format with prettier (via treefmt)
prettier --write "**/*.md"

# Lint
markdownlint "**/*.md"
```

### Shell Scripts

```bash
# Format
shfmt -i 2 -s -w **/*.sh

# Lint
shellcheck **/*.sh
```

### YAML Files

```bash
# Format
prettier --write "**/*.{yaml,yml}"

# Validate
yamllint .
```

## Best Practices

### Commit Workflow

1. **Make changes** in small, logical commits
2. **Stage changes**: `git add -p` (interactive staging)
3. **Write good commit messages** using conventional commits
4. **Let hooks run** - they'll catch issues early
5. **Review changes**: `git diff --staged`
6. **Push changes**: `git push`

### Code Review Workflow

1. **Use conventional comments** for clarity
2. **Be specific and actionable** in feedback
3. **Use `praise` liberally** to acknowledge good work
4. **Mark truly blocking issues** as `blocking`
5. **Provide context** with suggestions and alternatives
6. **Be respectful** - there's a human behind the code

### Module Development

1. **Use templates**: `nix run .#new-module`
2. **Follow naming conventions**: See `docs/ARCHITECTURE.md`
3. **Add documentation**: Update relevant docs
4. **Write tests**: Use NixOS tests when appropriate
5. **Check evaluation**: `nix flake check`

### Before Submitting PRs

```bash
# Format everything
nixfmt .

# Run all checks
nix flake check

# Run all pre-commit hooks
pre-commit run --all-files

# Test build
nh os build # or nh darwin build
```

## Helpful Aliases

When in the dev shell, these aliases are available:

```bash
fmt       # Format all Nix files (nixfmt)
lint      # Lint all Nix files (statix)
check     # Run all flake checks
update    # Update all flake inputs
```

## CI Integration

Our CI pipeline runs:

1. Nix flake check
2. All pre-commit hooks
3. Configuration builds (NixOS/Darwin)
4. Cache generation

Ensure all checks pass locally before pushing.

## Troubleshooting

### Pre-commit hooks fail

```bash
# Update hooks
pre-commit install --hook-type pre-commit --hook-type commit-msg

# Re-run hooks
pre-commit run --all-files
```

### Formatters conflict

```bash
# Our precedence: nixfmt > nixpkgs-fmt
# If you prefer nixpkgs-fmt, adjust pre-commit config
```

### Commit message rejected

```bash
# Check your message format
# Must follow: type(scope): subject
# Example: feat(nixos): add new module
```

### Build fails after dependency update

```bash
# Try updating the lock file
nix flake update

# Clear build cache
nix-collect-garbage

# Rebuild
nh os build --no-nom
```

## Resources

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Conventional Comments](https://conventionalcomments.org/)
- [EditorConfig](https://editorconfig.org/)
- [pre-commit](https://pre-commit.com/)
- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)

## Contributing

When contributing to this repository:

1. Follow the conventional commits standard
2. Use conventional comments in code reviews
3. Ensure all pre-commit hooks pass
4. Write clear, concise documentation
5. Test your changes thoroughly
6. Keep commits atomic and focused

## Questions?

If you have questions about DX tooling or practices:

1. Check this guide first
2. Review existing patterns in the codebase
3. Ask in code review discussions
4. Open an issue for clarification

Remember: Good DX leads to better code, faster development, and happier developers! 🚀
