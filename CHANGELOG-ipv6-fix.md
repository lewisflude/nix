# IPv6 Port Forwarding Fix for ProtonVPN

## Summary

**Issue Discovered:** ProtonVPN with WireGuard provides IPv6 connectivity, but NAT-PMP port forwarding only works for IPv4. This caused Transmission to listen on IPv6 where incoming connections would fail.

**Solution Applied:** Disabled IPv6 for both qBittorrent and Transmission to ensure all peer connections use the IPv4 port that is properly forwarded via NAT-PMP.

## Changes Made

### 1. Transmission Configuration (`modules/nixos/services/media-management/transmission.nix`)

**Added:**

- `bind-address-ipv4 = "0.0.0.0"` - Explicit IPv4 binding
- `bind-address-ipv6 = ""` - Disable IPv6 (empty string)
- Documentation comments explaining why IPv6 is disabled

**Impact:**

- Transmission will no longer listen on IPv6 port 64243
- All peer connections will use IPv4 (which has working port forwarding)
- Better peer connectivity and seeding performance

### 2. qBittorrent Configuration (`modules/nixos/services/media-management/qbittorrent.nix`)

**Added:**

- `DisableIPv6 = true` in the Session/VPN configuration
- Documentation comments explaining the ProtonVPN limitation

**Impact:**

- qBittorrent explicitly disables IPv6
- Already was using IPv4-only due to interface binding, this makes it explicit
- Ensures no IPv6 announcements to trackers

### 3. Documentation Created

#### New Document: `docs/PROTONVPN_IPV6_PORTFORWARDING.md`

Comprehensive guide covering:

- Technical explanation of the IPv6 issue
- ProtonVPN's IPv6 support and limitations
- NAT-PMP protocol limitations
- Configuration changes made
- Verification procedures
- Troubleshooting steps

#### Updated: `docs/PROTONVPN_PORT_FORWARDING_SETUP.md`

- Added warning about IPv4-only port forwarding
- Link to detailed IPv6 documentation

## Current Status

### Before Changes

```bash
# Transmission was listening on IPv6 (port not forwarded)
$ sudo ip netns exec qbt ss -tlnp | grep transmission
LISTEN 0      4096            [::]:64243         [::]:*    # ❌ Won't work

# qBittorrent was IPv4-only (correct)
$ sudo ip netns exec qbt ss -tlnp | grep qbittorrent
LISTEN 0      30     10.2.0.2%qbt0:64243      0.0.0.0:*    # ✅ Working
```

### After Rebuild (Expected)

```bash
# Transmission will be IPv4-only
$ sudo ip netns exec qbt ss -tlnp | grep transmission
LISTEN 0      128          0.0.0.0:64243       0.0.0.0:*    # ✅ Will work

# qBittorrent remains IPv4-only
$ sudo ip netns exec qbt ss -tlnp | grep qbittorrent
LISTEN 0      30     10.2.0.2%qbt0:64243      0.0.0.0:*    # ✅ Working
```

## What You Need to Do

### 1. Review Changes

```bash
cd /home/lewis/.config/nix

# Review all changes
git diff

# Review new documentation
cat docs/PROTONVPN_IPV6_PORTFORWARDING.md
```

### 2. Rebuild System

```bash
# Build and switch (choose your preferred method)
nh os switch

# Or
sudo nixos-rebuild switch --flake .#jupiter
```

### 3. Verify Services Restarted

```bash
# Check both services restarted successfully
sudo systemctl status qbittorrent.service
sudo systemctl status transmission.service

# Check port forwarding is working
./scripts/check-torrent-port.sh
```

### 4. Verify IPv6 is Disabled

```bash
# Check listening sockets (should be IPv4 only)
sudo ip netns exec qbt ss -tlnp | grep -E '(qbittorrent|transmission)'

# Should NOT show any IPv6 listeners on port 64243
# Should show IPv4 only: 10.2.0.2:64243 or 0.0.0.0:64243
```

### 5. Monitor Performance

After the change, monitor for:

- ✅ Better peer connectivity (more successful connections)
- ✅ Improved upload/download speeds
- ✅ No failed connection attempts in logs
- ✅ Better seeding ratios

## Technical Details

### Why This Matters

ProtonVPN provides both IPv4 and IPv6 addresses in the VPN namespace:

- **IPv4**: `10.2.0.2` (internal), `146.70.204.170` (external via NAT)
- **IPv6**: `2a07:b944::2:2` (internal), `2001:ac8:31:366::18` (external)

NAT-PMP port forwarding:

- ✅ Works for IPv4: Port 64243 → Your torrent client
- ❌ Does NOT work for IPv6: No port forwarding available

If torrent clients listen on IPv6:

- Clients announce IPv6 address to trackers
- IPv6 peers try to connect
- Connection fails (port not forwarded)
- Results in poor connectivity

### The Fix

By disabling IPv6 for torrent clients:

- Clients only bind to IPv4 addresses
- Only IPv4 address announced to trackers
- All peers use IPv4 (which has working port forwarding)
- Maximum connectivity and performance

### Why Not Disable IPv6 Globally?

The current approach (per-application IPv6 disable) is preferred over disabling IPv6 entirely in the VPN namespace because:

1. **Flexibility**: Other applications in the namespace can still use IPv6 if needed
2. **Granular Control**: Clear which applications are affected
3. **Future-proof**: If ProtonVPN adds IPv6 port forwarding, easy to re-enable
4. **Debugging**: Easier to understand and troubleshoot

## Expected Results

After rebuilding and verifying:

1. **✅ Both torrent clients use IPv4 only**
   - No IPv6 listening sockets for torrent ports
   - All peer connections via IPv4

2. **✅ Port forwarding works for all peers**
   - ProtonVPN forwards port 64243 for IPv4
   - All incoming connections successful

3. **✅ Better performance**
   - No failed IPv6 connection attempts
   - More successful peer connections
   - Better upload/download speeds

4. **✅ Optimal seeding**
   - Maximum peer connectivity
   - Better ratios on private trackers

## Rollback (if needed)

If you need to rollback these changes:

```bash
cd /home/lewis/.config/nix

# Discard changes
git restore modules/nixos/services/media-management/transmission.nix
git restore modules/nixos/services/media-management/qbittorrent.nix
git restore docs/PROTONVPN_PORT_FORWARDING_SETUP.md
rm docs/PROTONVPN_IPV6_PORTFORWARDING.md

# Rebuild
nh os switch
```

## Questions?

See detailed documentation in:

- `docs/PROTONVPN_IPV6_PORTFORWARDING.md` - Complete technical explanation
- `docs/PROTONVPN_PORT_FORWARDING_SETUP.md` - Port forwarding setup
- `docs/QBITTORRENT_GUIDE.md` - qBittorrent configuration

## Testing Checklist

After rebuild, verify:

- [ ] Both services started successfully
- [ ] qBittorrent listening on IPv4 port 64243
- [ ] Transmission listening on IPv4 port 64243
- [ ] No IPv6 listeners on port 64243
- [ ] Port forwarding service working (`./scripts/check-torrent-port.sh`)
- [ ] Peers connecting successfully
- [ ] Upload/download speeds normal or improved

---

**Date:** 2025-12-01
**Issue:** IPv6 port forwarding not supported by ProtonVPN NAT-PMP
**Resolution:** Disabled IPv6 for torrent clients, use IPv4 only
**Status:** Ready for rebuild and testing
