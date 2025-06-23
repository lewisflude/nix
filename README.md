# Nix Configuration

A comprehensive, cross-platform Nix configuration supporting both macOS (nix-darwin) and Linux (NixOS) with shared home-manager settings.

## 🚀 Quick Start

### Initial Setup

1. **Install Nix** (if not already installed):
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. **Clone this configuration**:
   ```bash
   git clone <your-repo-url> ~/.config/nix
   cd ~/.config/nix
   ```

3. **First-time build**:
   ```bash
   # macOS
   sudo darwin-rebuild switch --flake ~/.config/nix#macbook-pro
   
   # Linux
   sudo nixos-rebuild switch --flake ~/.config/nix#jupiter
   ```

### Daily Usage

- **System updates**: `update` or `system-update`
- **Full update with cleanup**: `system-update --full`
- **Build without switching**: `system-update --build-only`

## 📁 Configuration Structure

```
.
├── config-vars.nix          # User preferences and variables
├── flake.nix               # Main flake configuration
├── hosts/                  # Host-specific configurations
├── modules/                # System-level modules
│   ├── darwin/            # macOS-specific modules
│   └── nixos/             # Linux-specific modules
├── home/                   # Home-manager configurations
│   └── common/            # Cross-platform home configs
├── lib/                    # Helper functions and utilities
├── shells/                 # Development environments
└── secrets/               # Secrets management
```

## 🛠️ Development Environments

This configuration provides pre-configured development shells:

### Available Shells
- **Node.js/TypeScript**: `node-shell`
- **Python**: `python-shell`  
- **Rust**: `rust-shell`
- **Go**: `go-shell`
- **Web Development**: `web-shell`
- **Solana/Blockchain**: `solana-shell`
- **DevOps**: `devops-shell`

### Using Development Environments

#### Option 1: Direct Shell Access
```bash
node-shell  # Enter Node.js development environment
```

#### Option 2: Project-based with direnv
1. **Create `.envrc` in your project**:
   ```bash
   # Copy appropriate template
   cp ~/.config/nix/shells/envrc-templates/node .envrc
   
   # Allow direnv to load it
   direnv allow
   ```

2. **Automatic environment loading**: The environment will load automatically when you `cd` into the project directory.

## 🔐 Secrets Management

### Setup SOPS (one-time)
1. **Generate age key**:
   ```bash
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   ```

2. **Create secrets file**:
   ```bash
   # Get your age public key
   age-keygen -y ~/.config/sops/age/keys.txt
   
   # Create secrets.yaml with your public key
   cd ~/.config/nix/secrets
   sops secrets.yaml
   ```

### Adding Secrets
```bash
cd ~/.config/nix/secrets
sops secrets.yaml
```

Add entries like:
```yaml
openai-api-key: sk-...
github-token: ghp_...
aws-access-key-id: AKIA...
```

## 🎨 Customization

### User Preferences
Edit `config-vars.nix` to customize:
- User information (name, email)
- Development tools preferences
- Theme settings
- Platform-specific settings

### Adding Software
- **System packages**: Add to appropriate module in `modules/`
- **User packages**: Add to `home/common/apps.nix`
- **Development tools**: Add to relevant shell in `shells/`

## 🖥️ Platform-Specific Features

### macOS (Darwin)
- Homebrew integration for GUI apps
- System preferences configuration
- Dock and Finder customization

### Linux (NixOS)
- Hyprland desktop environment
- Waybar status bar with Catppuccin theme
- Gaming mode toggle
- Advanced audio (PipeWire) and networking

## 🧹 Maintenance

### Cleaning Up
- **Quick cleanup**: `nix-clean`
- **Full optimization**: `nix-optimize`
- **Store analysis**: `nix-analyze`
- **Check store size**: `nix-size`

### Backup and Recovery
- **Backup configuration**: `backup`
- **View backups**: `backup-restore`

## 🔧 Advanced Usage

### Custom Development Shell
Create a new shell in `shells/default.nix`:

```nix
myproject = pkgs.mkShell {
  buildInputs = with pkgs; [
    # your dependencies
  ];
  shellHook = ''
    echo "🚀 My project environment loaded"
  '';
};
```

### Adding New Secrets
1. Add to `secrets/default.nix`
2. Update `secrets.yaml` with SOPS
3. Reference in your modules

### Host-Specific Configuration
Add new hosts in `hosts/` directory following existing patterns.

## 📚 References

- **Nix Manual**: https://nixos.org/manual/nix/stable/
- **Home Manager**: https://nix-community.github.io/home-manager/
- **nix-darwin**: https://github.com/LnL7/nix-darwin
- **SOPS-nix**: https://github.com/Mic92/sops-nix

## 🐛 Troubleshooting

### Common Issues

1. **Build failures**: Check `journalctl -u nix-daemon` on Linux
2. **Permission issues**: Ensure user is in `nix-users` group
3. **Flake lock issues**: Run `nix flake update`
4. **Home-manager conflicts**: Run `home-manager switch --backup-extension .bak`

### Getting Help
- Check the Nix community forums
- Review recent commits for configuration changes
- Use `nix develop` for isolated testing environments