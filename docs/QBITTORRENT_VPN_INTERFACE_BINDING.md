# qBittorrent VPN Interface Binding

**Date:** 2025-01-27
**Status:** ✅ Implemented - qBittorrent now binds to VPN interface

## Problem

qBittorrent UDP trackers were failing with "Device or resource busy" errors when running in VPN-Confinement namespace. Even though qBittorrent was in the VPN namespace, it wasn't explicitly bound to the VPN interface, which may have caused UDP socket binding issues.

## Solution

**Bind qBittorrent to the VPN WireGuard interface** using qBittorrent's network interface binding feature (Options > Advanced > Network Interface).

## Implementation

Added interface binding configuration to `qbittorrent-standard.nix`:

```nix
BitTorrent = {
  Session = {
    # ... other settings ...
  }
  // (
    # Bind to VPN interface when VPN is enabled
    # This ensures all traffic (including UDP tracker announces) goes through the VPN
    # VPN-Confinement creates the WireGuard interface as "qbittor0" in the namespace
    # This corresponds to Options > Advanced > Network Interface in qBittorrent WebUI
    if vpnEnabled then {
      InterfaceName = "qbittor0";
    } else {}
  );
};
```

## Interface Name

- **VPN-Confinement namespace:** `qbittor`
- **WireGuard interface in namespace:** `qbittor0`
- **Interface IP:** `10.2.0.2/32`

VPN-Confinement automatically creates the WireGuard interface with this name pattern: `<namespace-name>0`.

## What This Does

1. **Forces all qBittorrent traffic through VPN:**
   - Peer connections (TCP/UDP)
   - Tracker announces (HTTP/TCP/UDP)
   - DHT queries
   - All network traffic

2. **May fix UDP tracker issues:**
   - Explicitly binds UDP sockets to VPN interface
   - Prevents socket binding conflicts
   - Ensures UDP tracker announces use correct interface

3. **Matches WebUI setting:**
   - Equivalent to: Options > Advanced > Network Interface > `qbittor0`
   - Set automatically via NixOS configuration

## Verification

After rebuilding and restarting qBittorrent:

1. **Check configuration:**

   ```bash
   sudo cat /var/lib/qBittorrent/config/qBittorrent.conf | grep -i interface
   # Should show: Session\InterfaceName=qbittor0
   ```

2. **Check in WebUI:**
   - Go to: Options > Advanced > Network Interface
   - Should show: `qbittor0` selected

3. **Check UDP tracker status:**
   - In qBittorrent WebUI, check torrent tracker status
   - UDP trackers should now work (or show different errors if still failing)

4. **Verify interface binding:**

   ```bash
   sudo ip netns exec qbittor ss -tunp | grep qbittorrent
   # All sockets should show qbittor0 interface
   ```

## Expected Results

✅ **All network traffic routes through VPN:**

- No leaks possible - qBittorrent can only use VPN interface
- UDP tracker announces go through VPN
- Peer connections only via VPN

✅ **Potential UDP tracker fix:**

- UDP socket binding explicitly to VPN interface may resolve "Device or resource busy" errors
- All UDP traffic (trackers, DHT, peers) uses same interface consistently

## Related Files

- `modules/nixos/services/media-management/qbittorrent-standard.nix` - Main configuration
- `docs/QBITTORRENT_UDP_TRACKER_ERRORS.md` - Original UDP tracker issue
- `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix` - VPN-Confinement config

## Next Steps

1. ✅ Configuration added
2. ⏳ Rebuild NixOS configuration
3. ⏳ Restart qBittorrent service
4. ⏳ Verify interface binding in config file
5. ⏳ Test UDP tracker connectivity
6. ⏳ Monitor for "Device or resource busy" errors

## Notes

- Interface name is hardcoded as `qbittor0` based on VPN-Confinement's naming pattern
- If VPN-Confinement changes naming pattern, this will need to be updated
- This is in addition to network namespace isolation - provides extra layer of enforcement
