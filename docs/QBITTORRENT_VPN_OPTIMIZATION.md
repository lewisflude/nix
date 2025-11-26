# qBittorrent VPN Optimization Guide

## Problem Diagnosis

After running diagnostic commands, the following issues were identified causing sporadic torrent behavior:

### Symptoms

- Sporadic connection issues in qBittorrent
- Inconsistent peer connectivity
- Occasional slowdowns

### Root Causes Found

1. **Packet Drops on WireGuard Interface**
   - **72,774 TX packets dropped** out of 14.2M sent (~0.5% drop rate)
   - WireGuard interface (`qbt0`) using `noqueue` qdisc (no buffering)
   - Traffic bursts from 273 simultaneous uploads overwhelming the interface

2. **Extremely Aggressive Upload Settings**
   - **1,643 max upload slots** (too high)
   - **273 active uploads** simultaneously
   - **547 active torrents** (excessive for HDD storage)
   - Combined with DHT, creating massive traffic bursts

3. **Insufficient Network Buffers**
   - Default UDP buffer minimum: 4096 bytes (too small)
   - Socket buffer defaults: 208 KB (adequate but could be better)

## Applied Fixes

### 1. Traffic Control Queue Discipline (qdisc)

**File**: `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix`

Added systemd service `configure-qbt-qdisc` that:

- Removes the `noqueue` qdisc from qbt0 interface
- Installs CAKE (Common Applications Kept Enhanced) qdisc
- Configured with 100 Mbit/s bandwidth shaping
- CAKE provides:
  - Automatic bufferbloat management
  - Fair queuing across flows
  - Better handling of traffic bursts

```nix
"configure-qbt-qdisc" = {
  description = "Configure traffic control qdisc for qBittorrent WireGuard interface";
  after = [ "${vpnCfg.namespace}.service" ];
  before = [ "qbittorrent.service" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = "yes";
    ExecStart = "${pkgs.iproute2}/bin/ip netns exec ${vpnCfg.namespace} ${pkgs.iproute2}/bin/tc qdisc replace dev ${vpnCfg.namespace}0 root cake bandwidth 100mbit";
    ExecStop = "${pkgs.iproute2}/bin/ip netns exec ${vpnCfg.namespace} ${pkgs.iproute2}/bin/tc qdisc del dev ${vpnCfg.namespace}0 root || true";
  };
};
```

### 2. Kernel Network Tuning

**File**: `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix`

Added comprehensive sysctl parameters:

```nix
boot.kernel.sysctl = {
  # Socket buffer configuration
  "net.core.rmem_default" = 262144;    # 256 KB receive buffer (up from 208 KB)
  "net.core.wmem_default" = 262144;    # 256 KB send buffer (up from 208 KB)
  "net.core.rmem_max" = 33554432;      # 32 MB max (unchanged)
  "net.core.wmem_max" = 33554432;      # 32 MB max (unchanged)

  # UDP buffer minimums for torrent traffic
  "net.ipv4.udp_rmem_min" = 16384;     # 16 KB UDP receive (up from 4 KB)
  "net.ipv4.udp_wmem_min" = 16384;     # 16 KB UDP send (up from 4 KB)

  # TCP congestion control - BBR for better VPN performance
  "net.core.default_qdisc" = "fq";              # Fair Queue (required for BBR)
  "net.ipv4.tcp_congestion_control" = "bbr";    # BBR congestion control
};
```

**Why BBR?**

- BBR (Bottleneck Bandwidth and RTT) is Google's modern congestion control algorithm
- Significantly improves TCP throughput over VPN tunnels
- Works better than traditional algorithms (cubic) on high-latency links
- Requires `fq` (Fair Queue) as the default qdisc

### 3. qBittorrent Connection Limits

**File**: `hosts/jupiter/default.nix`

Reduced aggressive connection settings:

| Setting | Old (Speed) | New (Balanced) | Change |
|---------|-------------|----------------|---------|
| `maxConnections` | 600 | 300 | -50% |
| `maxConnectionsPerTorrent` | 100 | 100 | No change |
| `maxUploads` | 1643 | 200 | -88% |
| `maxUploadsPerTorrent` | 10 | 10 | No change |
| `maxActiveTorrents` | 547 | 150 | -73% |
| `maxActiveUploads` | 273 | 50 | -82% |

**Rationale**:

- **maxUploads**: 1643 was causing massive traffic bursts; 200 still allows good seeding
- **maxActiveUploads**: 273 simultaneous uploads overwhelmed the interface; 50 is more sustainable
- **maxActiveTorrents**: 547 caused HDD thrashing; 150 is optimal for HDD storage
- **maxConnections**: 300 is sufficient and reduces router/gateway load

## Applying the Changes

After editing your NixOS configuration, rebuild your system:

```bash
# Build and switch to new configuration
nh os switch

# Or manually:
sudo nixos-rebuild switch --flake ~/.config/nix#jupiter
```

## Verifying the Fixes

After rebuilding, verify the changes are applied:

### 1. Check Queue Discipline

```bash
sudo ip netns exec qbt tc qdisc show dev qbt0
# Should show: qdisc cake ... bandwidth 100Mbit
```

### 2. Check Kernel Parameters

```bash
sysctl net.core.rmem_default net.core.wmem_default
sysctl net.ipv4.udp_rmem_min net.ipv4.udp_wmem_min
# Should show the increased values (262144 and 16384)
```

### 3. Monitor Packet Drops

```bash
# Before torrenting (note current drops)
sudo ip netns exec qbt ip -s link show qbt0

# Start torrenting for a while, then check again
sudo ip netns exec qbt ip -s link show qbt0

# TX dropped packets should increase much more slowly or not at all
```

### 4. Check qBittorrent Settings

```bash
# Verify new connection limits in config
sudo grep -E "MaxActiveUploads|MaxUploads|MaxConnections" /var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf
```

## Expected Results

After applying these changes, you should see:

1. **Eliminated or Drastically Reduced Packet Drops**
   - CAKE qdisc buffers traffic bursts instead of dropping packets
   - Packet drop rate should approach 0%

2. **More Consistent Torrent Performance**
   - Fewer connection timeouts
   - More stable peer connections
   - Consistent upload/download speeds

3. **Better System Stability**
   - Reduced HDD thrashing (from lower active torrents)
   - Lower router/gateway load (from reduced connections)
   - Better Jellyfin streaming performance (less I/O contention)

## Monitoring

Use these commands to monitor performance:

```bash
# Check WireGuard transfer and drops
sudo ip netns exec qbt wg show qbt0
sudo ip netns exec qbt ip -s link show qbt0

# Monitor active connections
sudo ip netns exec qbt ss -s

# Check qBittorrent connections
sudo ip netns exec qbt ss -tunap | grep qbittorrent | wc -l
```

## Advanced Tuning Options

### Adjusting CAKE Bandwidth

The CAKE qdisc is configured with `bandwidth 100mbit`. If your VPN speed differs significantly:

**Current VPN Speed**: ~82 Mbit/s upload (8,216 KB/s)

You can adjust the bandwidth parameter in `qbittorrent-vpn-confinement.nix`:

```nix
# For slower VPN (e.g., 50 Mbit/s):
ExecStart = "... cake bandwidth 50mbit overhead 60 mpu 64";

# For faster VPN (e.g., 200 Mbit/s):
ExecStart = "... cake bandwidth 200mbit overhead 60 mpu 64";
```

Set it slightly higher than your actual speed for best results (e.g., 100 Mbit for 82 Mbit actual).

### Optimizing RTT Parameter

After confirming the configuration is stable, you can optimize RTT based on measured latency:

```bash
# Measure RTT to VPN gateway
sudo ip netns exec qbt ping -c 10 -I qbt0 10.2.0.1

# If consistently ~10ms, switch to "metro" preset:
ExecStart = "... cake bandwidth 100mbit metro overhead 60 mpu 64";
```

CAKE RTT presets:

- **internet** (100ms): Default - conservative for worldwide peers ✓ Current
- **metro** (10ms): For VPN endpoints <20ms away
- **regional** (30ms): For regional connections
- **lan** (1ms): Only for local network traffic

### Understanding Overhead Compensation

The `overhead 60` parameter accounts for WireGuard's IPv4 encapsulation:

```
Your Application → TCP/IP → WireGuard → Physical Interface
                    ↑
                 CAKE sees this (e.g., 1400 bytes)
                                    ↑
                                 Actually sent: 1460 bytes
                                 (1400 + 60 overhead)
```

Without overhead compensation:

- CAKE thinks: "I'm sending 100 Mbit/s"
- Reality: Sending ~107 Mbit/s (6.8% over)
- Result: May exceed VPN capacity

With `overhead 60`:

- CAKE accounts for extra 60 bytes per packet
- When limiting to 100 Mbit/s, actually limits to 100 Mbit/s on wire
- Result: Accurate bandwidth control ✓

## Reverting Changes

If you need to revert any changes:

### Remove CAKE qdisc

```bash
sudo ip netns exec qbt tc qdisc del dev qbt0 root
```

### Restore original settings in git

```bash
cd ~/.config/nix
git diff hosts/jupiter/default.nix
git checkout hosts/jupiter/default.nix
sudo nixos-rebuild switch --flake .#jupiter
```

## Related Documentation

- [QBITTORRENT_GUIDE.md](./QBITTORRENT_GUIDE.md) - Complete qBittorrent setup guide
- [PROTONVPN_PORT_FORWARDING_SETUP.md](./PROTONVPN_PORT_FORWARDING_SETUP.md) - VPN setup guide

## References

- CAKE qdisc: <https://www.bufferbloat.net/projects/codel/wiki/Cake/>
- Linux Traffic Control: <https://tldp.org/HOWTO/Traffic-Control-HOWTO/>
- WireGuard Performance: <https://www.wireguard.com/performance/>
