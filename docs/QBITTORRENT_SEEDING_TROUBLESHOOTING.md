# qBittorrent Seeding Troubleshooting Guide

## Problem

qBittorrent is not seeding despite being configured and running in a VPN namespace.

## Configuration Overview

Your qBittorrent setup:

- **VPN Namespace**: `qbt`
- **VPN Interface**: `qbt0` (IP: `10.2.0.2`)
- **Torrent Port**: `6881` (TCP and UDP)
- **WebUI Port**: `8080` (accessible via reverse proxy at <https://torrent.blmt.io>)
- **VPN Provider**: ProtonVPN

## Most Likely Issues

### 1. VPN Namespace Firewall Blocking Incoming Connections ?? **MOST LIKELY**

The VPN namespace may have a default DROP policy that blocks incoming connections, even though `openVPNPorts` is configured.

**Check:**

```bash
sudo ip netns exec qbt iptables -L INPUT -n -v
```

**Look for:**

- Default policy should be `ACCEPT` or have explicit rules for port 6881
- If policy is `DROP` or `REJECT`, incoming connections are blocked

**Fix:**
The VPN confinement module should create iptables rules from `openVPNPorts`, but if it doesn't, you may need to manually add rules or fix the module.

### 2. Port Forwarding Not Enabled in ProtonVPN ?? **VERY LIKELY**

ProtonVPN requires port forwarding to be enabled in their dashboard for seeding to work.

**Check:**

1. Log into ProtonVPN dashboard
2. Go to Port Forwarding settings
3. Verify port `6881` is forwarded
4. Note the forwarded port (may differ from 6881)

**Fix:**

- Enable port forwarding in ProtonVPN dashboard
- If the forwarded port differs from 6881, update qBittorrent configuration to use that port
- Restart qBittorrent after enabling port forwarding

### 3. qBittorrent Settings Preventing Seeding

**Check via WebUI API:**

```bash
export QB_USERNAME='lewis'
export QB_PASSWORD='your-password'
./scripts/diagnose-qbittorrent-seeding.sh
```

**Common problematic settings:**

- `max_uploads = 0` (seeding disabled)
- `up_limit` too low (upload rate limit)
- Interface binding incorrect
- Listen port mismatch

### 4. Port Not Accessible from Internet

Even if port forwarding is enabled, the port must be accessible from the internet.

**Test:**

1. Visit: <https://www.yougetsignal.com/tools/open-ports/>
2. Enter your VPN external IP (get it with: `sudo ip netns exec qbt curl -s https://ipv4.icanhazip.com`)
3. Enter port: `6881`
4. Click "Check"

If port is closed, port forwarding is not working.

## Diagnostic Steps

### Step 1: Run Comprehensive Diagnostic

```bash
export QB_USERNAME='lewis'
export QB_PASSWORD='your-password'  # Get from secrets
./scripts/diagnose-qbittorrent-seeding.sh
```

This will check:

- Service status
- VPN namespace and interface
- Port binding
- Firewall rules
- qBittorrent configuration
- Port forwarding status
- Network connectivity

### Step 2: Check VPN Namespace Firewall

```bash
# Check default policy
sudo ip netns exec qbt iptables -L INPUT -n | head -5

# Check for rules on port 6881
sudo ip netns exec qbt iptables -L INPUT -n -v | grep 6881

# If no rules exist and policy is DROP, add them:
sudo ip netns exec qbt iptables -I INPUT -p tcp --dport 6881 -j ACCEPT
sudo ip netns exec qbt iptables -I INPUT -p udp --dport 6881 -j ACCEPT
```

### Step 3: Verify Port Forwarding

1. Get external IP:

   ```bash
   sudo ip netns exec qbt curl -s https://ipv4.icanhazip.com
   ```

2. Test port accessibility:
   - Use online port checker: <https://www.yougetsignal.com/tools/open-ports/>
   - Or from another machine: `nc -zv <EXTERNAL_IP> 6881`

### Step 4: Check qBittorrent Settings

Access WebUI at <https://torrent.blmt.io> and check:

- **Connection** ? **Port used for incoming connections**: Should be `6881`
- **Connection** ? **UPnP / NAT-PMP**: Should be **disabled** (using VPN port forwarding)
- **BitTorrent** ? **Interface**: Should be `qbt0` or `any`
- **BitTorrent** ? **Interface address**: Should be `10.2.0.2` or empty
- **Speed** ? **Upload rate limit**: Should be `0` (unlimited) or high enough
- **BitTorrent** ? **Maximum uploads**: Should be > 0

## Quick Fixes

### Fix 1: Add Firewall Rules Manually (Temporary)

If VPN namespace firewall is blocking connections:

```bash
sudo ip netns exec qbt iptables -I INPUT -p tcp --dport 6881 -j ACCEPT
sudo ip netns exec qbt iptables -I INPUT -p udp --dport 6881 -j ACCEPT
```

**Note:** These rules will be lost on reboot. The VPN confinement module should handle this automatically.

### Fix 2: Enable Port Forwarding in ProtonVPN

1. Log into ProtonVPN dashboard
2. Navigate to Port Forwarding
3. Enable port forwarding
4. Note the assigned port
5. If different from 6881, update configuration:

   ```nix
   # In hosts/jupiter/configuration.nix
   vpnNamespaces.qbt = {
     # ... existing config ...
     openVPNPorts = [
       {
         port = <ASSIGNED_PORT>;  # Update if different
         protocol = "both";
       }
     ];
   };
   ```

### Fix 3: Verify qBittorrent Configuration

Check that qBittorrent is using the correct port and interface. The configuration should match:

- Listen port: `6881`
- Interface: `qbt0`
- Interface address: `10.2.0.2`

## Permanent Solution

The VPN confinement module should automatically:

1. Create iptables rules for `openVPNPorts`
2. Allow incoming connections on the specified ports
3. Maintain these rules across reboots

If this isn't working, the VPN confinement module may need to be fixed or updated.

## Testing Seeding

After applying fixes:

1. **Check peer connections:**

   ```bash
   # Via API (requires credentials)
   curl -s -b /tmp/cookies.txt \
     "http://192.168.15.1:8080/api/v2/sync/maindata?rid=0" | \
     grep -o '"nb_connections":[0-9]*'
   ```

2. **Monitor seeding in WebUI:**
   - Go to <https://torrent.blmt.io>
   - Check "Seeding" tab
   - Look for active upload speeds
   - Check peer connections

3. **Verify port is open:**
   - Use external port checker
   - Port should show as "Open"

## Additional Resources

- [ProtonVPN Port Forwarding Guide](https://protonvpn.com/support/port-forwarding/)
- qBittorrent documentation
- VPN confinement module documentation

## Scripts Available

- `scripts/diagnose-qbittorrent-seeding.sh` - Comprehensive diagnostic
- `scripts/test-qbittorrent-connectivity.sh` - Network connectivity test
- `scripts/test-qbittorrent-seeding-health.sh` - Seeding health check
