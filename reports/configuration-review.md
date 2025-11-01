# Configuration Review - Potential Issues Check

## ✅ Issues Fixed

1. **Routing Conflict** - Fixed `accessibleFrom` default including `10.0.0.0/8` which conflicted with VPN addresses

## ⚠️ Potential Issues Found

### 1. Proxy Auto-Enable Logic

**Location:** `modules/nixos/services/media-management/qbittorrent.nix` line 26-27

**Current Logic:**

```nix
proxyAutoEnabled =
  qbtVpnEnabled && (vpnCfg.proxy.enable || (cfg.prowlarr.enable && cfg.prowlarr.useVpnProxy));
```

**Status:** ✅ **CORRECT** - Proxy will be enabled automatically since:

- `cfg.prowlarr.enable` defaults to `true` (from shared options)
- `cfg.prowlarr.useVpnProxy = true` (from your config)
- So proxy will auto-enable ✅

### 2. Prowlarr Proxy Configuration

**Location:** `hosts/jupiter/default.nix` line 134-137

**Current Config:**

```nix
prowlarr = {
  useVpnProxy = true;
  proxyType = "socks5"; # Use SOCKS5 proxy (Dante) - alternative: "http" for Privoxy
};
```

**Status:** ✅ **CORRECT** - Configuration looks good. Note: Comment mentions "Dante" but actual implementation uses `3proxy` which supports both HTTP and SOCKS5.

**Recommendation:** Update comment to reflect actual implementation:

```nix
proxyType = "socks5"; # Use SOCKS5 proxy (3proxy) - alternative: "http" for HTTP proxy
```

### 3. HTTP Timeout Issue

**Symptom:** HTTP connects but times out waiting for response

**Possible Causes:**

1. **iptables FORWARD policy is DROP** - VPN-Confinement sets `FORWARD DROP` but this shouldn't affect outgoing traffic from the namespace
2. **Response routing** - Responses might not be routed back correctly
3. **MTU size** - WireGuard MTU might be too large (should be ~1420)

**Investigation Needed:**

```bash
# Check FORWARD rules
sudo ip netns exec qbt iptables -L FORWARD -n -v

# Check MTU
sudo ip netns exec qbt ip link show qbt0 | grep mtu

# Test if reducing MTU helps
sudo ip netns exec qbt ip link set qbt0 mtu 1280
sudo ip netns exec qbt curl http://example.com
```

### 4. VPN Address Range Documentation

**Location:** `modules/nixos/services/media-management/qbittorrent.nix` line 492

**Issue:** The comment mentions excluding VPN range but doesn't specify which range

**Recommendation:** Add more specific documentation:

```nix
# Note: 10.0.0.0/8 removed from default to avoid conflict with VPN addresses
# ProtonVPN uses 10.2.0.0/16 range. If using other VPN providers, check their address range.
# If you need access from 10.x.x.x networks, add specific subnets excluding VPN range
```

### 5. TODO Comment in Config

**Location:** `hosts/jupiter/default.nix` line 115-117

**Current:**

```nix
# TODO: Update to Netherlands ProtonVPN server
# Get from: ProtonVPN Dashboard → WireGuard → Generate config for Netherlands
# Format: nl-*.protonvpn.net:51820 or specific IP:51820
```

**Status:** ⚠️ **INFO** - This is just a TODO note, not an error. Current endpoint (`185.107.44.110:51820`) appears to be working.

### 6. StartLimitIntervalSec Deprecation Warning

**Location:** `modules/nixos/services/media-management/qbittorrent.nix` line 763

**Issue:** Journal shows: `Unknown key 'StartLimitIntervalSec' in section [Service], ignoring`

**Fix:** Should use `StartLimitInterval` instead (without `Sec` suffix)

**Current:**

```nix
serviceConfig.StartLimitIntervalSec = "60s";
```

**Should be:**

```nix
serviceConfig.StartLimitInterval = "60s";
```

## Summary

### Critical Issues

- ✅ **FIXED:** Routing conflict with `10.0.0.0/8` in `accessibleFrom`

### Minor Issues

- ⚠️ `StartLimitIntervalSec` should be `StartLimitInterval` (deprecation warning)
- 📝 Comment mentions "Dante" but implementation uses "3proxy"

### Needs Investigation

- 🔍 HTTP timeout issue - requires testing after rebuild
- 🔍 MTU size might need adjustment

## Recommended Actions

1. **Rebuild configuration** to apply the routing fix:

   ```bash
   sudo nixos-rebuild switch
   ```

2. **Fix deprecation warning:**

   ```nix
   # Change line 763 in qbittorrent.nix
   serviceConfig.StartLimitInterval = "60s";  # Remove "Sec" suffix
   ```

3. **Test connectivity after rebuild:**

   ```bash
   sudo ip netns exec qbt ip route show
   sudo ip netns exec qbt curl https://torrent.blmt.io
   ```

4. **If HTTP still times out**, check MTU:

   ```bash
   sudo ip netns exec qbt ip link set qbt0 mtu 1280
   sudo ip netns exec qbt curl http://example.com
   ```

## Configuration Health Check

| Component | Status | Notes |
|-----------|--------|-------|
| WireGuard Config | ✅ Match | Matches ProtonVPN config |
| VPN Routing | ✅ Fixed | Removed conflicting route |
| Proxy Auto-Enable | ✅ Correct | Will enable for Prowlarr |
| DNS Configuration | ✅ Correct | Uses VPN DNS (10.2.0.1) |
| Port Configuration | ✅ Correct | Fixed port (6881), no randomization |
| Service Dependencies | ✅ Correct | Proper service ordering |
| StartLimitIntervalSec | ⚠️ Warning | Should be StartLimitInterval |

Overall, your configuration looks good! The main issue was the routing conflict, which is now fixed.
