#!/usr/bin/env bash

# Automated backup script for nix-darwin configuration
# Backs up configuration files, secrets, and important development data

set -euo pipefail

BACKUP_DIR="$HOME/Backups/nix-config"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_PATH="$BACKUP_DIR/$TIMESTAMP"

# Create backup directory
mkdir -p "$BACKUP_PATH"

echo "🚀 Starting nix-darwin configuration backup..."

# Backup nix configuration
echo "📁 Backing up nix configuration..."
cp -r "$HOME/.config/nix" "$BACKUP_PATH/nix-config"

# Backup secrets (encrypted)
if [ -d "$HOME/.config/secrets" ]; then
    echo "🔐 Backing up secrets..."
    tar -czf "$BACKUP_PATH/secrets.tar.gz" -C "$HOME/.config" secrets
    chmod 600 "$BACKUP_PATH/secrets.tar.gz"
fi

# Backup shell configuration
echo "🐚 Backing up shell configuration..."
mkdir -p "$BACKUP_PATH/shell"
[ -f "$HOME/.zshrc" ] && cp "$HOME/.zshrc" "$BACKUP_PATH/shell/"
[ -f "$HOME/.p10k.zsh" ] && cp "$HOME/.p10k.zsh" "$BACKUP_PATH/shell/"
[ -f "$HOME/.gitconfig" ] && cp "$HOME/.gitconfig" "$BACKUP_PATH/shell/"

# Backup SSH keys (if they exist)
if [ -d "$HOME/.ssh" ]; then
    echo "🔑 Backing up SSH configuration..."
    mkdir -p "$BACKUP_PATH/ssh"
    cp "$HOME/.ssh/config" "$BACKUP_PATH/ssh/" 2>/dev/null || true
    # Don't backup private keys for security - just config
fi

# Create a restore script
cat > "$BACKUP_PATH/restore.sh" << 'EOF'
#!/usr/bin/env bash
# Restore script for nix-darwin configuration

set -euo pipefail

BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔄 Restoring nix-darwin configuration from backup..."

# Restore nix configuration
if [ -d "$BACKUP_DIR/nix-config" ]; then
    echo "📁 Restoring nix configuration..."
    cp -r "$BACKUP_DIR/nix-config" "$HOME/.config/nix"
fi

# Restore secrets
if [ -f "$BACKUP_DIR/secrets.tar.gz" ]; then
    echo "🔐 Restoring secrets..."
    tar -xzf "$BACKUP_DIR/secrets.tar.gz" -C "$HOME/.config/"
    chmod -R 600 "$HOME/.config/secrets"
fi

# Restore shell configuration
if [ -d "$BACKUP_DIR/shell" ]; then
    echo "🐚 Restoring shell configuration..."
    [ -f "$BACKUP_DIR/shell/.zshrc" ] && cp "$BACKUP_DIR/shell/.zshrc" "$HOME/"
    [ -f "$BACKUP_DIR/shell/.p10k.zsh" ] && cp "$BACKUP_DIR/shell/.p10k.zsh" "$HOME/"
    [ -f "$BACKUP_DIR/shell/.gitconfig" ] && cp "$BACKUP_DIR/shell/.gitconfig" "$HOME/"
fi

# Restore SSH config
if [ -d "$BACKUP_DIR/ssh" ]; then
    echo "🔑 Restoring SSH configuration..."
    mkdir -p "$HOME/.ssh"
    [ -f "$BACKUP_DIR/ssh/config" ] && cp "$BACKUP_DIR/ssh/config" "$HOME/.ssh/"
    chmod 700 "$HOME/.ssh"
    chmod 600 "$HOME/.ssh/config" 2>/dev/null || true
fi

echo "✅ Restore complete! Run 'darwin-rebuild switch --flake ~/.config/nix' to apply configuration."
EOF

chmod +x "$BACKUP_PATH/restore.sh"

# Create manifest
cat > "$BACKUP_PATH/manifest.txt" << EOF
Nix-Darwin Configuration Backup
Generated: $(date)
Hostname: $(hostname)
User: $(whoami)
Nix Version: $(nix --version | head -n1)
Darwin-rebuild: $(which darwin-rebuild)

Contents:
- nix-config/: Complete nix-darwin configuration
- secrets.tar.gz: Encrypted secrets directory
- shell/: Shell configuration files
- ssh/: SSH configuration (no private keys)
- restore.sh: Automated restore script
- manifest.txt: This file

To restore:
1. Extract this backup to desired location
2. Run ./restore.sh
3. Run 'darwin-rebuild switch --flake ~/.config/nix'
EOF

# Cleanup old backups (keep last 10)
echo "🧹 Cleaning up old backups..."
ls -1t "$BACKUP_DIR" | tail -n +11 | xargs -I {} rm -rf "$BACKUP_DIR/{}" 2>/dev/null || true

echo "✅ Backup completed successfully!"
echo "📍 Backup location: $BACKUP_PATH"
echo "📋 Manifest: $BACKUP_PATH/manifest.txt"
echo "🔄 Restore script: $BACKUP_PATH/restore.sh"