# Routing Issue Diagnosis

## Problem Summary

**Symptoms:**

- ✅ WireGuard handshake: Active (7 seconds ago)
- ✅ DNS resolution: Works (can resolve torrent.blmt.io)
- ❌ Ping: Fails (cannot reach 10.2.0.1, 8.8.8.8)
- ❌ HTTP: Times out
- ❌ HTTPS: TLS error

**Routing Table:**

```
default dev qbt0 scope link
10.0.0.0/8 via 192.168.15.5 dev veth-qbt
127.0.0.1 via 192.168.15.5 dev veth-qbt
192.168.0.0/16 via 192.168.15.5 dev veth-qbt
192.168.15.0/24 dev veth-qbt proto kernel scope link src 192.168.15.1
```

## Analysis

The default route is correctly set to `qbt0`, but traffic isn't flowing. This suggests:

1. **DNS queries might be bypassing WireGuard** - DNS resolution works, but other traffic doesn't
2. **WireGuard interface might not be routing packets correctly**
3. **iptables rules might be blocking traffic**

## Diagnostic Steps

Run these commands **as root**:

```bash
cd /home/lewis/.config/nix
sudo bash scripts/diagnose-routing.sh
```

Or manually:

```bash
# 1. Check if packets are being transmitted
sudo ip netns exec qbt ip -s link show qbt0 | grep -E "TX|RX"

# 2. Check routing to specific destination
sudo ip netns exec qbt ip route get 8.8.8.8
sudo ip netns exec qbt ip route get 10.2.0.1

# 3. Check WireGuard peer status
sudo ip netns exec qbt /nix/store/30ymxnyg9zhvyr86rwa5h8s4phi6kxyv-wireguard-tools-1.0.20250521/bin/wg show qbt0

# 4. Test with tcpdump (if available)
sudo ip netns exec qbt tcpdump -i qbt0 -n -c 5 &
sudo ip netns exec qbt ping -c 2 8.8.8.8
```

## Possible Causes

### 1. WireGuard Interface Not Routing Properly

The interface might be UP but not properly configured for routing. Check:

```bash
# Verify interface is UP
sudo ip netns exec qbt ip link show qbt0 | grep state

# Check if there's a gateway issue
sudo ip netns exec qbt ip route get 8.8.8.8
```

### 2. DNS Using Wrong Interface

DNS might be resolving through veth instead of WireGuard. Check:

```bash
# See which interface DNS uses
sudo ip netns exec qbt strace -e trace=sendto getent hosts example.com 2>&1 | grep sendto
```

### 3. iptables Blocking Traffic

Check FORWARD and INPUT rules:

```bash
sudo ip netns exec qbt iptables -L FORWARD -n -v
sudo ip netns exec qbt iptables -L INPUT -n -v
```

### 4. WireGuard AllowedIPs Issue

Verify WireGuard is configured to route all traffic:

```bash
sudo ip netns exec qbt /nix/store/30ymxnyg9zhvyr86rwa5h8s4phi6kxyv-wireguard-tools-1.0.20250521/bin/wg show qbt0 | grep "allowed ips"
```

Should show: `allowed ips: 0.0.0.0/0, ::/0`

## Quick Fixes to Try

### Fix 1: Restart WireGuard Interface

```bash
# Bring interface down and up
sudo ip netns exec qbt ip link set qbt0 down
sudo ip netns exec qbt ip link set qbt0 up

# Or restart the service
sudo systemctl restart qbt.service
```

### Fix 2: Verify Routing Table

```bash
# Ensure default route is correct
sudo ip netns exec qbt ip route del default 2>/dev/null || true
sudo ip netns exec qbt ip route add default dev qbt0
```

### Fix 3: Check WireGuard Config

```bash
# Verify config is correct
sudo cat /run/qbittorrent-wg.conf

# Manually reconfigure if needed
sudo ip netns exec qbt /nix/store/30ymxnyg9zhvyr86rwa5h8s4phi6kxyv-wireguard-tools-1.0.20250521/bin/wg setconf qbt0 /run/qbittorrent-wg.conf
```

## Expected Resolution

After fixing, you should see:

- ✅ Ping to 8.8.8.8 works
- ✅ HTTP connectivity works
- ✅ HTTPS connectivity works
- ✅ VPN IP differs from host IP

Run the diagnostic script first to gather more information about what's blocking traffic.
