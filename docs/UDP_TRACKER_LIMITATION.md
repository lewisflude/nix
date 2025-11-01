# UDP Tracker Limitation in Network Namespaces

## Issue

When running qBittorrent in a network namespace with WireGuard VPN, UDP tracker communication fails with:

```
udp://tracker.opentrackr.org:1337/announce    Not working    Device or resource busy
```

## Root Cause

This is a known limitation of running qBittorrent in network namespaces. UDP socket binding for tracker queries fails due to kernel-level restrictions in network namespaces. The "Device or resource busy" error indicates that qBittorrent cannot bind UDP sockets for outbound tracker queries.

## Impact

**UDP Trackers**: Will not work

- Most public trackers use UDP
- These will show as "Not working" in qBittorrent

**TCP Trackers**: Work fine

- HTTP/HTTPS trackers continue to work
- These should connect successfully

**DHT (Distributed Hash Table)**: Works fine

- Uses UDP but with different socket binding
- Should show as "Working" in qBittorrent

**PeX (Peer Exchange)**: Works fine

- Uses TCP connections
- Should show as "Working" in qBittorrent

**LSD (Local Service Discovery)**: Works fine

- Uses local network protocols
- Should show as "Working" in qBittorrent

## Workaround

While UDP trackers won't work, torrenting should still function via:

1. **TCP Trackers**: Most torrents have at least some TCP trackers
2. **DHT**: Provides peer discovery without trackers
3. **PeX**: Exchanges peer information between clients

## Verification

Check qBittorrent WebUI → Statistics → Trackers:

### Expected (Working)

- ✅ **[DHT]**         Working
- ✅ **[LSD]**         Working
- ✅ **[PeX]**         Working
- ✅ <http://tracker.example.com/announce>    Working (TCP tracker)

### Expected (Not Working)

- ❌ udp://tracker.opentrackr.org:1337/announce    Not working    Device or resource busy
- ❌ udp://tracker.example.com:1337/announce    Not working    Device or resource busy

## Alternative Solutions

If UDP trackers are critical:

1. **Use TCP Trackers Only**: Remove UDP trackers from torrents
2. **Run Without VPN Namespace**: Not recommended for privacy
3. **Use Alternative Client**: Some clients handle UDP better in namespaces (untested)
4. **Wait for qBittorrent Fix**: This may be addressed in future versions

## Current Configuration

The module already:

- ✅ Disables UPnP/NAT-PMP (prevents UDP conflicts)
- ✅ Configures proper interface binding (`0.0.0.0`)
- ✅ Verifies namespace readiness before startup
- ✅ Uses systemd restart mechanisms for transient failures

## References

- [qBittorrent Issue Tracker](https://github.com/qbittorrent/qBittorrent/issues)
- Network namespace UDP socket limitations are documented in Linux kernel sources
