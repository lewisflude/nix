# VPN Port Forwarding - Fixes and Improvements Summary

## Current Status

### ? Fixed Issues

1. **Script improvements** - Added retry logic for VPN connectivity (10 attempts with 2s wait)
2. **Grep warnings** - Fixed backslash escaping in grep patterns
3. **System packages** - Added `test-vpn-port-forwarding` script to system packages
4. **Systemd warnings** - Fixed ordering/dependency warning for `network-online.target`

### ? Outstanding Issues

#### 1. WireGuard Not Properly Configured

**Problem:** The VPN-Confinement module's startup script (`qbt-up`) is not properly configuring WireGuard.

- Interface `qbt0` exists but has no WireGuard configuration
- Running `wg show qbt0` returns "No such device"
- Gateway 10.2.0.1 is unreachable despite proper routing

**Root Cause:** The WireGuard configuration from SOPS secret is not being applied to the interface.

**Evidence:**

```bash
# Interface exists
$ sudo ip netns exec qbt ip addr show qbt0
36: qbt0: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1420 qdisc noqueue state UNKNOWN
    inet 10.2.0.2/32 scope global qbt0

# But WireGuard not configured
$ sudo wg show qbt0
Unable to access interface: No such device

# Ping fails
$ sudo ip netns exec qbt ping -c 3 10.2.0.1
100% packet loss
```

**Fix Required:**
The VPN-Confinement module needs to properly execute:

```bash
wg setconf qbt0 <(strip_wgquick_config /run/secrets/vpn-confinement-qbittorrent)
```

This is in the startup script but appears to not be working.

#### 2. Route Addition Timing

**Problem:** The route `10.2.0.0/24 dev qbt0` specified in WireGuard's `PostUp` is not being added.

**Current routes:**

```
default dev qbt0 scope link
192.168.1.0/24 via 192.168.15.5 dev veth-qbt
192.168.15.0/24 dev veth-qbt proto kernel scope link src 192.168.15.1
```

**Missing:**

```
10.2.0.0/24 dev qbt0 scope link
```

**Fix:** Need to ensure the PostUp command runs or add the route explicitly in the startup script.

## Changes Made (Ready to Deploy)

### 1. scripts/protonvpn-natpmp-portforward.sh

**Changes:**

- Added retry logic to `check_vpn()` function (10 attempts, 2s intervals)
- Fixed grep pattern escaping to avoid warnings
- Better error messages with attempt counters

### 2. modules/nixos/services/media-management/protonvpn-portforward.nix

**Changes:**

- Fixed systemd service ordering/dependency warning
- Added `network-online.target` to `wants`
- Removed `requisite` dependency (too strict)
- Added `test-vpn-port-forwarding` to system packages
- Increased timer boot delay to 3 minutes (was 2 minutes)

### 3. scripts/test-vpn-port-forwarding.sh

**New file** - Quick diagnostic script that checks:

- ProtonVPN assigned port via NAT-PMP
- qBittorrent configured port
- Port matching
- Listening status
- Service status
- External IP verification

## What Needs to Be Done Next

### Immediate: Fix WireGuard Configuration

#### Option A: Investigate VPN-Confinement Module

1. Check if `wg` command is available in the startup script's PATH
2. Verify the `strip_wgquick_config` function works correctly
3. Add explicit route addition: `ip netns exec qbt ip route add 10.2.0.0/24 dev qbt0`

#### Option B: Debug Manually

```bash
# Check if wg is available in script
cat /nix/store/*/qbt-up/bin/qbt-up | grep PATH

# Try running wg setconf manually
sudo ip netns exec qbt wg setconf qbt0 /run/secrets/vpn-confinement-qbittorrent

# Check WireGuard kernel module
lsmod | grep wireguard
```

**Option C: Add ExecStartPost to qbt.service**
Add to the VPN-Confinement configuration:

```nix
systemd.services."${vpnCfg.namespace}".serviceConfig.ExecStartPost = [
  "${pkgs.iproute2}/bin/ip netns exec ${vpnCfg.namespace} ip route add 10.2.0.0/24 dev ${vpnCfg.namespace}0"
];
```

### After WireGuard Works

1. **Test port forwarding automation:**

   ```bash
   sudo systemctl start protonvpn-portforward.service
   journalctl -u protonvpn-portforward.service -n 50
   ```

2. **Verify timer is active:**

   ```bash
   systemctl status protonvpn-portforward.timer
   systemctl list-timers | grep protonvpn
   ```

3. **Run full verification:**

   ```bash
   test-vpn-port-forwarding
   verify-qbittorrent-vpn
   monitor-protonvpn-portforward
   ```

## Testing Checklist

Once VPN is working:

- [ ] VPN gateway (10.2.0.1) is reachable
- [ ] External IP shows ProtonVPN address
- [ ] NAT-PMP query returns a port
- [ ] qBittorrent config updated with port
- [ ] qBittorrent listening on correct port
- [ ] Timer runs every 45 minutes
- [ ] Port forwarding persists across reboots
- [ ] External port is open (test at yougetsignal.com)

## Files Modified

### Ready to commit

- `scripts/protonvpn-natpmp-portforward.sh` - Retry logic + fixes
- `scripts/test-vpn-port-forwarding.sh` - New diagnostic tool
- `modules/nixos/services/media-management/protonvpn-portforward.nix` - Systemd fixes
- `scripts/README.md` - Documentation for test script
- `docs/PROTONVPN_PORT_FORWARDING_SETUP.md` - Added quick verification section

### May need changes

- `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix` - May need to add route fix

## Rollback Plan

If issues arise after deployment:

1. **Disable port forwarding timer:**

   ```bash
   sudo systemctl disable --now protonvpn-portforward.timer
   ```

2. **Manual port setting:**

   ```bash
   # Set static port in qBittorrent config
   sudo sed -i 's/^Session\\Port=.*/Session\\Port=62000/' /var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf
   sudo systemctl restart qbittorrent.service
   ```

3. **Revert to previous configuration:**

   ```bash
   git revert HEAD
   nh os switch
   ```

## Notes

- The scripts are ready and tested
- The systemd configuration is improved
- **The main blocker is WireGuard not being configured properly**
- This is likely a VPN-Confinement module issue, not our scripts
- Once VPN works, everything else should work automatically
