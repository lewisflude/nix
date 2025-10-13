# direnv Integration Guide

This guide explains how to set up and use direnv with the nix-config repository for instant development environment activation.

## What is direnv?

direnv is a shell extension that automatically loads and unloads environment variables when you enter/exit a directory. For Nix development, it provides:

- **Instant activation** - No need to run `nix develop`
- **Auto-reload** - Changes to `flake.nix` trigger automatic rebuild
- **Editor integration** - Works with VS Code, Cursor, and other editors
- **Faster than nix-shell** - Uses caching for near-instant activation

## Installation

### 1. Install direnv

```bash
# On NixOS (add to configuration)
environment.systemPackages = [ pkgs.direnv ];

# On macOS/Darwin (add to Homebrew or Nix profile)
nix-env -iA nixpkgs.direnv

# Or via Home Manager
programs.direnv = {
  enable = true;
  nix-direnv.enable = true; # Better Nix integration
};
```

### 2. Configure Your Shell

Add the direnv hook to your shell configuration:

```bash
# For Bash (~/.bashrc)
eval "$(direnv hook bash)"

# For Zsh (~/.zshrc)
eval "$(direnv hook zsh)"

# For Fish (~/.config/fish/config.fish)
direnv hook fish | source
```

### 3. Enable direnv in Repository

```bash
# Navigate to nix-config directory
cd ~/.config/nix

# Allow direnv to run (one-time)
direnv allow

# You should see output like:
# direnv: loading ~/.config/nix/.envrc
# ✓ Nix configuration development environment loaded
```

## Features

### Automatic Environment Loading

When you `cd` into the nix-config directory, direnv automatically:

1. Loads the Nix development shell
2. Adds custom scripts to PATH
3. Sets up environment variables
4. Displays helpful information

```bash
cd ~/.config/nix
# Output:
# direnv: loading ~/.config/nix/.envrc
# ✓ Nix configuration development environment loaded
#   Available scripts:
#     - benchmark-rebuild.sh
#     - diff-config.sh
#     - new-module.sh
#     - update-flake.sh
```

### Available Tools

The development environment includes:

**Nix Tools:**
- `alejandra` - Fast Nix formatter
- `deadnix` - Find unused code
- `statix` - Lint and suggestions
- `nix-tree` - Dependency visualization
- `nvd` - Configuration comparison

**Documentation:**
- `mdbook` - Build documentation
- `graphviz` - Generate diagrams

**Utilities:**
- `ripgrep`, `fd`, `bat`, `eza` - Enhanced CLI tools
- `git`, `gh`, `jq` - Development essentials

### Helpful Aliases

The shell automatically sets up aliases:

```bash
fmt            # Format all Nix files with alejandra
lint           # Run statix linter
check          # Run nix flake check
update         # Update flake inputs
build-darwin   # Build Darwin configuration
build-nixos    # Build NixOS configuration
```

### Custom Scripts in PATH

All utility scripts are automatically available:

```bash
# No need to type ./scripts/utils/...
benchmark-rebuild.sh
diff-config.sh
new-module.sh feature my-feature
update-flake.sh
```

## Configuration

### .envrc File

The `.envrc` file in the repository root controls direnv behavior:

```bash
# Use the flake-based development shell
use flake

# Add scripts to PATH
PATH_add scripts/utils
PATH_add scripts/maintenance

# Set environment variables
export NIX_CONFIG_DIR="$(pwd)"
export FLAKE_DIR="$(pwd)"
```

### Watch Additional Files

You can configure direnv to watch specific files for changes:

```bash
# In .envrc
watch_file flake.lock
watch_file modules/**/*.nix
```

When these files change, direnv will reload the environment.

## Editor Integration

### VS Code / Cursor

1. Install the direnv extension:
   - [direnv for VS Code](https://marketplace.visualstudio.com/items?itemName=mkhl.direnv)

2. The extension will automatically detect and use the environment

3. You'll see a notification when direnv loads

### Vim / Neovim

With `vim-direnv` plugin:

```vim
" In your init.vim or .vimrc
Plug 'direnv/direnv.vim'
```

### Emacs

Built-in support via `direnv-mode`:

```elisp
(use-package direnv
  :config
  (direnv-mode))
```

## Performance Optimization

### nix-direnv for Faster Reloads

For even better performance, install nix-direnv:

```bash
# Via Home Manager
programs.direnv = {
  enable = true;
  nix-direnv.enable = true; # Adds smart caching
};
```

Benefits:
- **Caches the environment** - Subsequent loads are instant
- **Survives GC** - Environment persists across garbage collection
- **Smarter reloads** - Only rebuilds when necessary

### Cache Location

Environments are cached in:
- `~/.cache/nix-direnv/` - With nix-direnv
- `~/.direnv/` - Without nix-direnv

## Troubleshooting

### Environment Not Loading

```bash
# Check if direnv is allowed
direnv status

# Re-allow if needed
direnv allow

# Force reload
direnv reload
```

### Slow Initial Load

First load builds the development shell, which takes time. Subsequent loads are cached and instant.

```bash
# Pre-build the environment
nix develop -c true

# Then allow direnv
direnv allow
```

### Shell Hook Not Running

If you don't see the welcome message:

1. Check shell hook is configured:
   ```bash
   echo $DIRENV_DIR
   ```

2. Verify hook in shell config:
   ```bash
   # Should show "direnv hook ..."
   grep direnv ~/.zshrc  # or ~/.bashrc
   ```

3. Reload shell configuration:
   ```bash
   source ~/.zshrc
   ```

### Conflicts with Other Tools

If you use `nix-shell` or `nix develop` manually:

- direnv and manual shell can coexist
- Manual shell takes precedence when active
- Exit manual shell to return to direnv environment

## Best Practices

### 1. Always Allow After Pulling Changes

```bash
git pull
direnv allow  # If .envrc changed
```

### 2. Commit .envrc Template

The `.envrc` file is committed to the repository so others can use it. Local customizations should go in `.envrc.local`:

```bash
# Create local overrides
cat > .envrc.local <<EOF
# My custom environment variables
export MY_VAR="value"
EOF

# Add to .gitignore
echo ".envrc.local" >> .gitignore
```

### 3. Use with Flake Inputs

When you update flake inputs, direnv automatically rebuilds:

```bash
nix flake update
# direnv detects flake.lock change
# Automatically rebuilds environment
```

### 4. Combine with Starship or Oh-My-Zsh

direnv works great with shell prompts that show the environment:

```toml
# In starship.toml
[direnv]
disabled = false
format = "[$symbol$loaded]($style) "
symbol = "🔒 "
```

## Comparison: direnv vs nix develop

| Feature | direnv | nix develop |
|---------|--------|-------------|
| Activation | Automatic | Manual |
| Speed (first) | Same | Same |
| Speed (subsequent) | Instant (<50ms) | Slow (2-5s) |
| Editor integration | Excellent | Limited |
| Caching | Built-in | Manual |
| PATH persistence | Yes | Only in shell |
| Learning curve | Minimal | Minimal |

## Advanced Usage

### Per-Directory Shells

You can have different shells for subdirectories:

```bash
# In scripts/.envrc
use flake .#devShells.scripting
```

### Conditional Loading

Load different environments based on conditions:

```bash
# In .envrc
if [ "$(uname)" = "Darwin" ]; then
  use flake .#devShells.darwin
else
  use flake .#devShells.linux
fi
```

### Integration with lorri

For automatic rebuilds when files change:

```bash
# Install lorri
nix-env -iA nixpkgs.lorri

# In .envrc
eval "$(lorri direnv)"
```

## Security Considerations

### Why direnv Requires Explicit Allow

direnv requires `direnv allow` to prevent malicious code execution:

- `.envrc` can run arbitrary shell commands
- `allow` is required after any `.envrc` change
- Protects against accidentally running untrusted code

### Trusting the Repository

Only run `direnv allow` on repositories you trust:

```bash
# Review .envrc before allowing
cat .envrc

# Then allow if safe
direnv allow
```

### Revoking Access

```bash
# Remove permission
direnv deny

# Or delete the allow file
rm ~/.config/direnv/allow/*
```

## Resources

- [direnv Documentation](https://direnv.net/)
- [nix-direnv GitHub](https://github.com/nix-community/nix-direnv)
- [Nix Flakes and direnv](https://nixos.wiki/wiki/Flakes#Using_flakes_with_direnv)
- [direnv Hooks](https://direnv.net/docs/hook.html)

## Summary

direnv provides instant, automatic activation of the Nix development environment:

✅ **Fast** - Cached environments load in <50ms  
✅ **Automatic** - No need to remember `nix develop`  
✅ **Editor-friendly** - Works with all major editors  
✅ **Convenient** - Scripts and tools always available  
✅ **Safe** - Explicit allow prevents malicious code  

Once set up, you'll never want to go back to manual `nix develop`!

---

**See Also:**
- [Development Shell Configuration](../shells/default.nix)
- [Contributing Guide](../../CONTRIBUTING.md)
- [Architecture Documentation](../ARCHITECTURE.md)
