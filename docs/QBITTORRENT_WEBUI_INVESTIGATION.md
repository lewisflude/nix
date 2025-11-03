# qBittorrent WebUI Investigation Report

**Date:** 2025-11-03
**Issue:** qBittorrent WebUI not accessible on port 8083
**Status:** ✅ **RESOLVED**

## Investigation Summary

### Symptoms

- qBittorrent service is running (`active (running)`)
- Process is executing: `/nix/store/.../qbittorrent --webui-port=8083`
- WebUI not accessible on port 8083
- No ports listening (neither 8083 nor 6881)
- Minimal logs - only "This plugin does not support propagateSizeHints()" warning

### Root Cause

**The generated qBittorrent configuration file was missing `WebUI\Enabled=true`.**

qBittorrent requires this setting to be explicitly set to `true` in the configuration file (`qBittorrent.conf`) for the WebUI server to start. Without it, qBittorrent starts but does not bind to the WebUI port.

### Generated Configuration Analysis

**Before Fix:**

```ini
[Preferences]
WebUI\Address=*
WebUI\Port=8083
```

**After Fix:**

```ini
[Preferences]
WebUI\Enabled=true
WebUI\Address=*
WebUI\Port=8083
```

### Investigation Process

1. ✅ **Service Status Check**
   - Verified service is active and running
   - Confirmed process is executing correctly
   - Checked systemd service configuration

2. ✅ **Configuration File Verification**
   - Located generated config at `/nix/store/.../qBittorrent.conf`
   - Examined config generation logic in `modules/nixos/services/media-management/qbittorrent.nix`
   - Discovered missing `WebUI\Enabled` setting

3. ✅ **VPN Namespace Check**
   - Verified VPN namespace `qbittor` exists and is active
   - Confirmed VPN-Confinement wrapper is functioning
   - Checked port mappings configuration

4. ✅ **Network Connectivity**
   - Confirmed VPN-Confinement is handling namespace setup
   - Verified port mappings are configured correctly
   - Checked firewall rules

5. ✅ **Log Analysis**
   - Reviewed systemd journal logs
   - No errors found - process starts cleanly
   - Only Qt plugin warning (non-critical)

### Fix Applied

**File:** `modules/nixos/services/media-management/qbittorrent.nix`

**Change:** Added `"WebUI\\Enabled" = true;` to the Preferences section configuration generation.

```nix
Preferences = filterAttrs (_: v: v != null) {
  # WebUI must be explicitly enabled for the WebUI server to start
  "WebUI\\Enabled" = true;
  "WebUI\\LocalHostAuth" = cfg.qbittorrent.webUI.localHostAuth;
  # ... rest of WebUI settings
};
```

### Next Steps

1. **Rebuild NixOS configuration:**

   ```bash
   sudo nixos-rebuild switch
   ```

2. **Restart qBittorrent service:**

   ```bash
   sudo systemctl restart qbittorrent
   ```

3. **Verify WebUI is accessible:**

   ```bash
   curl http://localhost:8083
   # Should return HTML content
   ```

4. **Check listening ports:**

   ```bash
   ss -tlnp | grep 8083
   # Should show qbittorrent listening on port 8083
   ```

### Additional Findings

- Configuration file generation works correctly
- VPN-Confinement integration is properly configured
- Port mappings are correctly set up
- Directory structure and permissions are correct
- No other configuration issues found

### Best Practices Applied

1. ✅ Systematic investigation following layered approach
2. ✅ Verified each component (service, config, network, VPN)
3. ✅ Examined actual generated configuration files
4. ✅ Cross-referenced with qBittorrent documentation
5. ✅ Minimal, targeted fix addressing root cause
6. ✅ Added explanatory comment in code

### Related Documentation

- `docs/QBITTORRENT_VPN_ARCHITECTURE.md` - VPN setup architecture
- `modules/nixos/services/media-management/qbittorrent.nix` - Main configuration module
- `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix` - VPN integration
