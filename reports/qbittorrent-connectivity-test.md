# qBittorrent Torrent Connectivity Test Report

**Date:** 2025-11-01
**Tracker URL:** <https://torrent.blmt.io>
**Test Environment:** Restricted (no direct namespace access)

## Executive Summary

✅ **qBittorrent service is running**
✅ **VPN namespace (qbt) is active**
✅ **Host connectivity to tracker works**
⚠️ **Namespace-level connectivity requires root access to verify**

## Verified Components

### 1. Service Status

- ✅ `qbittorrent.service`: Active (running)
- ✅ `qbt.service`: Active (exited - oneshot service)
- ✅ `generate-qbt-wg-config.service`: Active (exited - config generated)

### 2. Network Namespace

- ✅ Namespace `qbt` exists: `ip netns list` shows `qbt (id: 0)`
- ✅ Namespace mount: `/run/netns/qbt` exists
- ✅ WireGuard config: `/run/qbittorrent-wg.conf` exists (259 bytes, owned by nobody)

### 3. Host Connectivity

- ✅ **torrent.blmt.io connectivity from host:**
  - HTTP Status: 200 OK
  - Connect Time: 0.001679s
  - Total Time: 0.016048s
  - SSL certificate: Valid (Let's Encrypt, expires 2026-01-15)

### 4. Port Status

- ✅ WebUI port 8080: Listening on host (accessible)
- ℹ️ Torrent port 6881: Not shown in `ss` output (may be listening in namespace)

### 5. Process Status

- ✅ qBittorrent process running (PID 720727)
- ✅ Network interface napi/qbt0-0 exists (VPN namespace networking)

## Configuration Summary

From `hosts/jupiter/default.nix`:

- VPN enabled: Yes
- Namespace: `qbt`
- VPN address: `10.2.0.2/32`
- VPN DNS: `10.2.0.1` (ProtonVPN DNS)
- Endpoint: `185.107.44.110:51820` (ProtonVPN server)
- Torrent port: `6881`
- Randomize port: `false` (required for VPN)

## Testing Limitations

⚠️ **Cannot directly test namespace connectivity** due to:

- Restricted environment (no sudo access)
- Network namespace requires root privileges to execute commands

## Recommended Verification Steps

To fully verify connectivity from the VPN namespace, run these commands **as root**:

```bash
# 1. Check WireGuard interface in namespace
sudo ip netns exec qbt ip link show wg0
sudo ip netns exec qbt ip addr show wg0

# 2. Test DNS resolution from namespace
sudo ip netns exec qbt getent hosts torrent.blmt.io

# 3. Test HTTP connectivity from namespace
sudo ip netns exec qbt curl -v --connect-timeout 10 https://torrent.blmt.io

# 4. Test VPN IP address
sudo ip netns exec qbt curl https://api.ipify.org

# 5. Check routing table
sudo ip netns exec qbt ip route show

# 6. Verify WireGuard connection
sudo ip netns exec qbt wg show
```

## Quick Test Script

A test script has been created at:

- `scripts/test-torrent-connectivity.sh`

Run it with:

```bash
cd /home/lewis/.config/nix
bash scripts/test-torrent-connectivity.sh
```

**Note:** Full namespace testing requires root privileges.

## Expected Behavior

When qBittorrent downloads torrents:

1. All traffic should route through the VPN namespace (`qbt`)
2. External IP should be the VPN IP (ProtonVPN), not your ISP IP
3. Tracker connections (including torrent.blmt.io) should work through VPN
4. WebUI remains accessible on host network (localhost:8080)

## Troubleshooting

If torrents are not connecting:

1. **Check VPN namespace status:**

   ```bash
   systemctl status qbt.service
   ```

2. **Check WireGuard config:**

   ```bash
   sudo cat /run/qbittorrent-wg.conf
   ```

3. **Check qBittorrent logs:**

   ```bash
   journalctl -u qbittorrent.service -f
   ```

4. **Verify VPN connectivity** (as root):

   ```bash
   sudo ip netns exec qbt ping -c 3 8.8.8.8
   sudo ip netns exec qbt curl https://api.ipify.org
   ```

5. **Check qBittorrent WebUI:**
   - Access: <http://localhost:8080>
   - Verify: Connection → Interface → Listen on all interfaces
   - Verify: Connection → Port → 6881 (not randomized)

## Conclusion

✅ **Host connectivity to torrent.blmt.io is working correctly**
⚠️ **Namespace connectivity requires root verification**
✅ **Services are running and configured correctly**

The configuration appears correct. To verify full VPN functionality, execute the recommended commands as root or use the test script with appropriate privileges.
