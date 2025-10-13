# Migration Guide

This guide covers common migration scenarios and state preservation strategies for nix-config.

## Table of Contents

1. [When to Migrate](#when-to-migrate)
2. [Pre-Migration Checklist](#pre-migration-checklist)
3. [Major NixOS Version Upgrades](#major-nixos-version-upgrades)
4. [Home Manager Breaking Changes](#home-manager-breaking-changes)
5. [Hardware Changes](#hardware-changes)
6. [Secrets Rotation](#secrets-rotation)
7. [Service State Preservation](#service-state-preservation)
8. [Database Migrations](#database-migrations)
9. [Rollback Procedures](#rollback-procedures)
10. [Post-Migration Validation](#post-migration-validation)

---

## When to Migrate

You need to follow migration procedures when:

- **Major NixOS version upgrade** (e.g., 23.11 → 24.05 → 24.11)
- **Home Manager breaking changes** (check release notes)
- **Hardware replacement** (new machine, disk, etc.)
- **Secrets rotation** (key compromise, regular rotation)
- **Service configuration changes** (major version upgrades)
- **Moving between hosts** (laptop → desktop, etc.)

---

## Pre-Migration Checklist

Before any migration:

### 1. Backup Critical Data

```bash
# Create backup directory
mkdir -p ~/migration-backup-$(date +%Y%m%d)
cd ~/migration-backup-$(date +%Y%m%d)

# Backup Home Manager state
cp -r ~/.local/state/home-manager ./home-manager-state

# Backup important dotfiles
cp -r ~/.config ./config-backup
cp -r ~/.ssh ./ssh-backup

# Backup secrets (if not using SOPS)
# cp -r ~/.gnupg ./gnupg-backup

# Export current system configuration
nix-env --query --installed > installed-packages.txt
nixos-version > nixos-version.txt  # NixOS only
```

### 2. Document Current State

```bash
# System information
cat > system-info.txt <<EOF
Hostname: $(hostname)
Date: $(date)
NixOS Version: $(nixos-version 2>/dev/null || echo "N/A - Darwin")
Nix Version: $(nix --version)
Current Generation: $(readlink /nix/var/nix/profiles/system)
EOF

# List all generations
nix-env --list-generations >> system-info.txt

# Current flake inputs
nix flake metadata >> system-info.txt
```

### 3. Test Configuration

```bash
# Verify current config builds
cd ~/.config/nix

# Build without switching
nix build .#nixosConfigurations.jupiter.config.system.build.toplevel
# OR
nix build .#darwinConfigurations.Lewiss-MacBook-Pro.system

# Run diff to see what would change
./scripts/utils/diff-config.sh

# Run all checks
nix flake check
```

### 4. Review Release Notes

```bash
# Check NixOS release notes
https://nixos.org/manual/nixos/stable/release-notes.html

# Check Home Manager changelog
https://github.com/nix-community/home-manager/releases

# Check nix-darwin releases (macOS)
https://github.com/LNL7/nix-darwin/releases
```

---

## Major NixOS Version Upgrades

### Example: NixOS 24.05 → 24.11

#### 1. Update Flake Inputs

```bash
cd ~/.config/nix

# Backup current flake.lock
cp flake.lock flake.lock.backup

# Update specific inputs
nix flake lock --update-input nixpkgs
nix flake lock --update-input home-manager

# Or update everything
nix flake update
```

#### 2. Review Breaking Changes

Check the release notes and look for:
- Renamed options
- Removed packages
- Changed defaults
- Service migrations

Common breaking changes pattern:

```nix
# OLD (24.05)
services.xserver.enable = true;
services.xserver.displayManager.gdm.enable = true;

# NEW (24.11) - might have changes
# Check: https://nixos.org/manual/nixos/stable/release-notes
```

#### 3. Build New Configuration

```bash
# Test build
nix build .#nixosConfigurations.jupiter.config.system.build.toplevel --show-trace

# Check for errors
# Fix any deprecated options
```

#### 4. Create Restore Point

```bash
# Note current generation number
current_gen=$(nixos-rebuild list-generations | grep current | awk '{print $1}')
echo "Current generation: $current_gen"

# This becomes your rollback target
```

#### 5. Apply Migration

```bash
# Switch to new configuration
sudo nixos-rebuild switch --flake ~/.config/nix#jupiter

# Monitor for issues
journalctl -f
```

#### 6. Verify Services

```bash
# Check all services
systemctl --failed

# Check specific critical services
systemctl status sshd
systemctl status docker
systemctl status NetworkManager

# Test user environment
su - $USER -c 'echo "User environment OK"'
```

#### 7. Rollback if Needed

```bash
# Boot into previous generation
sudo nixos-rebuild switch --rollback

# Or boot specific generation
sudo /nix/var/nix/profiles/system-${current_gen}-link/bin/switch-to-configuration switch
```

---

## Home Manager Breaking Changes

### Identify Breaking Changes

```bash
# Check Home Manager changelog
nix flake metadata .#home-manager

# Common breaking changes:
# - programs.* moved to services.*
# - Option renames
# - Module restructuring
```

### Migration Steps

```bash
# 1. Build current config
home-manager build

# 2. Update home-manager input
nix flake lock --update-input home-manager

# 3. Fix any errors
# Read error messages carefully - they usually indicate the new option name

# 4. Build again
home-manager build

# 5. Apply
home-manager switch
```

### Example Fixes

```nix
# Example 1: Program moved to service
# OLD
programs.dunst.enable = true;

# NEW  
services.dunst.enable = true;

# Example 2: Option renamed
# OLD
programs.git.signing.key = "ABC123";

# NEW
programs.git.signing.signByDefault = true;
programs.git.signing.key = "ABC123";
```

---

## Hardware Changes

### Moving to New Machine

#### 1. Generate Hardware Config

```bash
# On new machine after installing NixOS
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix

# Copy to your repo
cp hardware-configuration.nix ~/.config/nix/hosts/new-machine/
```

#### 2. Create Host Configuration

```bash
cd ~/.config/nix

# Copy existing host as template
cp -r hosts/jupiter hosts/new-machine

# Update hardware-configuration.nix
# Update default.nix with new hostname and features
```

#### 3. Transfer Secrets

```bash
# On old machine: Export secrets
cd ~/.config/nix
tar czf secrets-backup.tar.gz secrets/

# Transfer to new machine
scp secrets-backup.tar.gz new-machine:~/

# On new machine: Import secrets
cd ~/.config/nix
tar xzf ~/secrets-backup.tar.gz

# Update SOPS keys if needed
ssh-to-age -i ~/.ssh/id_ed25519.pub
# Add new key to .sops.yaml
```

#### 4. Sync State

```bash
# Sync important state directories
rsync -av old-machine:~/.local/state/ ~/.local/state/
rsync -av old-machine:~/.config/ ~/.config/
rsync -av old-machine:~/Documents/ ~/Documents/
```

---

## Secrets Rotation

### When to Rotate

- Key compromise or suspected compromise
- Employee departure (shared keys)
- Regular rotation policy (e.g., annually)
- Moving to new encryption method

### SOPS Key Rotation

#### 1. Generate New Keys

```bash
# Generate new SSH key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_new

# Convert to age format
ssh-to-age -i ~/.ssh/id_ed25519_new.pub
# Copy the age key output
```

#### 2. Update SOPS Config

```yaml
# .sops.yaml
keys:
  - &user_new age1234567890abcdef...  # New key
  - &user_old age0987654321fedcba...  # Old key (temporary)
  
creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
      - age:
          - *user_new
          - *user_old  # Keep old key temporarily
```

#### 3. Re-encrypt Secrets

```bash
cd ~/.config/nix

# Re-encrypt all secrets with new key
for file in secrets/*.yaml; do
  sops updatekeys "$file"
done

# Verify
sops decrypt secrets/secrets.yaml
```

#### 4. Deploy Changes

```bash
# Build and switch
sudo nixos-rebuild switch --flake .#jupiter

# Verify secrets accessible
# Check services using secrets
```

#### 5. Remove Old Key

```yaml
# After verifying everything works, update .sops.yaml
keys:
  - &user_new age1234567890abcdef...  # Only new key

creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
      - age:
          - *user_new  # Old key removed
```

#### 6. Re-encrypt Again

```bash
# Final encryption with only new key
for file in secrets/*.yaml; do
  sops updatekeys "$file"
done
```

---

## Service State Preservation

### Docker Volumes

```bash
# Backup Docker volumes
docker run --rm -v myvolume:/data -v $(pwd):/backup \
  alpine tar czf /backup/myvolume-backup.tar.gz /data

# Restore on new system
docker run --rm -v myvolume:/data -v $(pwd):/backup \
  alpine tar xzf /backup/myvolume-backup.tar.gz -C /
```

### Systemd Service Data

```bash
# Backup service data
sudo tar czf service-data-backup.tar.gz \
  /var/lib/my-service \
  /etc/my-service

# Restore (after installing NixOS)
sudo tar xzf service-data-backup.tar.gz -C /
```

### Home Assistant Example

```bash
# Backup Home Assistant
sudo systemctl stop home-assistant
sudo tar czf hass-backup.tar.gz /var/lib/hass
sudo systemctl start home-assistant

# Restore on new system
sudo systemctl stop home-assistant
sudo tar xzf hass-backup.tar.gz -C /
sudo chown -R hass:hass /var/lib/hass
sudo systemctl start home-assistant
```

---

## Database Migrations

### PostgreSQL

```bash
# Backup database
sudo -u postgres pg_dumpall > postgres-backup.sql

# After migration, restore
sudo -u postgres psql < postgres-backup.sql
```

### MySQL/MariaDB

```bash
# Backup
mysqldump --all-databases > mysql-backup.sql

# Restore
mysql < mysql-backup.sql
```

### SQLite

```bash
# Backup SQLite database
cp /var/lib/myapp/db.sqlite3 db-backup.sqlite3

# Restore
cp db-backup.sqlite3 /var/lib/myapp/db.sqlite3
```

---

## Rollback Procedures

### NixOS Rollback

```bash
# Method 1: Quick rollback
sudo nixos-rebuild switch --rollback

# Method 2: Boot menu
# Restart and select previous generation from boot menu

# Method 3: Specific generation
sudo /nix/var/nix/profiles/system-123-link/bin/switch-to-configuration switch

# Method 4: From rescue mode
mount /dev/sda1 /mnt
nixos-enter --root /mnt
nixos-rebuild switch --rollback
```

### Home Manager Rollback

```bash
# List generations
home-manager generations

# Rollback to previous
home-manager generations | head -n 2 | tail -n 1 | awk '{print $7}' | xargs -I {} {}/activate

# Or restore from backup
cp -r ~/migration-backup-20241013/home-manager-state ~/.local/state/home-manager
home-manager switch
```

### Flake Lock Rollback

```bash
# Restore old flake.lock
cp flake.lock.backup flake.lock

# Rebuild with old inputs
nixos-rebuild switch --flake .#jupiter
```

---

## Post-Migration Validation

### System Health Check

```bash
#!/usr/bin/env bash
# post-migration-check.sh

echo "=== System Health Check ==="

# 1. Check system version
echo "System version:"
nixos-version 2>/dev/null || sw_vers 2>/dev/null

# 2. Check all services
echo -e "\nFailed services:"
systemctl --failed || echo "N/A on Darwin"

# 3. Check disk space
echo -e "\nDisk usage:"
df -h /

# 4. Check secrets
echo -e "\nSecrets check:"
if [ -f ~/.config/nix/secrets/secrets.yaml ]; then
  sops decrypt ~/.config/nix/secrets/secrets.yaml > /dev/null && echo "✅ Secrets accessible" || echo "❌ Secrets not accessible"
fi

# 5. Check Home Manager
echo -e "\nHome Manager:"
home-manager --version

# 6. Check user environment
echo -e "\nUser packages:"
nix-env --query --installed | wc -l
echo "packages installed"

# 7. Test network
echo -e "\nNetwork:"
ping -c 1 google.com > /dev/null && echo "✅ Network OK" || echo "❌ Network issue"

# 8. Check Docker (if enabled)
if command -v docker &> /dev/null; then
  echo -e "\nDocker:"
  docker ps && echo "✅ Docker OK" || echo "⚠️  Docker not running"
fi

echo -e "\n=== Health Check Complete ==="
```

### Application-Specific Checks

```bash
# Check GUI applications
echo "Testing GUI applications..."
which firefox && echo "✅ Firefox installed"
which cursor && echo "✅ Cursor installed"

# Check development tools
echo "Testing development tools..."
node --version
python --version
rustc --version

# Check shell configuration
echo "Testing shell..."
zsh --version
echo $SHELL
```

---

## Common Migration Issues

### Issue 1: Build Failures After Update

**Symptom:** `nix build` fails with evaluation errors

**Solution:**
```bash
# Clear evaluation cache
rm -rf ~/.cache/nix

# Update all inputs
nix flake update

# Try with trace
nix build --show-trace
```

### Issue 2: Services Won't Start

**Symptom:** `systemctl status myservice` shows failed

**Solution:**
```bash
# Check logs
journalctl -u myservice -n 50

# Check configuration
systemctl cat myservice

# Verify permissions
ls -la /var/lib/myservice
```

### Issue 3: Secrets Not Accessible

**Symptom:** SOPS decryption fails

**Solution:**
```bash
# Verify age key
ssh-to-age -i ~/.ssh/id_ed25519.pub

# Check .sops.yaml
cat .sops.yaml

# Re-encrypt secrets
sops updatekeys secrets/secrets.yaml
```

### Issue 4: Home Manager Activation Fails

**Symptom:** `home-manager switch` errors

**Solution:**
```bash
# Check for conflicting files
home-manager switch --show-trace

# Backup and remove conflicts
mv ~/.config/conflicting-file ~/.config/conflicting-file.backup

# Try again
home-manager switch
```

---

## Migration Checklist

Print this checklist for your migration:

```
[ ] Backup current state
[ ] Document current configuration
[ ] Review release notes
[ ] Test new configuration (build)
[ ] Preview changes (diff-config.sh)
[ ] Create restore point
[ ] Apply migration
[ ] Verify system boots
[ ] Check all services
[ ] Verify user environment
[ ] Test critical applications
[ ] Validate secrets access
[ ] Run health check script
[ ] Document any issues
[ ] Keep old generation available
[ ] Update documentation
```

---

## Emergency Contacts

In case of critical issues:

1. **Boot from USB/Recovery**
   - Keep a NixOS USB drive handy
   - Use to roll back or fix issues

2. **Community Resources**
   - NixOS Discourse: https://discourse.nixos.org
   - NixOS Matrix: #nixos:nixos.org
   - GitHub Discussions: Repository issues

3. **Backup System**
   - Always keep a working backup system
   - Test backups before migration

---

## Best Practices

1. **Never migrate in production without testing**
2. **Always have a rollback plan**
3. **Migrate during low-traffic periods**
4. **Keep old generations until validated**
5. **Document everything**
6. **Test in VM first if possible**
7. **One major change at a time**
8. **Maintain offline documentation**

---

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [SOPS-Nix Guide](https://github.com/Mic92/sops-nix)
- [Nix Pills](https://nixos.org/guides/nix-pills/)

---

**Last Updated:** 2025-10-13  
**Version:** 1.0.0

For questions or issues, open an issue on GitHub or consult the community resources above.
