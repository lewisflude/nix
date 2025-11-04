# qBittorrent NAT-PMP Port Forwarding Enabled

**Date:** 2025-01-27
**Status:** ✅ Enabled - NAT-PMP port forwarding is now active

## Configuration Changes

### NixOS Configuration

Updated `modules/nixos/services/media-management/qbittorrent-standard.nix`:

```nix
Network = {
  # Enable UPnP/NAT-PMP port forwarding
  # This allows qBittorrent to automatically configure port forwarding on supported routers/VPNs
  PortForwardingEnabled = true;
};
```

### Current Running Config

Manually updated `/var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf`:

```ini
[Network]
PortForwardingEnabled=true
```

## What This Does

**NAT-PMP (NAT Port Mapping Protocol)** allows qBittorrent to:

- Automatically request port forwarding from compatible routers/VPN gateways
- Map the BitTorrent port (6881) through NAT/firewall
- Improve peer connectivity and download speeds
- Receive incoming connections more reliably

## How It Works

1. **qBittorrent sends NAT-PMP requests:**
   - To the gateway/router (typically the VPN gateway in your namespace)
   - Requests forwarding for port 6881 (TCP and UDP)

2. **Gateway responds:**
   - If NAT-PMP is supported, gateway forwards the port
   - qBittorrent stores mapping state

3. **Incoming connections:**
   - Other peers can now connect directly to your port
   - Better download/upload speeds

## Verification

### Check in WebUI

1. Open qBittorrent WebUI: `http://192.168.15.1:8080/`
2. Go to **Options > Connection**
3. Look for **"Port forwarding status"** or NAT-PMP indicator
4. Should show port forwarding is active (if gateway supports it)

### Check Config File

```bash
sudo cat /var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf | grep PortForwardingEnabled
# Should show: PortForwardingEnabled=true
```

### Check NAT-PMP State

```bash
sudo ls -la /var/lib/qBittorrent/.natpmp-state/
# Should show state files if NAT-PMP is working
```

## VPN Namespace Considerations

In your VPN-Confinement namespace setup:

- **Gateway:** The VPN gateway (`10.2.0.1` or similar) is the target for NAT-PMP requests
- **Port 6881:** Already mapped via VPN-Confinement `portMappings` and `openVPNPorts`
- **NAT-PMP:** May help with additional port forwarding if VPN provider supports it

## Troubleshooting

### If NAT-PMP Fails

1. **VPN provider may not support NAT-PMP:**
   - Many VPN providers don't support NAT-PMP/UPnP
   - This is normal and not an error

2. **Check logs:**

   ```bash
   sudo journalctl -u qbittorrent | grep -i "nat\|portforward\|upnp"
   ```

3. **Permission errors (fixed):**
   - `.natpmp-state` directory now has correct permissions
   - qBittorrent user can write to it

### If Port Forwarding Doesn't Work

- VPN-Confinement already handles port mapping via `portMappings`
- NAT-PMP is additional - won't hurt if it doesn't work
- Manual port forwarding may be required depending on VPN provider

## Expected Benefits

✅ **Better peer connectivity:**

- More incoming connections
- Faster download speeds
- Better ratio on private trackers

✅ **Automatic port management:**

- No manual port forwarding configuration needed
- Works with compatible routers/VPNs

## Notes

- **Security:** NAT-PMP is generally safe, but only works with trusted gateways (your VPN)
- **VPN Provider:** Most VPN providers don't support NAT-PMP/UPnP - this is normal
- **Fallback:** Even if NAT-PMP doesn't work, VPN-Confinement's port mappings handle forwarding
- **Permanent:** After rebuild, this setting will be automatically enabled

## Related Configuration

- VPN-Confinement port mappings: `qbittorrent-vpn-confinement.nix`
- BitTorrent port: `6881` (configured in `qbittorrent-standard.nix`)
- VPN interface binding: `qbittor0` (already configured)
