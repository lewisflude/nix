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

### 2. Kernel Network Buffer Tuning

**File**: `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix`

Added sysctl parameters:

```nix
boot.kernel.sysctl = {
  # Socket buffer defaults increased from 208 KB to 256 KB
  "net.core.rmem_default" = 262144;
  "net.core.wmem_default" = 262144;
  "net.core.rmem_max" = 33554432;     # 32 MB (unchanged)
  "net.core.wmem_max" = 33554432;     # 32 MB (unchanged)

  # UDP buffer minimums increased from 4 KB to 16 KB
  "net.ipv4.udp_rmem_min" = 16384;
  "net.ipv4.udp_wmem_min" = 16384;
};
```

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

## Tuning the CAKE Bandwidth

The CAKE qdisc is configured with `bandwidth 100mbit`. If your VPN speed differs significantly:

**Current VPN Speed**: ~82 Mbit/s upload (8,216 KB/s)

You can adjust the bandwidth parameter in `qbittorrent-vpn-confinement.nix`:

```nix
# For slower VPN (e.g., 50 Mbit/s):
ExecStart = "... cake bandwidth 50mbit";

# For faster VPN (e.g., 200 Mbit/s):
ExecStart = "... cake bandwidth 200mbit";
```

Set it slightly higher than your actual speed for best results (e.g., 100 Mbit for 82 Mbit actual).

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
