# WireGuard VPN Status: CONNECTED ✅

## Summary

WireGuard is **working correctly**:

- ✅ Handshake established: 1 minute, 26 seconds ago
- ✅ Traffic flowing: 15.23 KiB received, 14.06 KiB sent
- ✅ Persistent keepalive: every 25 seconds
- ✅ Endpoint connected: 185.107.44.110:51820

## Next: Test Connectivity

Since WireGuard is connected, the TLS error might be due to:

1. iptables OUTPUT rules blocking traffic
2. DNS issues
3. MTU size problems
4. Connection timeout/interruption

### Run Comprehensive Test

```bash
cd /home/lewis/.config/nix
sudo bash scripts/test-vpn-connectivity.sh
```

This will test:

- DNS resolution
- HTTP connectivity
- HTTPS connectivity
- iptables rules
- VPN IP address

### Quick Tests

**1. Test HTTP (non-TLS) first:**

```bash
sudo ip netns exec qbt curl -v --max-time 5 http://example.com
```

**2. Check iptables OUTPUT rules:**

```bash
sudo ip netns exec qbt iptables -L OUTPUT -n -v
```

**3. Test HTTPS with verbose output:**

```bash
sudo ip netns exec qbt curl -v --max-time 10 https://torrent.blmt.io 2>&1 | head -40
```

**4. Check VPN IP:**

```bash
sudo ip netns exec qbt curl https://api.ipify.org
```

## Expected Results

- **HTTP should work** - If HTTP works but HTTPS fails, it's a TLS-specific issue
- **VPN IP should be different** - Should show ProtonVPN IP, not your ISP IP
- **DNS should resolve** - Should use VPN DNS (10.2.0.1)

## If HTTPS Still Fails

The TLS error "unexpected eof while reading" could be:

1. **MTU too large** - Try reducing MTU:

   ```bash
   sudo ip netns exec qbt ip link set qbt0 mtu 1280
   ```

2. **Connection timeout** - The connection might be timing out before TLS completes

3. **Firewall rules** - Check if OUTPUT rules are blocking

4. **DNS issue** - Verify DNS is resolving correctly

## Status

✅ **WireGuard VPN: CONNECTED**
⚠️ **TLS Connectivity: NEEDS TESTING**

Run the connectivity test script to diagnose the TLS issue.
