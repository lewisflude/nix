# qBittorrent localhost:8080 Access Issue - Summary

**Date:** 2025-11-03
**Status:** ✅ RESOLVED - Use bridge gateway IP (`192.168.15.1:8080`) instead of localhost

## Problem

Cannot access qBittorrent WebUI at `localhost:8080` when VPN-Confinement is enabled. Requests return HTTP 404 (JSON error response) instead of the qBittorrent login page.

## Root Cause

**VPN-Confinement's port mapping works correctly, but localhost (127.0.0.1) traffic is not forwarded:**

- **Working access:** `http://192.168.15.1:8080/` ✅ Works perfectly
- **Current NAT rule:** `DNAT tcp dpt:8080 to:192.168.15.1:8080` - This is correct!
- **Problem:** VPN-Confinement's NAT rules don't apply to localhost (127.0.0.1) traffic because localhost routes through the loopback interface, bypassing the bridge interface where NAT rules are applied
- **VPN-Confinement setup:** Uses bridge `qbittor-br` with IP `192.168.15.5/24`, gateway at `192.168.15.1`

## Verification

✅ **qBittorrent is working correctly:**

- Listening on port 8080 inside `qbittor` namespace
- Responds with HTTP 200 when accessed from within namespace: `sudo ip netns exec qbittor curl http://127.0.0.1:8080`
- WebUI is functional and properly configured

❌ **Host access fails:**

- `curl http://localhost:8080` → HTTP 404 (JSON error)
- `curl http://192.168.15.5:8080` → HTTP 404 (JSON error)
- NAT rule forwards to `192.168.15.1:8080` which doesn't have qBittorrent listening

## Network Configuration

- **Bridge interface:** `qbittor-br` at `192.168.15.5/24`
- **veth interface:** `veth-qbittor-br` connected to bridge
- **Namespace:** `qbittor` (VPN-Confinement managed)
- **VPN-Confinement config:** Port mapping `8080→8080` configured

## Solution ✅

**Access qBittorrent via the bridge gateway IP instead of localhost:**

```
http://192.168.15.1:8080/
```

This works because VPN-Confinement's NAT rules apply to traffic routed through the bridge interface, not localhost loopback.

## Why Localhost Doesn't Work

**Technical explanation:**

1. **Localhost routing:** When you access `localhost:8080`, the OS routes this through the loopback interface (`lo`), not through the bridge interface (`qbittor-br`)
2. **NAT rules location:** VPN-Confinement's iptables NAT rules are applied to traffic going through the bridge interface
3. **Loopback bypass:** Loopback traffic bypasses the bridge, so NAT rules don't apply
4. **Bridge gateway works:** Accessing `192.168.15.1:8080` routes through the bridge interface, where NAT rules correctly forward to the namespace

## Additional Solutions

### Option 1: Use Bridge Gateway IP (Current Solution) ✅

**Use:** `http://192.168.15.1:8080/`

**Pros:**

- Works immediately, no configuration changes
- Properly routed through VPN-Confinement's NAT rules
- Secure (only accessible from configured `accessibleFrom` IPs)

**Cons:**

- Not as intuitive as `localhost:8080`
- Requires remembering the IP

### Option 2: Add Hosts File Entry (Localhost Alias)

Add an entry to `/etc/hosts` to make `localhost` resolve to the bridge gateway:

```bash
# Add to /etc/hosts
192.168.15.1  qbittorrent.local
```

Then access via `http://qbittorrent.local:8080/`

**Note:** This won't work for `localhost` itself since localhost is hardcoded to 127.0.0.1, but you can use a custom hostname.

### Option 3: Create Localhost Proxy (Advanced)

Create a simple proxy service that listens on localhost:8080 and forwards to 192.168.15.1:8080. This is more complex and generally not recommended.

### Option 4: Access via Host's External IP

If `accessibleFrom` includes your network range, you can access via your host's actual IP:

```bash
# Find your host IP
ip addr show eno2 | grep "inet "

# Access via host IP (e.g., 192.168.1.210:8080)
curl http://192.168.1.210:8080
```

This may work if VPN-Confinement's NAT rules apply to your network interface.

## Recommended Solution

**Use `http://192.168.15.1:8080/` instead of `localhost:8080`**

This is the correct way to access services running in VPN-Confinement namespaces. The bridge gateway IP (`192.168.15.1`) is specifically set up by VPN-Confinement to forward traffic to services in the namespace.

## Understanding VPN-Confinement Port Mapping

VPN-Confinement creates a bridge network (`qbittor-br`) with:

- **Bridge IP:** `192.168.15.5/24` (on host)
- **Gateway IP:** `192.168.15.1` (inside namespace, forwards to services)
- **Port mappings:** Forward traffic from host → bridge gateway → service in namespace

The `accessibleFrom` configuration controls which source IPs are allowed to access the service, but the actual forwarding happens through the bridge gateway IP, not localhost.

## Testing Commands

```bash
# 1. Verify qBittorrent works in namespace
sudo ip netns exec qbittor curl -v http://127.0.0.1:8080

# 2. Test from host via localhost
curl -v http://localhost:8080

# 3. Test from host via bridge IP
curl -v http://192.168.15.5:8080

# 4. Test from host via actual host IP
curl -v http://192.168.1.210:8080  # Replace with your IP

# 5. Check VPN-Confinement service logs
sudo journalctl -u qbittor.service -n 100

# 6. Check NAT rules
sudo iptables -t nat -L -n -v | grep 8080
```

## Related Files

- `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix` - VPN-Confinement config
- `modules/nixos/services/media-management/qbittorrent-standard.nix` - qBittorrent service config
- `docs/QBITTORRENT_LOCALHOST_DEBUG_PLAN.md` - Detailed debugging plan
