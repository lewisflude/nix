# Testing YubiKey Authentication After Rebuild

This guide provides safe testing procedures for YubiKey authentication changes.

## Safety First: Pre-Testing Checklist

Before logging out to test the greeter:

1. **Keep a backup session open** - Don't close your current session
2. **Test in a TTY first** - Verify authentication works without risking your graphical session
3. **Know your password** - Ensure you can still log in if YubiKey fails
4. **Have physical access** - Don't test remotely unless you have console access

## Phase 1: Non-Destructive Verification (Do This First!)

### 1.1 Verify PAM Configuration

Check that greetd's PAM config has the correct settings:

```bash
# Check greetd PAM configuration
cat /etc/pam.d/greetd

# Look for these key lines:
# - auth sufficient pam_u2f.so ... (NOT "required")
# - auth required pam_unix.so (password fallback)
```

Expected output should show:

- `auth sufficient` for pam_u2f (allows fallback)
- `auth required` for pam_unix (password auth)

### 1.2 Verify U2F Mappings File

```bash
# Check u2f_mappings exists and is readable
ls -la /etc/u2f_mappings
cat /etc/u2f_mappings

# Should show:
# -rw-r--r-- 1 root root ... /etc/u2f_mappings
# lewis:PaGbsjJa2IPXjK...
```

### 1.3 Test YubiKey Detection

```bash
# Test if YubiKey is detected
lsusb | grep -i yubi

# Or check dmesg
dmesg | tail -20 | grep -i usb

# Test pam_u2f directly
pamu2fcfg -u lewis -o pam://yubi -i pam://yubi
# Touch your YubiKey when prompted - should show your key details
```

### 1.4 Test sudo with YubiKey (Safe Test!)

Since sudo also uses u2fAuth, test it first:

```bash
# This should prompt for YubiKey touch
sudo -k  # Clear sudo cache
sudo ls

# Expected behavior:
# 1. Shows "Please touch the device"
# 2. Touch YubiKey → succeeds immediately
# 3. OR wait for timeout → falls back to password prompt
```

**If sudo works with YubiKey → Your PAM config is correct!**

## Phase 2: TTY Testing (Safer Than Greeter)

Test authentication in a TTY before risking your graphical session.

### 2.1 Switch to TTY

```bash
# Keep your current graphical session running!
# Switch to TTY2 (or TTY3-6)
Ctrl+Alt+F2
```

### 2.2 Test TTY Login with YubiKey

```
# At login prompt, enter username:
lewis

# System should display:
# "Please touch the device"

# Test 1: Touch YubiKey immediately
→ Should log in without password prompt

# Test 2: Wait for timeout (don't touch)
→ Should show password prompt
→ Enter password → should log in
```

### 2.3 Log Out and Test Again

```bash
# In TTY session:
exit

# Try logging in again, this time with password only
lewis
[wait for timeout or press Enter]
[enter password]
→ Should log in successfully
```

### 2.4 Return to Graphical Session

```bash
# Switch back to your graphical session
Ctrl+Alt+F1  # Usually F1 or F7
```

**If TTY login works → Greeter should work too!**

## Phase 3: Greeter Testing (Final Validation)

Only proceed if TTY testing succeeded.

### 3.1 Lock Screen Test (Less Risky)

Test screen lock first (easier to recover from):

```bash
# Lock your screen
# (Your keybind, or use loginctl)
loginctl lock-session

# At lock screen:
# 1. Try YubiKey touch → should unlock
# 2. Try password → should unlock
```

### 3.2 Full Greeter Test

**⚠️ Only do this if TTY and lock screen tests passed!**

```bash
# Log out to greeter
# Your compositor should have a logout command
# For niri: niri msg action quit

# Or from terminal:
loginctl terminate-user $USER
```

At the greeter (ReGreet):

1. **Test YubiKey Path:**
   - Enter username
   - Wait for "Please touch the device" message
   - Touch YubiKey
   - Should log in without password

2. **Test Password Fallback:**
   - Log out again
   - Enter username
   - DON'T touch YubiKey (wait for timeout)
   - Enter password when prompted
   - Should log in successfully

## Phase 4: Diagnostics (If Something Fails)

### 4.1 Check PAM Logs

```bash
# Real-time PAM authentication logs
sudo journalctl -xef | grep -i pam

# Or check recent PAM activity
sudo journalctl -u greetd.service --since "5 minutes ago"

# Look for errors like:
# - "pam_u2f: user not found" → Check /etc/u2f_mappings
# - "pam_u2f: no devices configured" → Re-run pamu2fcfg
# - "pam_u2f: authentication error" → YubiKey not touched or failed
```

### 4.2 Enable PAM Debug Mode

If tests fail, enable debug logging:

```nix
# In modules/nixos/core/security.nix
security.pam.u2f.settings = {
  debug = true;  # Change from false to true
};
```

Rebuild and check logs:

```bash
sudo nixos-rebuild switch
sudo journalctl -xef | grep pam_u2f
```

### 4.3 Check YubiKey Registration

```bash
# Verify your YubiKey is properly registered
pamu2fcfg -u lewis -o pam://yubi -i pam://yubi -v

# Should show:
# - Credential ID
# - Public key
# - Options: +presence
```

### 4.4 Test PAM Stack Manually

```bash
# Use pamtester to test authentication
sudo pamtester greetd lewis authenticate

# This will test the full PAM stack
# Expected: Prompts for YubiKey, then password fallback
```

## Common Issues and Solutions

### Issue 1: "Please touch the device" but nothing happens

**Diagnosis:** YubiKey not detected or wrong origin/appid

**Solution:**

```bash
# Check YubiKey is connected
lsusb | grep Yubico

# Check pcscd service is running
systemctl status pcscd

# Restart pcscd if needed
sudo systemctl restart pcscd
```

### Issue 2: YubiKey timeout takes too long

**Diagnosis:** Default timeout is ~15 seconds

**Solution:** Add `timeout=5` to pam_u2f settings:

```nix
security.pam.u2f.settings = {
  # ... other settings ...
  prompt_timeout = 5;  # Wait only 5 seconds before fallback
};
```

### Issue 3: Authentication fails completely

**Diagnosis:** PAM config error or corrupted u2f_mappings

**Solution:**

```bash
# Check PAM config syntax
sudo pam-auth-update --force

# Regenerate u2f_mappings
pamu2fcfg -u lewis -o pam://yubi -i pam://yubi > /tmp/u2f_keys
# Copy to system (will need to rebuild)
```

### Issue 4: Password prompt never appears

**Diagnosis:** pam_unix.so not configured correctly

**Solution:** Verify greetd PAM has:

```bash
cat /etc/pam.d/greetd | grep pam_unix
# Should show: auth required pam_unix.so
```

## Recovery Procedures

### If You Get Locked Out

1. **Boot to TTY2:**

   ```
   Ctrl+Alt+F2 at boot/login
   ```

2. **Log in with password only** (YubiKey timeout will allow this)

3. **Fix the config:**

   ```bash
   cd ~/.config/nix
   git diff  # See what changed
   git revert HEAD  # If needed
   sudo nixos-rebuild switch
   ```

4. **Alternative: Remove u2f_mappings temporarily:**

   ```bash
   # As root in TTY
   sudo mv /etc/u2f_mappings /etc/u2f_mappings.bak
   sudo nixos-rebuild switch
   # Now you can log in with password only
   ```

## Success Criteria

✅ Your authentication is working correctly if:

1. **YubiKey path works:**
   - Touch YubiKey → Logs in without password
   - Fast (< 2 seconds after touch)

2. **Password fallback works:**
   - Don't touch YubiKey → Shows password prompt
   - Enter password → Logs in successfully

3. **Both paths work consistently:**
   - TTY login works
   - Greeter login works
   - Screen lock/unlock works
   - sudo works

4. **No blocking behavior:**
   - Never stuck waiting forever
   - Always can fall back to password
   - No system lockouts

## Testing Checklist

Copy this checklist and mark off each test:

```
Pre-Flight Checks:
[ ] PAM config shows "auth sufficient" for u2f
[ ] /etc/u2f_mappings exists and is readable
[ ] lsusb shows YubiKey connected
[ ] pcscd service is running

Phase 1: Non-Destructive
[ ] sudo with YubiKey touch works
[ ] sudo with password fallback works

Phase 2: TTY Testing
[ ] TTY login with YubiKey works
[ ] TTY login with password works
[ ] Can switch back to graphical session

Phase 3: Lock Screen
[ ] Screen lock with YubiKey unlock works
[ ] Screen lock with password unlock works

Phase 4: Greeter (Final)
[ ] Greeter login with YubiKey works
[ ] Greeter login with password works
[ ] Multiple login/logout cycles work
```

## Additional Notes

- **YubiKey must be inserted before login** - It won't work if you plug it in after the prompt
- **Touch detection requires physical contact** - Proximity isn't enough
- **LED should flash** - If YubiKey LED doesn't flash, it's not receiving the auth request
- **Timeout is normal** - Waiting 10-15 seconds for password prompt is expected behavior

## Debugging Commands Reference

```bash
# View real-time authentication attempts
sudo journalctl -xef -u greetd.service

# Check PAM modules loaded
sudo pam-auth-update --package-status

# Test YubiKey directly
ykman info

# Check U2F support
ykman fido info

# View PAM configuration
ls -la /etc/pam.d/
cat /etc/pam.d/greetd

# Test pam_u2f module
pamtester -v greetd $USER authenticate
```

## See Also

- [YubiKey Setup Guide](https://developers.yubico.com/pam-u2f/)
- [PAM Configuration](https://linux.die.net/man/5/pam.conf)
- [NixOS PAM Module](https://search.nixos.org/options?query=security.pam)
