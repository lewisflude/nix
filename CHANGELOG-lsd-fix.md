# Changelog: LSD (Local Peer Discovery) Fix

**Date**: 2025-12-01
**Issue**: LSD was enabled in VPN mode, causing unnecessary local network noise
**Status**: ✅ Fixed

## Summary

Following the comprehensive ProtonVPN + qBittorrent checklist, we identified that our configuration was already following 4 out of 5 critical best practices. However, we found one issue: **LSD (Local Peer Discovery) was enabled even when using VPN**.

## Checklist Results

### ✅ 1. Bind qBittorrent to the WireGuard Interface

**Status**: Already implemented correctly

```nix
// optionalAttrs (qbittorrentCfg.vpn.enable or false) {
  Interface = "qbt0";
  InterfaceName = "qbt0";
  InterfaceAddress = "10.2.0.2";
}
```

**Result**: All BitTorrent traffic is confined to the VPN namespace (`qbt`), preventing any IP leaks if the VPN drops.

### ✅ 2. Disable UPnP / NAT-PMP in qBittorrent

**Status**: Already implemented correctly

```nix
Network = {
  PortForwardingEnabled = if (qbittorrentCfg.vpn.enable or false) then false else true;
};

Session = {
  UseUPnP = if (qbittorrentCfg.vpn.enable or false) then false else true;
  UseNATPMP = if (qbittorrentCfg.vpn.enable or false) then false else true;
}
```

**Result**: qBittorrent's internal port forwarding is disabled when VPN is active, allowing our external NAT-PMP automation script to handle port forwarding properly.

### ✅ 3. Handle IPv6 Correctly (Leak Protection)

**Status**: Already implemented correctly

```nix
// optionalAttrs (qbittorrentCfg.vpn.enable or false) {
  DisableIPv6 = true;
}
```

**Additional protection**:

- Default `ipProtocol` is set to `"IPv4"` (can be configured per-host)
- VPN interface bound to IPv4 address only (`10.2.0.2`)

**Result**: IPv6 is completely disabled when VPN is enabled, preventing IPv6 leaks (since ProtonVPN's NAT-PMP port forwarding is IPv4-only).

### ⚠️ 4. Verify Peer Discovery Protocols (DHT/PeX/LSD)

**Status**: FIXED

#### Before (Incorrect)

```nix
UsePEX = true;
UseDHT = true;
UseLSD = true;  # ❌ Always enabled, even with VPN
```

#### After (Correct)

```nix
UsePEX = true;  # Peer exchange for better peer discovery
UseDHT = true;  # DHT for trackerless torrents
# LSD (Local Peer Discovery) - disable when using VPN
# It's only useful for finding peers on local LAN, which is irrelevant inside a VPN tunnel
# When VPN is disabled, enable it for local network peer discovery
UseLSD = if (qbittorrentCfg.vpn.enable or false) then false else true;
```

**Why this matters**:

- LSD (Local Service Discovery) is designed for finding peers on your **local network** (like a university campus)
- When using VPN, all traffic is tunneled, so local network peer discovery is **irrelevant**
- Leaving it enabled can cause unnecessary network noise and potential connection attempts to non-VPN interfaces

**Result**: LSD is now disabled when VPN is enabled, and enabled when VPN is disabled (for local network setups).

### ✅ 5. Protocol Encryption

**Status**: Already implemented correctly

```nix
encryption = mkOption {
  type = types.enum [ 0 1 2 ];
  default = 1;  # Require encryption (hide protocol headers from DPI)
};
```

**Result**: qBittorrent requires encryption by default, hiding BitTorrent protocol from Deep Packet Inspection (DPI) while still allowing legacy peers.

## Additional Correctly Configured Settings

### Connection Icon Status

Our configuration ensures the **Globe (Green)** icon in qBittorrent:

| Setting | Configuration | Result |
|---------|--------------|--------|
| **Interface Binding** | `qbt0` | ✅ Confined to VPN |
| **Port Forwarding** | External NAT-PMP script | ✅ Port updated every 45 min |
| **IPv6** | Disabled | ✅ No IPv6 leaks |
| **UPnP/NAT-PMP** | Disabled in qBittorrent | ✅ No conflicts with script |

Expected result: **Fully connectable** (green globe icon in qBittorrent WebUI).

### Settings Summary

| Setting | Recommended Value | Our Configuration | Status |
|---------|------------------|-------------------|--------|
| **Network Interface** | VPN adapter (e.g., `wg0`, `qbt0`) | `qbt0` | ✅ |
| **UPnP / NAT-PMP** | Disabled | Disabled when VPN active | ✅ |
| **IPv6** | Disabled (bind to IPv4 only) | `DisableIPv6 = true` | ✅ |
| **Listening Port** | Must match NAT-PMP output | Auto-updated by script | ✅ |
| **Encryption** | "Require encryption" (1) | `1` (default) | ✅ |
| **DHT / PeX** | Enabled (for public torrents) | Enabled | ✅ |
| **LSD** | Disabled (VPN mode) | Now disabled when VPN active | ✅ |

## Files Modified

### Core Module

- **File**: `modules/nixos/services/media-management/qbittorrent.nix`
- **Change**: Line 645-648 - LSD now disabled when VPN is enabled
- **Impact**: Reduces unnecessary local network traffic when using VPN

## Testing

After applying this change, verify with:

```bash
# 1. Rebuild system
nh os switch

# 2. Check qBittorrent config
sudo grep "UseLSD" /var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf

# Expected output (when VPN is enabled):
# Session\UseLSD=false

# 3. Verify port forwarding still works
./scripts/test-vpn-port-forwarding.sh

# 4. Check connection status in qBittorrent WebUI
# Should show green globe (fully connectable)
```

## Migration Notes

No action required for existing deployments. The change is backward-compatible and will take effect on the next system rebuild.

## References

- **Original Advice**: User-provided comprehensive ProtonVPN + qBittorrent checklist
- **ProtonVPN Port Forwarding Guide**: `docs/PROTONVPN_PORT_FORWARDING_SETUP.md`
- **qBittorrent Setup Guide**: `docs/QBITTORRENT_GUIDE.md`
- **Module**: `modules/nixos/services/media-management/qbittorrent.nix`

## Success Criteria

✅ **Configuration is now fully compliant with ProtonVPN + qBittorrent best practices:**

1. ✅ Interface binding to VPN adapter (`qbt0`)
2. ✅ UPnP/NAT-PMP disabled in qBittorrent
3. ✅ IPv6 disabled to prevent leaks
4. ✅ DHT/PeX enabled for public torrents
5. ✅ LSD disabled in VPN mode (FIXED)
6. ✅ Encryption required (mode 1)
7. ✅ Automatic port forwarding via NAT-PMP script

## Next Steps

1. **Review changes**: `git diff modules/nixos/services/media-management/qbittorrent.nix`
2. **Rebuild system**: `nh os switch`
3. **Verify configuration**: Run verification scripts
4. **Monitor**: Check qBittorrent connection status (should be green globe)

---

**Issue**: Resolved
**Reviewer**: System Administrator
**Status**: Ready for deployment
