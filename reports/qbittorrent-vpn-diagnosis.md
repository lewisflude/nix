# qBittorrent VPN Connectivity Issue - Diagnosis & Fix

**Date:** 2025-11-01
**Issue:** WireGuard interface `qbt0` exists but VPN connection not established
**Symptoms:** TLS connection errors, interface exists but no VPN connectivity

## Root Cause

The VPN-Confinement module creates the WireGuard interface as `qbt0` (not `wg0`), but the interface may not be properly configured or the VPN connection may not be established.

## Diagnostic Steps

Run these commands **as root** to diagnose:

```bash
# 1. Check if qbt0 interface exists and its status
sudo ip netns exec qbt ip link show qbt0

# 2. Check WireGuard configuration
sudo ip netns exec qbt wg show qbt0

# 3. Check IP addresses on the interface
sudo ip netns exec qbt ip addr show qbt0

# 4. Check routing table
sudo ip netns exec qbt ip route show

# 5. Test DNS resolution
sudo ip netns exec qbt getent hosts torrent.blmt.io

# 6. Test basic connectivity
sudo ip netns exec qbt ping -c 3 8.8.8.8

# 7. Check WireGuard config file
sudo cat /run/qbittorrent-wg.conf
```

## Expected Output

**If VPN is working correctly:**

- `wg show qbt0` should show:
  - Interface: qbt0
  - Public key: <your VPN public key>
  - Endpoint: 185.107.44.110:51820 (or your endpoint)
  - Allowed IPs: 0.0.0.0/0, ::/0
  - Latest handshake: <recent timestamp>
  - Transfer: <bytes sent/received>

**If VPN is NOT working:**

- `wg show qbt0` may show:
  - No peers configured
  - No handshake
  - Missing endpoint

## Common Issues & Fixes

### Issue 1: WireGuard Config Not Applied

**Symptom:** `wg show qbt0` shows no peers or configuration

**Fix:**

```bash
# Restart the VPN namespace service
sudo systemctl restart qbt.service

# Check logs
sudo journalctl -u qbt.service -n 50
```

### Issue 2: Endpoint Not Reachable

**Symptom:** Script waits indefinitely for endpoint (line 104-106 in qbt-up)

**Fix:**

```bash
# Test endpoint reachability from host
ping -c 3 185.107.44.110

# If unreachable, check firewall or network connectivity
# Verify endpoint IP is correct in hosts/jupiter/default.nix
```

### Issue 3: Private Key Issue

**Symptom:** WireGuard config exists but wg show shows errors

**Fix:**

```bash
# Verify private key secret exists
sudo ls -la /run/secrets/qbittorrent/vpn/privateKey

# Check if secret is accessible
sudo cat /run/secrets/qbittorrent/vpn/privateKey | head -c 50

# Regenerate WireGuard config
sudo systemctl restart generate-qbt-wg-config.service
sudo systemctl restart qbt.service
```

### Issue 4: DNS Not Configured

**Symptom:** DNS resolution fails in namespace

**Fix:**

```bash
# Check DNS config
sudo cat /etc/netns/qbt/resolv.conf

# Should contain:
# nameserver 10.2.0.1

# If missing, restart qbt.service
sudo systemctl restart qbt.service
```

## Testing Connectivity

After fixing issues, test connectivity:

```bash
# Test from namespace
sudo ip netns exec qbt curl -v https://torrent.blmt.io

# Check VPN IP
sudo ip netns exec qbt curl https://api.ipify.org

# Should show VPN IP (ProtonVPN), not your ISP IP
```

## Updated Test Script

The test script has been updated to check for `qbt0` instead of `wg0`. Run:

```bash
cd /home/lewis/.config/nix
bash scripts/test-torrent-connectivity.sh
```

**Note:** Full namespace testing requires root privileges.

## Configuration Verification

Verify your configuration in `hosts/jupiter/default.nix`:

```nix
qbittorrent = {
  vpn = {
    enable = true;
    addresses = ["10.2.0.2/32"];  # ✓ Correct
    dns = ["10.2.0.1"];           # ✓ Correct (ProtonVPN DNS)
    privateKeySecret = "qbittorrent/vpn/privateKey";  # ✓ Correct
    peers = [
      {
        publicKey = "YgGdHIXeCQgBc4nXKJ4vct8S0fPqBpTgk4I8gh3uMEg=";
        endpoint = "185.107.44.110:51820";  # ✓ Verify this is correct
        allowedIPs = ["0.0.0.0/0", "::/0"];  # ✓ Correct
        persistentKeepalive = 25;  # ✓ Correct
      }
    ];
  };
};
```

## Next Steps

1. Run diagnostic commands above as root
2. Check `wg show qbt0` output
3. If no peers configured, restart services:

   ```bash
   sudo systemctl restart generate-qbt-wg-config.service
   sudo systemctl restart qbt.service
   ```

4. Test connectivity again
5. If still failing, check WireGuard config file content
