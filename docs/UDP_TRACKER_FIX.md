# UDP Tracker "Device or resource busy" Fix

## Problem

When running qBittorrent in a network namespace with WireGuard VPN, UDP tracker communication fails with:

```
** [0] udp://tracker.opentrackr.org:1337/announce    Not working    Device or resource busy
** [1] udp://tracker.example.com:1337/announce       Not working    Device or resource busy
```

While DHT, LSD, and PEX work fine (they use TCP or local protocols).

## Root Cause

When applications run in network namespaces, UDP socket binding can have issues:

1. **Socket binding race condition**: qBittorrent tries to bind UDP sockets for tracker communication, but the socket binding fails momentarily because the interface state is changing
2. **Namespace isolation**: The namespace limits socket options that normally work in the host network
3. **UDP timeout handling**: Failed UDP queries aren't retried properly, leaving trackers in "Not working" state

## Solutions Applied

We've implemented multiple fixes:

### 1. Disabled UPnP/NAT-PMP (Primary Fix)

```nix
Connection = {
  UPnP = false;
  NatPmp = false;
};
```

**Why**: UPnP/NAT-PMP use UDP-based discovery that can fail in namespaces, interfering with normal UDP socket operations.

### 2. Added UDP Socket Initialization Script

```bash
# In: /nix/modules/nixos/services/media-management/qbittorrent.nix
ExecStartPost = "+${fixupNamespaceUDP}"
```

This script:

- Waits 3 seconds for qBittorrent to fully initialize
- Tests UDP connectivity to the torrent port
- Forces socket binding to stabilize UDP communication

### 3. Fixed Global Settings

```nix
Connection = {
  InterfaceAddress = "0.0.0.0";  # Listen on all interfaces
  ListenInterfaceValue = "0.0.0.0";  # Accept forwarded traffic
  ConnectionSpeed = 0;  # Auto-detect (graceful handling of slow links)
};
```

### 4. Optimized BitTorrent Settings

```nix
BitTorrent = {
  MaxConnecsPerTorrent = 500;  # Reasonable connection limits
  MaxUploadsPerTorrent = 100;  # Prevent resource exhaustion
};
```

## What These Fixes Do

### Before Fix

```
UDP Tracker Query
  ↓
[Socket bind fails - "Device or resource busy"]
  ↓
Tracker marked as "Not working"
  ↓
No retries until torrent restart
```

### After Fix

```
UDP Tracker Query
  ↓
[Socket initialization script ensures sockets are ready]
  ↓
[UPnP disabled - no conflicting UDP operations]
  ↓
Tracker communication succeeds
  ↓
DHT + TCP trackers provide fallback
```

## How to Deploy

1. **Rebuild your system**:

```bash
nh os switch
```

The rebuild will:

- Apply the disabled UPnP/NAT-PMP settings
- Install the UDP socket initialization script
- Update qBittorrent configuration

2. **Restart qBittorrent**:

```bash
sudo systemctl restart qbittorrent
```

3. **Verify the fix**:

```bash
# Check that UDP trackers now show "Working" status
# Go to WebUI → Statistics → Trackers
# Wait 30 seconds for tracker re-announces
```

## Expected Behavior After Fix

### UDP Trackers

- **Before**: "Not working" with "Device or resource busy"
- **After**: "Working" with seeders/leechers count

### Connection Status

- DHT: Working ✓
- LSD: Working ✓
- PEX: Working ✓
- UDP Trackers: Working ✓ (after fix)
- TCP Trackers: Working ✓

### In WebUI

```
Statistics → Trackers should show:
✓ ** [DHT] **         Working
✓ ** [LSD] **         Working
✓ ** [PeX] **         Working
✓ 0  udp://tracker... Working        123  45  ...
✓ 1  udp://tracker... Working         98  67  ...
```

## Troubleshooting

### Fix didn't work?

1. **Clear qBittorrent cache**:

```bash
sudo systemctl stop qbittorrent
sudo rm -rf /var/lib/qBittorrent/.cache
sudo systemctl start qbittorrent
```

2. **Check VPN is connected**:

```bash
sudo ip netns exec qbittorrent wg show
# Should show: latest handshake: X seconds ago
```

3. **Test UDP manually**:

```bash
sudo ip netns exec qbittorrent nc -u -z -w 2 tracker.opentrackr.org 1337
# Should succeed without "Device or resource busy"
```

4. **Check logs for errors**:

```bash
sudo journalctl -u qbittorrent -f
# Look for UDP-related errors
```

### Trackers still showing "Working" but no peers?

This might be a different issue:

- The tracker is working, but returns no peers
- Your IP might be blacklisted
- The torrent might be dead
- Your VPN IP might be blocked

**Verify**: Try a popular, active torrent (e.g., Ubuntu ISO) and check if you get peers.

## Advanced: Manual Testing

```bash
# Test UDP tracker from namespace
sudo ip netns exec qbittorrent bash
nslookup tracker.opentrackr.org
nc -u -z -w 2 tracker.opentrackr.org 1337
# Both should succeed

# Check qBittorrent sees the namespace UDP port
netstat -tlunp | grep qbittorrent
# Should show: 0.0.0.0:6881 udp LISTENING
```

## Performance Notes

The UDP socket initialization adds **3 seconds** to qBittorrent startup time. This is negligible compared to:

- Service restart time (~5-10 seconds)
- Tracker communication time (~30 seconds first announce)

## Related Configuration

Your qBittorrent VPN setup uses:

- **Port forwarding**: iptables NAT rules forward UDP 6881 → namespace
- **WireGuard**: Encrypts all traffic through VPN tunnel
- **Namespace isolation**: Keeps traffic separate from host network
- **DNS**: VPN provider DNS (10.2.0.1) configured in namespace
- **Proxies**: Privoxy (HTTP) and Dante (SOCKS5) for other services

All of these work together to ensure torrents use the VPN exclusively.

## Files Modified

- `modules/nixos/services/media-management/qbittorrent.nix`:
  - Added `fixupNamespaceUDP` script
  - Disabled `UPnP` and `NatPmp` in Connection settings
  - Added `ExecStartPost` to run UDP fixup
  - Optimized `MaxConnecsPerTorrent` and `MaxUploadsPerTorrent`

## Testing Checklist

- [ ] Rebuild completed without errors
- [ ] qBittorrent service starts successfully
- [ ] UDP tracker status changes to "Working" within 30 seconds
- [ ] Torrents show seeders/leechers from trackers
- [ ] DHT, LSD, PEX still show "Working"
- [ ] WebUI is accessible at <http://127.0.0.1:8080>
- [ ] VPN remains connected (check `wg show` in namespace)

## Questions?

Refer to:

- `docs/QBITTORRENT_VPN_SETUP.md` - Complete VPN setup guide
- `docs/QBITTORRENT_VPN_CHECKLIST.md` - Verification checklist
- `scripts/verify-qbt-vpn.sh` - Automated verification script
