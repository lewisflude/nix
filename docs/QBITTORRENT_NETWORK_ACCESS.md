# Accessing qBittorrent WebUI from Local Network

**Date:** 2025-11-03
**Service:** qBittorrent WebUI via VPN-Confinement

## Overview

qBittorrent is running inside a VPN-Confinement namespace and is accessible via the bridge gateway IP `192.168.15.1:8080` from the host machine. To access it from other machines on your local network, you need to use the host's actual IP address.

## Current Configuration

- **Host IP:** `192.168.1.210/24` (on interface `eno2`)
- **Bridge Gateway IP:** `192.168.15.1` (only accessible from host)
- **WebUI Port:** `8080`
- **VPN-Confinement `accessibleFrom`:** Includes `192.168.1.0/24` (your local network)

## Access Methods

### From Host Machine (Jupiter)

**Use bridge gateway IP:**

```
http://192.168.15.1:8080/
```

This is the correct way to access services in VPN-Confinement namespaces from the host.

### From Other Machines on Local Network

**Use host's actual IP address:**

```
http://192.168.1.210:8080/
```

VPN-Confinement should forward this traffic to the namespace based on the `accessibleFrom` configuration which includes `192.168.1.0/24`.

## How It Works

1. **Request arrives:** Client on local network accesses `http://192.168.1.210:8080/`
2. **Firewall check:** NixOS firewall allows port 8080 (already configured)
3. **VPN-Confinement:** Checks if source IP (`192.168.1.x`) is in `accessibleFrom` list ✅
4. **Port mapping:** VPN-Confinement's NAT rules forward to `192.168.15.1:8080` (bridge gateway)
5. **Namespace:** Bridge gateway forwards to qBittorrent inside the namespace

## Verification

To test if this works from another machine on your network:

```bash
# From another machine on 192.168.1.0/24 network:
curl http://192.168.1.210:8080

# Should return qBittorrent login page HTML
```

## Troubleshooting

### If Access from Network Doesn't Work

1. **Check firewall:**

   ```bash
   # Port 8080 should be in allowedTCPPorts (already configured)
   # Check if firewall is blocking
   sudo iptables -L INPUT -n -v | grep 8080
   ```

2. **Check VPN-Confinement `accessibleFrom`:**
   - Should include `192.168.1.0/24` (already configured)
   - Verify the requesting machine's IP is in this range

3. **Check VPN-Confinement NAT rules:**

   ```bash
   sudo iptables -t nat -L -n -v | grep 8080
   ```

   - Should show DNAT rules forwarding to `192.168.15.1:8080`
   - Rules should apply to traffic from `192.168.1.0/24`

4. **Check VPN-Confinement logs:**

   ```bash
   sudo journalctl -u qbittor.service | grep -i "accessible\|nat\|forward"
   ```

### If VPN-Confinement Doesn't Forward External Traffic

VPN-Confinement may only forward traffic from `accessibleFrom` IPs. The NAT rules should automatically handle this, but if they don't:

1. **Verify NAT rules apply to eno2 interface:**

   ```bash
   sudo iptables -t nat -L -n -v | grep -A 5 8080
   ```

   - Check if rules specify source IP or interface

2. **Check if VPN-Confinement creates separate rules for external access:**
   - May need to check VPN-Confinement source code or documentation
   - Some implementations create rules only for bridge interface

## Alternative: Host IP Proxy

If VPN-Confinement doesn't forward external traffic correctly, you could create a simple reverse proxy on the host that listens on `192.168.1.210:8080` and forwards to `192.168.15.1:8080`. However, this should not be necessary if VPN-Confinement is configured correctly.

## Security Considerations

- **`accessibleFrom` restriction:** Only IPs in `accessibleFrom` can access the service
- **Current config:** Allows access from `192.168.1.0/24` and `192.168.0.0/24`
- **Recommendation:** Ensure your local network ranges are correct and not too broad

## Summary

- **Host access:** `http://192.168.15.1:8080/` ✅
- **Network access:** `http://192.168.1.210:8080/` (should work based on config) ✅
- **localhost:** `http://localhost:8080/` ❌ (doesn't work, use bridge gateway IP)
