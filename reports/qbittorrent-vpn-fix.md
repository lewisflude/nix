# qBittorrent VPN Connectivity Fix

## Issue Summary

**Symptom:** TLS connection errors when connecting from VPN namespace
**Interface:** `qbt0` exists and is UP with IP `10.2.0.2/32`
**Problem:** WireGuard connection not established or OUTPUT rules blocking traffic

## Root Cause

The WireGuard interface exists but may not be properly configured. The TLS error "unexpected eof while reading" suggests:

1. WireGuard handshake not established (most likely)
2. iptables OUTPUT rules blocking connections
3. WireGuard config not applied correctly

## Diagnostic Steps

Run these commands **as root**:

```bash
# 1. Check WireGuard status (using full path)
sudo ip netns exec qbt /nix/store/*/wireguard-tools-*/bin/wg show qbt0

# 2. Check routing
sudo ip netns exec qbt ip route show

# 3. Check iptables OUTPUT rules
sudo ip netns exec qbt iptables -L OUTPUT -n -v

# 4. Check OUTPUT policy
sudo ip netns exec qbt iptables -S OUTPUT | head -5

# 5. Test basic connectivity
sudo ip netns exec qbt ping -c 3 8.8.8.8

# 6. Test HTTP (non-TLS)
sudo ip netns exec qbt curl -v --max-time 5 http://example.com

# 7. Check WireGuard config
sudo cat /run/qbittorrent-wg.conf
```

## Expected WireGuard Output

If WireGuard is working, `wg show qbt0` should show:

```
interface: qbt0
  public key: <your-public-key>
  private key: (hidden)
  listening port: <random-port>

peer: <peer-public-key>
  endpoint: 185.107.44.110:51820
  allowed ips: 0.0.0.0/0, ::/0
  latest handshake: <recent timestamp, e.g., 2 seconds ago>
  transfer: <bytes sent/received>
```

If NOT working, you'll see:

- No peers listed
- No handshake
- Missing endpoint

## Fixes

### Fix 1: Restart VPN Namespace Service

```bash
# Regenerate WireGuard config
sudo systemctl restart generate-qbt-wg-config.service

# Restart VPN namespace
sudo systemctl restart qbt.service

# Check status
sudo systemctl status qbt.service
```

### Fix 2: Check WireGuard Config File

```bash
# Verify config exists and has correct format
sudo cat /run/qbittorrent-wg.conf

# Should contain:
# [Interface]
# PrivateKey = <key>
# Address = 10.2.0.2/32
# DNS = 10.2.0.1
#
# [Peer]
# PublicKey = YgGdHIXeCQgBc4nXKJ4vct8S0fPqBpTgk4I8gh3uMEg=
# Endpoint = 185.107.44.110:51820
# AllowedIPs = 0.0.0.0/0, ::/0
# PersistentKeepalive = 25
```

### Fix 3: Manually Reconfigure WireGuard (if needed)

```bash
# Stop the service
sudo systemctl stop qbt.service

# Check if interface exists
sudo ip netns exec qbt ip link show qbt0

# If interface exists but not configured, manually configure:
sudo ip netns exec qbt /nix/store/*/wireguard-tools-*/bin/wg setconf qbt0 /run/qbittorrent-wg.conf

# Bring interface up
sudo ip netns exec qbt ip link set qbt0 up

# Check status
sudo ip netns exec qbt /nix/store/*/wireguard-tools-*/bin/wg show qbt0
```

### Fix 4: Check Private Key Secret

```bash
# Verify secret exists
sudo ls -la /run/secrets/qbittorrent/vpn/privateKey

# Check if readable
sudo cat /run/secrets/qbittorrent/vpn/privateKey | head -c 50

# Should show a WireGuard private key (base64-like string)
```

### Fix 5: Check iptables OUTPUT Rules

```bash
# Check OUTPUT policy (should be ACCEPT by default)
sudo ip netns exec qbt iptables -S OUTPUT

# If OUTPUT is blocking, check rules:
sudo ip netns exec qbt iptables -L OUTPUT -n -v

# If needed, allow OUTPUT (temporary fix):
sudo ip netns exec qbt iptables -P OUTPUT ACCEPT
```

### Fix 6: Test Endpoint Reachability

```bash
# Test if VPN endpoint is reachable from host
ping -c 3 185.107.44.110

# If unreachable, check network/firewall
# Verify endpoint is correct in hosts/jupiter/default.nix
```

## Verification

After applying fixes, verify connectivity:

```bash
# 1. Check WireGuard handshake
sudo ip netns exec qbt /nix/store/*/wireguard-tools-*/bin/wg show qbt0 | grep handshake

# Should show recent handshake (within last few minutes)

# 2. Check VPN IP
sudo ip netns exec qbt curl https://api.ipify.org

# Should show ProtonVPN IP, not your ISP IP

# 3. Test HTTPS connectivity
sudo ip netns exec qbt curl -v https://torrent.blmt.io

# Should complete successfully without TLS errors
```

## Quick Diagnostic Script

Run the diagnostic script:

```bash
cd /home/lewis/.config/nix
sudo bash scripts/check-qbt-vpn.sh
```

## Common Issues

### Issue: "No such file or directory" when running `wg`

**Solution:** Use full path to wg:

```bash
sudo ip netns exec qbt /nix/store/*/wireguard-tools-*/bin/wg show qbt0
```

Or find the exact path:

```bash
find /nix/store -name "wg" -type f | grep wireguard | head -1
```

### Issue: WireGuard handshake never completes

**Causes:**

- Endpoint unreachable (check firewall/network)
- Wrong private key
- Wrong peer public key
- Endpoint IP/port incorrect

**Fix:** Verify all configuration values match your ProtonVPN WireGuard config

### Issue: TLS errors persist after WireGuard handshake

**Possible causes:**

- iptables OUTPUT rules blocking
- DNS issues
- MTU size too large

**Fix:**

```bash
# Check MTU
sudo ip netns exec qbt ip link show qbt0 | grep mtu

# Check OUTPUT rules
sudo ip netns exec qbt iptables -L OUTPUT -n -v
```

## Next Steps

1. Run diagnostic commands above
2. Check WireGuard status: `sudo ip netns exec qbt /nix/store/*/wireguard-tools-*/bin/wg show qbt0`
3. If no handshake, restart services: `sudo systemctl restart qbt.service`
4. If still failing, check config file and verify all values are correct
5. Test connectivity again
