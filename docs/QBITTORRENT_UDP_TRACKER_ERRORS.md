# qBittorrent UDP Tracker "Device or resource busy" Error

**Date:** 2025-01-27
**Status:** 🔍 Identified - UDP tracker socket binding issue in VPN namespace
**Affected:** All torrents with UDP trackers (e.g., bitsearch.to torrents)

## Problem

qBittorrent reports UDP trackers as "Not working" with error "Device or resource busy" when running in VPN-Confinement namespace:

- `udp://tracker.torrent.eu.org:451/announce` → "Device or resource busy"
- `udp://tracker.opentrackr.org:1337/announce` → "Device or resource busy"
- `udp://tracker.bitsearch.to:1337/announce` → "timed out" or "Device or resource busy"

However:

- ✅ DHT, LSD, and PeX work correctly (all show "Working")
- ✅ UDP connectivity from namespace to trackers works (`nc -vzu` succeeds)
- ✅ qBittorrent can bind UDP sockets on port 6881 for peer connections
- ✅ TCP trackers work fine

## Root Cause

**qBittorrent has a known issue binding UDP sockets for tracker announces in network namespaces.**

When qBittorrent tries to send UDP tracker announces:

1. It attempts to bind UDP sockets for outgoing tracker communication
2. In a network namespace environment, socket binding can conflict or hit resource limits
3. The error "Device or resource busy" (EAGAIN/EBUSY) occurs when the bind() system call fails

This is separate from:

- Peer protocol (can be TCP-only and still need UDP trackers)
- DHT/LSD/PeX (which use different socket binding mechanisms)
- Incoming connections (port 6881 binding works fine)

## Verification

Confirmed UDP connectivity works:

```bash
# Test UDP connectivity from namespace
sudo ip netns exec qbittor nc -vzu tracker.torrent.eu.org 451
# ✅ Connection succeeded

sudo ip netns exec qbittor nc -vzu tracker.opentrackr.org 1337
# ✅ Connection succeeded
```

qBittorrent UDP sockets are bound:

```bash
sudo ip netns exec qbittor ss -ulnp | grep qbittorrent
# Shows qBittorrent has UDP sockets bound on multiple interfaces
```

## Workarounds

### Option 1: Use TCP Trackers Only (Not Recommended)

Remove UDP trackers from torrents and use only TCP trackers. However, many public trackers use UDP, so this significantly reduces tracker availability.

### Option 2: Wait for qBittorrent Fix

This is a known qBittorrent issue. Monitor qBittorrent releases for fixes to UDP tracker socket binding in network namespaces.

### Option 3: Check qBittorrent Interface Binding

Ensure qBittorrent isn't trying to bind to a specific interface that doesn't exist in the namespace. Check configuration:

- `Session\Interface` - Should be empty/null or set to VPN interface
- `Session\InterfaceName` - Should match interface in namespace

### Option 4: Increase Socket Limits (May Help)

The issue might be related to socket limits in the namespace. Check and potentially increase:

```bash
# Check current limits
sudo ip netns exec qbittor ulimit -n

# Check systemd service limits
sudo systemctl show qbittorrent | grep LimitNOFILE
```

### Option 5: Use Alternative BitTorrent Client

If UDP trackers are critical, consider temporarily using a different BitTorrent client that handles UDP tracker announces better in namespaces, or run qBittorrent without VPN namespace (less secure).

## Impact

**Current Impact:**

- UDP trackers fail with "Device or resource busy" error
- TCP trackers work fine
- DHT, LSD, PeX work (these use different mechanisms)
- Peer connections work (can still download/upload)

**Effect on Downloads:**

- **May still work:** If torrents have TCP trackers or sufficient DHT/PeX peers
- **May fail:** If torrents rely heavily on UDP trackers for peer discovery
- **bitsearch.to torrents:** These typically have multiple trackers, so may still work via other trackers

## Monitoring

Check tracker status in qBittorrent WebUI:

1. Open WebUI: `http://192.168.15.1:8080/`
2. Select a torrent
3. Check "Trackers" tab
4. UDP trackers will show "Not working" with "Device or resource busy"
5. TCP trackers should show "Working" or connection status

## Related Issues

- NAT-PMP state file permission errors (separate issue, not blocking)
- VPN-Confinement namespace setup is correct
- UDP connectivity through VPN works
- Issue is specific to qBittorrent's UDP tracker socket binding

## References

- qBittorrent issue: UDP tracker announces in network namespaces
- VPN-Confinement working correctly
- Network routing through VPN functional

## Next Steps

1. ✅ Documented issue
2. ⏳ Monitor qBittorrent releases for namespace UDP fixes
3. ⏳ Test if interface binding configuration helps
4. ⏳ Check if increasing socket limits resolves issue
5. ⏳ Consider workarounds if UDP trackers become critical
