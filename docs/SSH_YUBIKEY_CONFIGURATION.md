# SSH YubiKey Configuration - Analysis and Fixes

**Date:** 2025-01-20  
**Issue:** Passphrase prompts for "certify key" on first SSH use after login

## Problem Analysis

### What Was Happening

Your configuration had **two SSH authentication systems** running simultaneously:

1. **GPG Agent SSH** (intended): Configured to provide YubiKey-backed SSH authentication
2. **File-based SSH keys** (unintended fallback): Traditional `~/.ssh/id_ed25519` keys

The problem: Your `sshcontrol` file pointed to the **wrong keygrip**:
- **Configured**: `408B5C...` (encrypted Ed25519 file-based key)
- **Should be**: `495B10...` (YubiKey OpenPGP authentication key)

### Why Passphrase Prompts Occurred

When SSH tried to authenticate:
1. GPG agent looked for keygrip `408B5C...` from sshcontrol
2. Found it as an encrypted key on disk
3. Asked for your **GPG passphrase** to decrypt it
4. Cached the decrypted key for 24 hours
5. SSH then worked fine until next reboot

The confusing "certify key" error message was GPG agent trying to decrypt the disk-based key.

### Architecture Issues Identified

From multiple expert perspectives:

**Security**: System was only as secure as weakest method (file keys). Having YubiKey but not using it provided no security benefit.

**User Experience**: Passphrase prompts felt broken and weren't the intended YubiKey PIN prompts.

**Configuration**: Multiple SSH authentication paths created emergent behavior and confusion.

**Maintainability**: Config intent (YubiKey SSH) didn't match reality (file-based keys through GPG agent).

## The Fix

### Changed: `home/common/features/core/gpg.nix`

Updated `sshcontrol` to use YubiKey OpenPGP authentication key:

**Before:**
```
408B5C190D65BE8599A3ABBA3DB1E789761C0081  # Encrypted disk-based Ed25519 key
```

**After:**
```
495B10388160753867D2B6F7CAED2ED08F4D4323  # YubiKey OpenPGP Auth key (RSA 4096)
```

### Also Fixed: `home/nixos/hardware-tools/gnome-keyring.nix`

Removed conflicting GNOME Keyring SSH component:

**Before:**
```nix
components = [
  "secrets"
  "ssh"  # ❌ Conflicted with GPG agent
];
```

**After:**
```nix
components = [
  "secrets"
  # "ssh" - Disabled to avoid conflict with GPG agent SSH support
];
```

## Expected Behavior After Fix

### First SSH Use After Login

**You will see:**
```
Please enter PIN for YubiKey
[Touch required] *blink*
```

**This is CORRECT and EXPECTED:**
- YubiKey PIN (not passphrase) required once per session
- May require physical touch (security feature)
- PIN is cached for remainder of session

### Subsequent SSH Use

No prompts - completely seamless. The YubiKey authentication key is loaded and ready.

### Security Benefits

✅ **Hardware-backed authentication**: Private keys never leave YubiKey  
✅ **Immune to extraction**: Malware cannot steal keys  
✅ **Physical presence**: Requires YubiKey to be inserted  
✅ **Audit trail**: Physical device possession required  
✅ **Non-exportable**: Keys generated on YubiKey stay on YubiKey

## How It Works

### Authentication Flow

```
SSH Connection Request
    ↓
GPG Agent checks sshcontrol
    ↓
Finds keygrip 495B10... (YubiKey key)
    ↓
Requests YubiKey PIN (first use only)
    ↓
YubiKey performs authentication
    ↓
SSH connection succeeds
```

### Key Architecture

```
┌─────────────────────────────────────┐
│         SSH Connection              │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│         GPG Agent                   │
│  (SSH support enabled)              │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│         YubiKey                     │
│  OpenPGP Authentication Key         │
│  (RSA 4096, non-exportable)         │
└─────────────────────────────────────┘
```

## Verification Steps

After rebuilding your system, verify the configuration:

```bash
# 1. Check SSH agent socket is GPG agent
echo $SSH_AUTH_SOCK
# Should show: /run/user/1000/gnupg/S.gpg-agent.ssh

# 2. List available SSH keys
ssh-add -l
# Should show YubiKey keys with "cardno:30_043_632"

# 3. Check sshcontrol has correct keygrip
cat ~/.gnupg/sshcontrol
# Should show: 495B10388160753867D2B6F7CAED2ED08F4D4323

# 4. Test GitHub authentication
ssh -T git@github.com
# Should prompt for YubiKey PIN first time, then succeed
```

## Your YubiKey Keys

Your YubiKey (Serial: 30043632) has multiple authentication keys:

1. **OpenPGP RSA 4096** (PRIMARY for SSH)
   - Keygrip: `495B10388160753867D2B6F7CAED2ED08F4D4323`
   - SHA256: `RK1I2SGm1fOLgNpXWHrQD1xyqmLorayXhjqDzIbLlO8`
   - Used by: GPG agent for SSH

2. **PIV RSA 2048** (Available but not primary)
   - Keygrip: `B3E3BEABDF8033DF78B0D863C85AF5B01F9F0635`
   - SHA256: `y6lfRyGVehmIv26FuenUNdvjnL6pP96l69NhWG30rig`
   - Can be used for PKCS#11 or specific PIV scenarios

**Recommendation**: Stick with OpenPGP for SSH. PIV is useful for corporate environments requiring PKCS#11 but adds complexity.

## Alternative Configuration (Not Recommended)

If you prefer **simpler file-based SSH** without YubiKey:

### Option B: Disable GPG Agent SSH

```nix
# In home/common/features/core/gpg.nix
services.gpg-agent = {
  enable = true;
  enableSshSupport = false;  # ← Disable SSH support
  # ... rest of config
};

# Remove sshcontrol file
home.file.".gnupg/sshcontrol".enable = false;
```

**Trade-offs:**
- ✅ Simpler, no PIN prompts
- ✅ Works without YubiKey inserted
- ❌ Less secure (keys on disk)
- ❌ Doesn't utilize YubiKey capabilities
- ❌ Vulnerable to malware/theft

## Best Practices

### Security

1. **Enable touch requirement**: Add extra security by requiring physical touch
   ```bash
   ykman openpgp keys set-touch aut on
   ```

2. **Backup YubiKey**: Consider getting a second YubiKey with same keys
   - Keys must be backed up BEFORE moving to YubiKey
   - Once on YubiKey, they're non-exportable

3. **Strong PIN**: Use a strong YubiKey PIN (not just 4 digits)

### Usability

1. **PIN caching**: Your config caches PIN for 24 hours (reasonable)
2. **Touch detector**: You have `yubikey-touch-detector` for visual feedback
3. **Session management**: PIN persists for entire user session

### Maintenance

1. **Key expiration**: Your subkeys expire in 2027 - plan renewal
2. **Regular testing**: Periodically test YubiKey authentication
3. **Backup awareness**: Know your key backup location/procedure

## FAQ

**Q: Why PIN instead of passphrase?**  
A: YubiKey has its own PIN (hardware-level). GPG passphrase is for encrypted disk keys.

**Q: What if I lose my YubiKey?**  
A: You need backup keys. Either:
- Backup YubiKey with same keys
- Keep master key backup in secure location
- Emergency recovery keys on other systems

**Q: Can I use both YubiKey and file keys?**  
A: Technically yes, but not recommended. Reduces security to weakest method.

**Q: What about git commit signing?**  
A: Still works! GPG agent uses YubiKey for both SSH auth and commit signing.

**Q: Performance impact?**  
A: Minimal. First SSH connection per session has ~1-2 second delay for PIN entry.

## Industry Best Practices

Based on research and expert analysis:

### When to Use YubiKey SSH

✅ **High-security scenarios:**
- Production server access
- Infrastructure administration
- Compliance-required systems
- High-value GitHub/GitLab accounts

✅ **Developer workstations:**
- As primary authentication (this setup)
- With backup authentication methods

### When to Consider File-Based SSH

✅ **Low-stakes environments:**
- Personal projects
- Local development networks
- Automated scripts/CI (use dedicated keys)

### Hybrid Approach (Not Recommended Here)

Some organizations use:
- YubiKey for production
- File keys for development

This adds complexity and requires careful SSH config management per host.

## References

- [drduh YubiKey Guide](https://github.com/drduh/YubiKey-Guide) - Comprehensive guide
- [Yubico OpenPGP SSH](https://developers.yubico.com/PGP/SSH_authentication/) - Official docs
- [NIST 800-63B](https://pages.nist.gov/800-63-3/sp800-63b.html) - Authentication guidelines
- Your config: `home/common/features/core/gpg.nix` and `ssh.nix`

## Troubleshooting

### "No such file or directory" for sshcontrol

Rebuild system to apply changes:
```bash
nh os switch
```

### YubiKey not detected

```bash
# Check if YubiKey is visible
gpg --card-status

# Restart GPG agent
gpgconf --kill gpg-agent
```

### Still getting passphrase prompts

1. Check SSH_AUTH_SOCK points to GPG agent
2. Verify sshcontrol has correct keygrip
3. Ensure no other SSH agents running

### "Invalid IPC response" errors

Restart GPG agent:
```bash
gpgconf --kill gpg-agent
# Agent restarts automatically on next use
```

---

**Conclusion**: Your configuration now properly implements hardware-backed SSH authentication via YubiKey, providing strong security with reasonable usability trade-offs. The one PIN prompt per session is the expected behavior for this security model.
