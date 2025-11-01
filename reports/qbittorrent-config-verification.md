# qBittorrent VPN Configuration Verification

## Configuration Comparison

Your NixOS config matches ProtonVPN's config:

| Setting | ProtonVPN Config | NixOS Config | Status |
|---------|------------------|--------------|--------|
| Address | 10.2.0.2/32 | 10.2.0.2/32 | ✅ Match |
| DNS | 10.2.0.1 | 10.2.0.1 | ✅ Match |
| PublicKey | YgGdHIXeCQgBc4nXKJ4vct8S0fPqBpTgk4I8gh3uMEg= | YgGdHIXeCQgBc4nXKJ4vct8S0fPqBpTgk4I8gh3uMEg= | ✅ Match |
| Endpoint | 185.107.44.110:51820 | 185.107.44.110:51820 | ✅ Match |
| AllowedIPs | 0.0.0.0/0, ::/0 | 0.0.0.0/0, ::/0 | ✅ Match |
| PersistentKeepalive | (not specified) | 25 | ✅ OK (optional, helps keep connection alive) |

## Next Steps to Diagnose

Since the configuration is correct, the issue is likely that WireGuard isn't establishing a handshake.

### Step 1: Check WireGuard Status

Run this command **as root** (outside the restricted environment):

```bash
# Find WireGuard tools path
WG_PATH=$(find /nix/store -name "wg" -type f 2>/dev/null | grep wireguard | head -1)

# Check WireGuard status
sudo ip netns exec qbt "$WG_PATH" show qbt0
```

**Expected output if working:**

```
interface: qbt0
  public key: <some-key>
  private key: (hidden)
  listening port: <port>

peer: YgGdHIXeCQgBc4nXKJ4vct8S0fPqBpTgk4I8gh3uMEg=
  endpoint: 185.107.44.110:51820
  allowed ips: 0.0.0.0/0, ::/0
  latest handshake: 2 seconds ago    ← THIS IS KEY!
  transfer: 1.23 MiB received, 456 KiB sent
```

**If NOT working, you'll see:**

- No peers listed
- No handshake timestamp
- Transfer: 0 B received, 0 B sent

### Step 2: Verify Generated Config File

Check that the generated config matches ProtonVPN:

```bash
sudo cat /run/qbittorrent-wg.conf
```

Should look like:

```
[Interface]
PrivateKey = <your-private-key>
Address = 10.2.0.2/32
DNS = 10.2.0.1

[Peer]
PublicKey = YgGdHIXeCQgBc4nXKJ4vct8S0fPqBpTgk4I8gh3uMEg=
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = 185.107.44.110:51820
PersistentKeepalive = 25
```

### Step 3: Test Endpoint Reachability

Ensure the VPN endpoint is reachable:

```bash
# Test from host network
ping -c 3 185.107.44.110

# Test UDP port (WireGuard uses UDP)
nc -zv -u 185.107.44.110 51820
```

### Step 4: Restart Services

If WireGuard isn't connecting, restart the services:

```bash
# Regenerate config
sudo systemctl restart generate-qbt-wg-config.service

# Restart VPN namespace
sudo systemctl restart qbt.service

# Wait a few seconds for handshake
sleep 5

# Check status again
sudo ip netns exec qbt "$WG_PATH" show qbt0
```

### Step 5: Check Logs

If still not working, check logs:

```bash
# VPN namespace service logs
sudo journalctl -u qbt.service -n 50 --no-pager

# WireGuard config generation logs
sudo journalctl -u generate-qbt-wg-config.service -n 50 --no-pager
```

## Common Issues

### Issue: No Handshake Established

**Symptoms:**

- `wg show qbt0` shows no "latest handshake"
- Transfer shows 0 B

**Possible Causes:**

1. Endpoint unreachable (firewall/network issue)
2. Private key incorrect
3. WireGuard config not applied correctly

**Fix:**

1. Verify endpoint is reachable: `ping 185.107.44.110`
2. Check private key: `sudo cat /run/secrets/qbittorrent/vpn/privateKey`
3. Manually apply config:

   ```bash
   sudo ip netns exec qbt "$WG_PATH" setconf qbt0 /run/qbittorrent-wg.conf
   sudo ip netns exec qbt ip link set qbt0 up
   ```

### Issue: TLS Errors After Handshake

If WireGuard handshake is working but TLS still fails:

1. Check iptables OUTPUT rules:

   ```bash
   sudo ip netns exec qbt iptables -L OUTPUT -n -v
   ```

2. Test HTTP (non-TLS) first:

   ```bash
   sudo ip netns exec qbt curl http://example.com
   ```

3. Check MTU size:

   ```bash
   sudo ip netns exec qbt ip link show qbt0 | grep mtu
   ```

   If MTU is too large (should be ~1420 for WireGuard), adjust it.

## Verification Commands

Once WireGuard is connected, verify everything:

```bash
# 1. Check WireGuard handshake
sudo ip netns exec qbt "$WG_PATH" show qbt0 | grep handshake

# 2. Check VPN IP (should be ProtonVPN IP)
sudo ip netns exec qbt curl https://api.ipify.org

# 3. Test HTTPS connectivity
sudo ip netns exec qbt curl -v https://torrent.blmt.io

# 4. Test DNS
sudo ip netns exec qbt getent hosts torrent.blmt.io
```

## Summary

Your configuration is **correct** and matches ProtonVPN's config. The issue is that WireGuard isn't establishing a handshake. Follow the steps above to:

1. Verify WireGuard status
2. Check if handshake is established
3. Restart services if needed
4. Check logs for errors

The key command is checking `wg show qbt0` - if there's no handshake, WireGuard isn't connected even though the interface is UP.
