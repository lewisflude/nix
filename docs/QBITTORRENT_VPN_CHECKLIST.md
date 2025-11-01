# qBittorrent VPN Setup Checklist

Use this checklist to verify your qBittorrent VPN setup is working correctly.

## Pre-Build Checklist

- [ ] `randomizePort = false` in host configuration
- [ ] VPN `addresses` are set in qbittorrent.vpn config
- [ ] VPN `dns` is set (e.g., `[ "10.2.0.1" ]`)
- [ ] WireGuard `peers` has at least one peer configured
- [ ] `privateKeySecret` or `privateKeyFile` is set for WireGuard key
- [ ] `downloadPath` and `categoryPaths` are set for storage locations
- [ ] Speed limits are reasonable for your VPN provider

### Example Minimal Config

```nix
qbittorrent = {
  enable = true;
  webUiUsername = "admin";
  webUiPasswordHash = "@ByteArray(...)";
  downloadPath = "/mnt/storage/torrents";
  torrentingPort = 6881;
  randomizePort = false;  # ✓ CRITICAL

  vpn = {
    enable = true;
    addresses = [ "10.2.0.2/32" ];
    dns = [ "10.2.0.1" ];
    privateKeySecret = "qbittorrent/vpn/privateKey";
    peers = [{
      publicKey = "YOUR_VPN_KEY";
      endpoint = "vpn.provider:51820";
      allowedIPs = [ "0.0.0.0/0" "::/0" ];
      persistentKeepalive = 25;
    }];
  };
};
```

## Post-Build Checklist (After Rebuild)

### Services Running

- [ ] `systemctl status qbittorrent-netns.service` → **active (exited)**
- [ ] `systemctl status wg-quick-wg-qbtvpn.service` → **active (running)**
- [ ] `systemctl status qbittorrent.service` → **active (running)**
- [ ] `systemctl status privoxy-qbvpn.service` → **active (running)**
- [ ] `systemctl status dante-qbvpn.service` → **active (running)**

### Network Configuration

- [ ] Network namespace exists: `ip netns list | grep qbittorrent`
- [ ] WireGuard interface in namespace: `sudo ip netns exec qbittorrent ip link show wg-qbtvpn`
- [ ] veth pair on host: `ip link show qbt-host`
- [ ] veth in namespace: `sudo ip netns exec qbittorrent ip link show qbt-veth`
- [ ] Namespace has default route: `sudo ip netns exec qbittorrent ip route show | grep default`

### DNS Configuration

- [ ] resolv.conf exists in namespace: `cat /run/netns/qbittorrent/etc/resolv.conf`
- [ ] Contains correct nameserver (e.g., 10.2.0.1)
- [ ] DNS resolves in namespace: `sudo ip netns exec qbittorrent nslookup google.com`

### Firewall Rules

- [ ] iptables rules exist: `iptables -t nat -L PREROUTING -n | grep 8080`
- [ ] Torrent port rule exists: `iptables -t nat -L PREROUTING -n | grep 6881`
- [ ] FORWARD rules allow traffic: `iptables -L FORWARD -n | grep 10.200`

### Connectivity

- [ ] VPN works: `sudo ip netns exec qbittorrent ping 8.8.8.8`
  - Expected: Some packets reach Google
- [ ] WebUI accessible: `curl http://127.0.0.1:8080`
  - Expected: HTTP response (you'll see HTML)
- [ ] qBittorrent listens in namespace: `sudo ip netns exec qbittorrent ss -tlnp | grep qbittorrent`

### IPv6 Check (Privacy)

- [ ] No IPv6 default route: `sudo ip netns exec qbittorrent ip -6 route`
  - Expected: Only link-local routes, NO `default`
- [ ] If you see `default`, fix with: `sudo ip -n qbittorrent -6 route del default`

## WebUI Configuration Checklist

### Access WebUI

1. Open browser: `http://127.0.0.1:8080`
2. Login with configured credentials

### Verify Settings

- [ ] **Connection → Listening Port**
  - [ ] Port matches config (e.g., 6881)
  - [ ] Interface: `0.0.0.0` (allows forwarded traffic)
  - [ ] ✓ Is not randomized

- [ ] **Downloads**
  - [ ] Save path: `/mnt/storage/torrents` (or your path)
  - [ ] Pre-allocate disk space: **Enabled**
  - [ ] Delete torrent file: **Your preference**

- [ ] **Speed**
  - [ ] Upload limit: ~800 KiB/s (70-80% of VPN cap)
  - [ ] Download limit: ~3000 KiB/s (adjust to VPN)

- [ ] **BitTorrent**
  - [ ] Encryption: `Allow encryption` (not Disabled, not Forced)
  - [ ] Anonymous mode: **Disabled**

- [ ] **Web UI**
  - [ ] Bypass auth for localhost: **Enabled**
  - [ ] Auth subnet whitelist: Set if needed

## Testing Checklist

### Test 1: Can You Access qBittorrent?

```bash
curl -I http://127.0.0.1:8080
# Expected: HTTP/1.1 200 OK
```

### Test 2: Is qBittorrent Running in Namespace?

```bash
sudo ip netns exec qbittorrent ps aux | grep qbittorrent
# Expected: qbittorrent process listed
```

### Test 3: Can the Namespace Reach the Internet?

```bash
sudo ip netns exec qbittorrent ping -c 3 8.8.8.8
# Expected: 0% packet loss
```

### Test 4: Does DNS Work in Namespace?

```bash
sudo ip netns exec qbittorrent nslookup example.com
# Expected: Server: 10.2.0.1 (your VPN DNS)
# Expected: Address: xxx.xxx.xxx.xxx
```

### Test 5: Add a Test Torrent

1. Go to WebUI (<http://127.0.0.1:8080>)
2. Add a torrent from a public tracker (e.g., Ubuntu)
3. Let it download for 30 seconds
4. Check that:
   - [ ] Status shows "Downloading" or "Downloading metadata"
   - [ ] Speed is > 0 KiB/s
   - [ ] No errors in logs

### Test 6: Check VPN Leak (IP Check)

1. Let a torrent download for a minute
2. Visit: [https://ipleak.net](https://ipleak.net)
3. Check the "torrent" section at bottom
4. Expected: **VPN IP address shown, NOT your ISP IP**

## Troubleshooting Flow

### Torrents Not Downloading?

1. **Check randomizePort**

   ```bash
   grep -r "randomizePort" /home/lewis/.config/nix/hosts/jupiter/
   # Must be: randomizePort = false;
   ```

   Fix: Set to `false` and rebuild

2. **Check VPN is up**

   ```bash
   systemctl status wg-quick-wg-qbtvpn
   # Must be: active (running)
   ```

   Fix: `sudo systemctl restart wg-quick-wg-qbtvpn.service`

3. **Check qBittorrent is running in namespace**

   ```bash
   sudo ip netns exec qbittorrent ps aux | grep qbittorrent
   ```

   Fix: `sudo systemctl restart qbittorrent.service`

4. **Check iptables rules**

   ```bash
   iptables -t nat -L PREROUTING -n
   ```

   Fix: Rebuild to reinstall rules

5. **Check WireGuard status**

   ```bash
   sudo ip netns exec qbittorrent wg show
   ```

   Fix: Check private key is correct, peer endpoint reachable

### WebUI Unreachable?

1. **Check if port is forwarded**

   ```bash
   iptables -t nat -L PREROUTING -n | grep 8080
   ```

2. **Check if listening in namespace**

   ```bash
   sudo ip netns exec qbittorrent ss -tlnp | grep qbittorrent
   ```

3. **Check service status**

   ```bash
   systemctl status qbittorrent
   # Restart if needed
   sudo systemctl restart qbittorrent
   ```

### No Internet in Namespace?

1. **Check WireGuard**

   ```bash
   sudo ip netns exec qbittorrent wg show
   # Should show peer with latest handshake time
   ```

2. **Check routing**

   ```bash
   sudo ip netns exec qbittorrent ip route show
   # Should have: default via <vpn_gateway>
   ```

3. **Test connectivity**

   ```bash
   sudo ip netns exec qbittorrent ping 8.8.8.8
   ```

## Performance Optimization

After everything is working:

1. **Adjust speed limits based on actual VPN speed**
   - Test: `speedtest-cli` from namespace
   - Set limits to 70-80% of max

2. **Adjust max active torrents**
   - Too many = worse speeds
   - Start with 5-10, increase until you see issues

3. **Monitor resource usage**

   ```bash
   # Check qBittorrent memory/CPU
   ps aux | grep qbittorrent

   # Check VPN tunnel status
   sudo ip netns exec qbittorrent wg show
   ```

4. **Set up seeding limits**
   - Use Radarr/Sonarr seeding goals (not qBittorrent limits)
   - Or set ratio limit to 2.0 in WebUI

## Logs & Debugging

### View qBittorrent logs

```bash
# If using systemd (journalctl)
sudo journalctl -u qbittorrent -f
```

### Check namespace logs

```bash
sudo ip netns exec qbittorrent dmesg | tail -20
```

### Check WireGuard status

```bash
sudo ip netns exec qbittorrent wg show all
```

### Verify all interfaces

```bash
# Host side
ip addr show qbt-host
iptables -t nat -L -n

# Namespace side
sudo ip netns exec qbittorrent ip addr show qbt-veth
sudo ip netns exec qbittorrent ip route show
```

## Next Steps

Once verified:

1. **Configure Prowlarr** with SOCKS5 proxy at `127.0.0.1:1080`
2. **Configure Radarr** to use qBittorrent
3. **Configure Sonarr** to use qBittorrent
4. **Monitor logs** for the first few days
5. **Adjust limits** as needed for your VPN provider

## Success Indicators ✓

- [ ] WebUI loads at <http://127.0.0.1:8080>
- [ ] Can add and download torrents
- [ ] qBittorrent shows IP address matching VPN on ipleak.net
- [ ] No error messages in logs
- [ ] Speed is reasonable for your VPN provider
- [ ] Prowlarr can use the SOCKS5 proxy
- [ ] Radarr/Sonarr can connect to qBittorrent

---

**Questions?** Check `docs/QBITTORRENT_VPN_SETUP.md` for detailed explanations.
