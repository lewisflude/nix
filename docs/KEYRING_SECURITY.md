# GNOME Keyring Security with YubiKey Authentication

## Overview

This system uses YubiKey for passwordless authentication. This document explains the keyring security model and best practices.

## Security Model

### System Authentication (Strong Security Boundary)

- **YubiKey U2F**: Hardware-based, phishing-resistant authentication
- **Password fallback**: Available when YubiKey is not present
- **PAM integration**: Configured in `modules/nixos/core/security.nix`

### Keyring Security (Application Secrets)

- **Login keyring**: Auto-unlocks on session start (empty password)
- **Secure keyrings**: Optional, manually unlocked with password

## Why Empty Password on Login Keyring?

### Industry Standard Approach

This is the standard approach used by:

- Ubuntu with auto-login
- Fedora Workstation with fingerprint auth
- Enterprise GNOME deployments with smart cards
- macOS with Touch ID

### Security Reasoning

1. **Real security boundary is system auth**: If an attacker bypasses your YubiKey, they have system access
2. **Session access = keyring access**: Apps running in your session can already request keyring secrets
3. **Convenience matters**: Passwordless auth shouldn't require password for every app
4. **Physical access required**: Keyring is encrypted at rest, only accessible in your running session

### What This Protects Against

- ✅ Remote attacks (keyring encrypted on disk)
- ✅ Theft while powered off (keyring encrypted, requires YubiKey to boot/login)
- ✅ Unauthorized system access (YubiKey required)

### What This Doesn't Protect Against

- ❌ Attacker with access to your running, unlocked desktop session
  - *But: They could already access keyring via any running app*

## Recommended Setup

### 1. Login Keyring (Empty Password)

**Purpose**: Store routine application secrets

- Browser passwords
- WiFi passwords
- Email/chat client credentials
- Application tokens

**Setup**:

```bash
# Delete existing login keyring
rm ~/.local/share/keyrings/login.keyring

# Let it auto-create with empty password on next login
# The unlock-login-keyring.service will handle this
```

**How it works**:

- System service: `unlock-login-keyring.service` (see `modules/nixos/core/security.nix`)
- Automatically unlocks on session start with empty password
- Apps can access secrets without prompting

### 2. Secure Keyring (Optional, With Password)

**Purpose**: Store sensitive secrets that require manual unlock

- GPG private key passwords
- SSH key passphrases (if not using agent)
- Cryptocurrency wallet passwords
- Financial application credentials

**Setup**:

```bash
# Create a new secure keyring using Seahorse
seahorse

# In Seahorse:
# 1. File → New → Password Keyring
# 2. Name it "Secure" (or any name)
# 3. Set a strong password
# 4. Move sensitive secrets to this keyring
```

**How it works**:

- Remains locked after login
- Apps prompt for keyring password when accessing secrets
- You control when to unlock it

## Manual Configuration

### Set Login Keyring to Empty Password

**Using Seahorse (GUI)**:

```bash
seahorse
```

1. Find "Login" keyring in left sidebar
2. Right-click → "Change Password"
3. Enter current password
4. Leave new password fields empty
5. Confirm

**Using command line**:

```bash
# This will prompt for old password, then new (press Enter for empty)
gnome-keyring-daemon --replace
secret-tool lock

# Unlock with empty password
printf '\n' | gnome-keyring-daemon --unlock
```

### Verify Auto-Unlock Works

After next login:

```bash
# Check if keyring is unlocked
secret-tool lookup dummy dummy

# Expected output: "No such secret in the keyring"
# (This means keyring is unlocked and accessible)

# If locked, you'll see: "The keyring is locked"
```

## Alternative: Always Require Password

If you prefer to ALWAYS enter your password for keyring unlock (even with YubiKey):

### Option A: Use Password Instead of YubiKey

- Don't touch YubiKey at login prompt
- Enter password instead
- This unlocks both system and keyring

### Option B: Manual Keyring Unlock

- Authenticate with YubiKey
- Accept that keyring stays locked
- Manually unlock when needed:

  ```bash
  secret-tool lookup dummy dummy
  # Enter keyring password when prompted
  ```

### Option C: Modify PAM (Advanced, Not Recommended)

Change PAM flow to require password AFTER YubiKey:

```nix
# In modules/nixos/core/security.nix, change:
auth sufficient ${pkgs.pam_u2f}/lib/security/pam_u2f.so ...
# To:
auth required ${pkgs.pam_u2f}/lib/security/pam_u2f.so ...
# Then require password too
```

**Downside**: This is 2FA (both required), defeats passwordless convenience.

## Security Considerations

### Threat Model

| Threat | Mitigation |
|--------|------------|
| Remote attacker | YubiKey required for system access |
| Physical theft (powered off) | Disk encryption + YubiKey required |
| Evil maid attack | YubiKey with user presence detection |
| Malware in running session | No mitigation (but malware could access keyring anyway) |
| Shoulder surfing | YubiKey has no password to observe |

### Trade-offs

| Approach | Security | Convenience |
|----------|----------|-------------|
| Empty login keyring | Good (system auth is boundary) | Excellent |
| Locked keyring | Marginal improvement | Poor (constant prompts) |
| Separate keyrings | Best (granular control) | Good |

## Comparison with Other Systems

### macOS + Touch ID

- System: Touch ID (biometric)
- Keychain: Auto-unlocks on successful Touch ID
- Secure items: Require Touch ID per-access

### Windows + Windows Hello

- System: Windows Hello (biometric/PIN)
- Credential Manager: Auto-unlocks on login
- BitLocker: Separate TPM-based encryption

### Linux + Fingerprint Reader

- System: Fingerprint authentication
- GNOME Keyring: Auto-unlocks (same as empty password)
- Secure secrets: Optional separate keyring

**Our approach matches industry standard for hardware-based authentication.**

## Troubleshooting

### Keyring Not Auto-Unlocking

Check service status:

```bash
systemctl --user status unlock-login-keyring.service
```

Check if keyring has non-empty password:

```bash
# Try unlocking with empty password
printf '\n' | gnome-keyring-daemon --unlock

# If it fails, keyring has a password
```

### Apps Keep Asking for Keyring Password

Your login keyring still has a password. Follow setup steps above to set empty password.

### Want to Lock Keyring Manually

```bash
# Lock all keyrings
secret-tool lock

# Lock specific keyring
dbus-send --session --print-reply \
  --dest=org.freedesktop.secrets \
  /org/freedesktop/secrets/collection/login \
  org.freedesktop.Secret.Collection.Lock
```

## References

- [GNOME Keyring Architecture](https://wiki.gnome.org/Projects/GnomeKeyring/Architecture)
- [Ubuntu Auto-Login Keyring](https://help.ubuntu.com/stable/ubuntu-help/user-goodpassword.html)
- [Yubico PAM U2F Documentation](https://developers.yubico.com/pam-u2f/)
- [Arch Linux GNOME Keyring Guide](https://wiki.archlinux.org/title/GNOME/Keyring)

## Summary

**Best Practice for YubiKey + GNOME Keyring**:

1. ✅ Use empty password on login keyring (auto-unlock)
2. ✅ Create separate secure keyring for truly sensitive secrets
3. ✅ Trust YubiKey as your primary security boundary
4. ✅ Follow industry-standard approach used by major distros

This provides excellent security with optimal user experience.
