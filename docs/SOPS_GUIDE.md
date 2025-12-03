# SOPS-nix Secret Management Guide

## Overview

This project uses **sops-nix** for declarative secrets management with age encryption. Secrets are encrypted before being committed to git, ensuring secure version control while maintaining the benefits of declarative configuration.

**Key Features:**
- ✅ Age-based encryption (modern, fast, secure)
- ✅ GPG fallback for additional security layers
- ✅ Per-host and per-user secret isolation
- ✅ Atomic secret deployment
- ✅ Git-friendly encrypted storage

## Architecture

### Encryption Flow

```
Plaintext Secret → SOPS Encryption → Encrypted File (git) → NixOS Build → Decrypted Secret (/run/secrets)
                      ↑
                   age keys
```

### Key Locations

**Linux (NixOS):**
- System key: `/var/lib/sops-nix/key.txt`
- SSH host key: `/etc/ssh/ssh_host_ed25519_key` (converted to age)

**macOS (nix-darwin):**
- User key: `~/.config/sops-nix/key.txt`
- No SSH key auto-detection (disabled for security)

**Admin Keys:**
- Age key: `~/.config/sops/age/keys.txt` (or `~/Library/Application Support/sops/age/keys.txt` on macOS)
- GPG key: In GPG keyring (`gpg --list-secret-keys`)

## Configuration Structure

### .sops.yaml Explanation

The `.sops.yaml` file defines encryption keys and access rules:

```yaml
keys:
  # Admin keys (decrypt all secrets)
  - &admin_lewis_gpg 7369D9C25A365E6C926ADBAB48B34CF9C735A6AE
  - &admin_lewis_age age1lzf4exwy6guezs2wqftd5hf5ftkcjmcvd7lyukvud66py9pk4aeqwx2p9h

  # Host keys (machine-specific)
  - &jupiter_age age1dn3panz9kx6g6petqm8lyund72gslwt29p6grlq9cf5t3cd68gcqxlv289
  - &mercury_age age15q885zhzw0x5kk75upc30cql3nhkj7ugrxr0gs80tds988acgetszzd4px
  - &macbook_age age164pr400e5gz2vnwarmq3uwymj2krhagvsx5dh0nautczkha8eqds2jq2k2
```

**Key Groups:**
- Uses YAML anchors (`&name`) for reusable references
- Admin keys can decrypt all secrets
- Host keys only decrypt secrets for their specific machine
- Multiple keys in a group = OR operation (any key can decrypt)

### Secret Organization

| Path | Encrypted For | Purpose |
|------|---------------|---------|
| `secrets/secrets.yaml` | All hosts + admin | System-wide secrets |
| `secrets/user.yaml` | macOS + admin | User-specific secrets |
| `hosts/jupiter/secrets.yaml` | Jupiter + admin | Jupiter-only secrets |
| `hosts/mercury/secrets.yaml` | Mercury + admin | Mercury-only secrets |

## Common Operations

### 1. Viewing Secrets

```bash
# View encrypted secret (requires appropriate key)
sops secrets/secrets.yaml

# View specific key
sops -d --extract '["GITHUB_TOKEN"]' secrets/secrets.yaml
```

### 2. Adding New Secrets

```bash
# Edit secrets file (SOPS editor opens automatically)
sops secrets/secrets.yaml

# Add new key-value pair:
# SOPS will encrypt when you save

# Example content:
# GITHUB_TOKEN: ghp_xxxxxxxxxxxx
# NEW_API_KEY: sk-xxxxxxxxxxxx
```

**Then declare in NixOS configuration:**

```nix
# modules/shared/sops.nix
sops.secrets.NEW_API_KEY = {
  sopsFile = ../../secrets/secrets.yaml;
  owner = config.host.username;
  mode = "0400";
};
```

### 3. Updating Existing Secrets

```bash
# Edit secrets file
sops secrets/secrets.yaml

# Modify value, save
# SOPS automatically re-encrypts with existing keys
```

### 4. Rotating Secret Values

**For sensitive data that may have been compromised:**

```bash
# 1. Edit the secret file
sops secrets/secrets.yaml

# 2. Change the secret value
# Example: Generate new API key from service provider
# Update the value in SOPS

# 3. Save (SOPS encrypts automatically)

# 4. Commit to git
git add secrets/secrets.yaml
git commit -m "rotate: Update compromised API key"

# 5. Deploy to affected hosts
nh os switch  # On NixOS
darwin-rebuild switch  # On macOS
```

## Key Management

### Backing Up Keys

**CRITICAL: If you lose your age key, encrypted secrets are UNRECOVERABLE.**

#### Admin Keys

```bash
# Linux
cp ~/.config/sops/age/keys.txt ~/backup/sops-age-key-$(date +%Y%m%d).txt

# macOS
cp ~/Library/Application\ Support/sops/age/keys.txt ~/backup/sops-age-key-$(date +%Y%m%d).txt

# Store in password manager (recommended)
# 1. Open password manager (1Password, Bitwarden, etc.)
# 2. Create secure note: "SOPS Age Key - Admin"
# 3. Copy contents of keys.txt
# 4. Add recovery instructions
```

#### Host Keys

```bash
# On each NixOS host
sudo cp /var/lib/sops-nix/key.txt ~/backup/sops-$(hostname)-$(date +%Y%m%d).txt
sudo chown $USER:users ~/backup/sops-$(hostname)-$(date +%Y%m%d).txt

# On macOS
cp ~/.config/sops-nix/key.txt ~/backup/sops-$(hostname)-$(date +%Y%m%d).txt

# Store securely (encrypted backup, password manager)
```

### Generating New Host Keys

**When setting up a new machine:**

```bash
# 1. Generate age key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# 2. Extract public key
age-keygen -y ~/.config/sops/age/keys.txt
# Output: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 3. Add to .sops.yaml
# Edit .sops.yaml and add:
# - &new_host_age age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 4. Update creation rules to include new host key
```

### Key Rotation (Security Best Practice)

**Rotate keys when:**
- A team member leaves
- A host is decommissioned
- Keys may have been compromised
- Annually as preventive measure

**Procedure:**

```bash
# 1. Generate new age key
age-keygen -o ~/.config/sops/age/keys-new.txt

# 2. Extract new public key
NEW_KEY=$(age-keygen -y ~/.config/sops/age/keys-new.txt)
echo "New key: $NEW_KEY"

# 3. Update .sops.yaml with new key
# Add new key anchor, update creation rules

# 4. Re-encrypt all secrets with new key set
sops updatekeys secrets/secrets.yaml
sops updatekeys secrets/user.yaml
sops updatekeys hosts/jupiter/secrets.yaml
sops updatekeys hosts/mercury/secrets.yaml

# 5. Test decryption with new key
sops secrets/secrets.yaml

# 6. Replace old key with new key
mv ~/.config/sops/age/keys-new.txt ~/.config/sops/age/keys.txt

# 7. Commit updated secrets
git add .sops.yaml secrets/
git commit -m "security: Rotate age encryption keys"

# 8. Deploy to all hosts
# Secrets will be accessible with new key
```

### Removing Access (Offboarding)

**When removing a team member's access:**

```bash
# 1. Remove their key from .sops.yaml
# Edit .sops.yaml:
# - Delete their key anchor (&their_name_age)
# - Remove from all creation_rules where referenced

# 2. Re-encrypt all secrets (removes their access)
find secrets/ -name "*.yaml" -exec sops updatekeys {} \;
find hosts/ -name "secrets.yaml" -exec sops updatekeys {} \;

# 3. Verify they can no longer decrypt
# (Test with their key if available)

# 4. Commit changes
git add .sops.yaml secrets/ hosts/
git commit -m "security: Remove access for departing team member"

# 5. Optional: Rotate secret values for defense in depth
# Follow "Rotating Secret Values" procedure above
```

## Adding New Hosts

**When adding a new system to the fleet:**

```bash
# 1. On new host, get the age public key
# NixOS generates this automatically in /var/lib/sops-nix/key.txt
# Or generate manually:
age-keygen -o /tmp/newhost-key.txt
age-keygen -y /tmp/newhost-key.txt

# 2. Add to .sops.yaml
keys:
  - &newhost_age age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 3. Add host-specific rules
- path_regex: hosts/newhost/secrets\.yaml$
  key_groups:
    - pgp:
        - *admin_lewis_gpg
      age:
        - *admin_lewis_age
        - *newhost_age

# 4. Update system secrets to include new host
- path_regex: secrets/secrets\.yaml$
  key_groups:
    - pgp:
        - *admin_lewis_gpg
      age:
        - *admin_lewis_age
        - *jupiter_age
        - *mercury_age
        - *macbook_age
        - *newhost_age  # Add here

# 5. Re-encrypt secrets with new key
sops updatekeys secrets/secrets.yaml

# 6. Create host-specific secrets file if needed
sops hosts/newhost/secrets.yaml

# 7. Commit and deploy
git add .sops.yaml secrets/ hosts/newhost/
git commit -m "feat: Add sops configuration for newhost"
```

## Troubleshooting

### "Failed to get the data key required to decrypt"

**Cause:** Your machine's age key is not in the `.sops.yaml` for this secret file.

**Solution:**
```bash
# 1. Check which keys can decrypt
sops secrets/secrets.yaml  # Shows error if you can't decrypt

# 2. Add your key to .sops.yaml
# Get your public key:
age-keygen -y /var/lib/sops-nix/key.txt  # Linux
age-keygen -y ~/.config/sops-nix/key.txt  # macOS

# 3. Update .sops.yaml with your key
# 4. Ask admin to re-encrypt: sops updatekeys secrets/secrets.yaml
```

### "MAC mismatch" or corrupted secrets

**Cause:** Secret file was manually edited while encrypted, or merge conflict.

**Solution:**
```bash
# 1. Restore from git if corrupted
git checkout secrets/secrets.yaml

# 2. If merge conflict, choose one version fully
# NEVER manually edit encrypted sections

# 3. Re-edit properly
sops secrets/secrets.yaml
```

### Missing secrets in /run/secrets

**Cause:** Secret not declared in NixOS configuration, or deployment failed.

**Solution:**
```bash
# 1. Verify secret is declared
grep -r "sops.secrets.YOUR_SECRET" modules/

# 2. Check systemd service
systemctl status sops-secrets.service

# 3. Check for errors
journalctl -u sops-secrets.service -n 50

# 4. Rebuild
nh os switch  # Or darwin-rebuild switch
```

### Permission denied accessing /run/secrets/SECRET

**Cause:** Service user doesn't have permission to read secret.

**Solution:**
```nix
# Adjust secret permissions
sops.secrets.YOUR_SECRET = {
  owner = "serviceuser";  # Or add service to "keys" group
  group = "keys";
  mode = "0440";  # Group readable
};
```

## Security Best Practices

### ✅ DO

- **Back up keys immediately** to password manager
- **Use age for all new secrets** (modern, simpler)
- **Encrypt before commit** (never commit plaintext)
- **Use host-specific secrets** for machine-specific data
- **Rotate keys annually** or when team changes
- **Test decryption** after key rotation
- **Use minimal permissions** (mode 0400 unless group access needed)
- **Document secret purpose** in NixOS config comments

### ❌ DON'T

- **Don't share age keys** between team members (each person has their own admin key)
- **Don't commit plaintext secrets** (always use SOPS)
- **Don't manually edit encrypted sections** (use `sops` command)
- **Don't use `--shamir-secret-sharing` unless needed** (avoid dashes before age/pgp in key_groups)
- **Don't store keys unencrypted on cloud** (use password manager)
- **Don't skip key backups** (keys are unrecoverable if lost)
- **Don't use root-owned secrets** for user services (set appropriate owner)

## Integration with NixOS

### Declaring Secrets

```nix
# modules/shared/sops.nix
sops = {
  age = {
    keyFile = "/var/lib/sops-nix/key.txt";  # Linux
    # keyFile = "~/.config/sops-nix/key.txt";  # macOS
    generateKey = true;  # Auto-generate if missing
  };

  defaultSopsFile = ../../secrets/secrets.yaml;

  secrets = {
    # System secret (root:root 0400)
    GITHUB_TOKEN = { };

    # User-accessible secret
    OPENAI_API_KEY = {
      owner = config.host.username;
      mode = "0400";
    };

    # Service secret (custom owner)
    DATABASE_PASSWORD = {
      owner = "postgres";
      group = "postgres";
      mode = "0440";
    };

    # Secret from different file
    HOST_SPECIFIC_KEY = {
      sopsFile = ../../hosts/${config.host.hostname}/secrets.yaml;
    };
  };
};
```

### Using Secrets in Services

```nix
# Reference secret path in services
systemd.services.myservice = {
  serviceConfig = {
    EnvironmentFile = config.sops.secrets.SERVICE_VARS.path;
    # Secret available as environment variable
  };
};

# Or load directly
environment.systemPackages = [
  (pkgs.writeShellScriptBin "deploy-script" ''
    export API_KEY=$(cat ${config.sops.secrets.API_KEY.path})
    curl -H "Authorization: Bearer $API_KEY" https://api.example.com
  '')
];
```

## Quick Reference

### Common Commands

```bash
# Edit secrets
sops secrets/secrets.yaml

# View secrets (decrypted)
sops -d secrets/secrets.yaml

# Extract specific key
sops -d --extract '["KEY_NAME"]' secrets/secrets.yaml

# Update encryption keys after .sops.yaml changes
sops updatekeys secrets/secrets.yaml

# Re-encrypt all secrets
find secrets/ -name "*.yaml" -exec sops updatekeys {} \;

# Generate new age key
age-keygen -o ~/.config/sops/age/keys.txt

# Get public key
age-keygen -y ~/.config/sops/age/keys.txt

# Rotate all secrets
sops updatekeys secrets/secrets.yaml
sops updatekeys secrets/user.yaml
find hosts/ -name "secrets.yaml" -exec sops updatekeys {} \;
```

### File Locations

| Item | Linux | macOS |
|------|-------|-------|
| System age key | `/var/lib/sops-nix/key.txt` | `~/.config/sops-nix/key.txt` |
| Admin age key | `~/.config/sops/age/keys.txt` | `~/Library/Application Support/sops/age/keys.txt` |
| GPG key | `~/.gnupg/` | `~/.gnupg/` |
| Decrypted secrets | `/run/secrets/` | `/run/secrets/` (symlink to `/run/secrets.d/*`) |
| SOPS config | `.sops.yaml` (repo root) | `.sops.yaml` (repo root) |

## Maintenance Schedule

### Weekly
- None required (secrets are managed declaratively)

### Monthly
- Review secret access logs
- Audit which secrets are in use
- Check for deprecated secrets

### Quarterly
- Test secret restoration from backup
- Review `.sops.yaml` for accuracy
- Update documentation for new patterns

### Annually
- **Rotate all encryption keys** (security best practice)
- Review team access (offboard departed members)
- Audit secret file organization
- Test disaster recovery procedures

## Further Reading

- [sops-nix GitHub](https://github.com/Mic92/sops-nix)
- [SOPS Documentation](https://github.com/mozilla/sops)
- [Age Encryption](https://age-encryption.org/)
- [NixOS Secrets Management](https://nixos.wiki/wiki/Sops-nix)
