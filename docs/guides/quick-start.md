# Quick Start Guide

Get up and running with this Nix configuration in just a few minutes!

## 🚀 5-Minute Setup

### Step 1: Install Nix

**Recommended (Determinate Systems installer):**
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

**Alternative (Official installer):**
```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

### Step 2: Clone Configuration

```bash
# Clone to the standard location
git clone <your-repo-url> ~/.config/nix
cd ~/.config/nix
```

### Step 3: Find Your Hostname

Check available host configurations:
```bash
ls hosts/
# Example output: jupiter/  Lewiss-MacBook-Pro/
```

Your hostname should match one of these directories, or you'll need to [create a new host configuration](configuration.md#adding-hosts).

### Step 4: Build Your System

**macOS (nix-darwin):**
```bash
sudo darwin-rebuild switch --flake ~/.config/nix#<hostname>
```

**Linux (NixOS):**
```bash
sudo nixos-rebuild switch --flake ~/.config/nix#<hostname>
```

> **🔄 First build takes longer** - Nix downloads and builds everything from scratch. Subsequent builds are much faster!

## 🎉 You're Done!

Your system is now managed by Nix! Here's what you get out of the box:

### ✅ Pre-configured Applications
- **Shell:** Zsh with Oh My Zsh and Powerlevel10k
- **Terminal:** Modern terminal tools (bat, fzf, ripgrep, etc.)
- **Development:** Git, Docker, and language-specific tooling
- **Editor:** Configured text editors and development environments

### ✅ Development Environments
Try out a development shell:
```bash
nix develop ~/.config/nix#shell-selector
select_dev_shell  # Interactive menu
```

Or jump directly into a specific environment:
```bash
nix develop ~/.config/nix#node     # Node.js + TypeScript
nix develop ~/.config/nix#python   # Python + pip/poetry  
nix develop ~/.config/nix#rust     # Rust + Cargo
```

## 🔧 Next Steps

### Customize Your Setup
1. **Add packages:** Edit `home/common/apps.nix`
2. **Configure applications:** Browse `home/common/apps/`
3. **Set up dev environments:** See [Development Guide](development.md)

### Learn the Workflow
```bash
# Make changes to configuration files
vim home/common/apps.nix

# Apply changes
sudo darwin-rebuild switch --flake ~/.config/nix#<hostname>  # macOS
sudo nixos-rebuild switch --flake ~/.config/nix#<hostname>   # Linux

# Update dependencies occasionally
nix flake update
```

### Essential Commands
```bash
# Test build without applying
darwin-rebuild build --flake ~/.config/nix#<hostname>   # macOS
nixos-rebuild build --flake ~/.config/nix#<hostname>    # Linux

# Format Nix files
nix fmt

# Clean up old builds  
nix-collect-garbage -d
nix store optimise
```

## 🆘 Need Help?

### Common Issues
- **Permission denied:** Make sure you're using `sudo` for system rebuilds
- **Build failures:** Check you've committed all changes with `git add -A && git commit`
- **Missing hostname:** Create a new host configuration following the pattern in `hosts/`

### Get Support
- **Troubleshooting:** See [Troubleshooting Guide](troubleshooting.md)
- **Configuration:** See [Configuration Guide](configuration.md)
- **Development:** See [Development Guide](development.md)
- **Architecture:** See [Architecture Overview](../reference/architecture.md)

---

**🎯 Ready to dive deeper?** Check out the [Configuration Guide](configuration.md) to start customizing your setup!
