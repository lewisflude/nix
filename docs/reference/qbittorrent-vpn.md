# qBittorrent VPN Configuration Guide

This guide covers the complete qBittorrent VPN setup using VPN-Confinement for secure BitTorrent traffic routing through a ProtonVPN WireGuard tunnel.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Configuration](#configuration)
3. [Port Forwarding](#port-forwarding)
4. [Interface Binding](#interface-binding)
5. [Performance Optimization](#performance-optimization)
6. [qBittorrent Bottleneck Analysis](#qbittorrent-bottleneck-analysis)
7. [Troubleshooting](#troubleshooting)
8. [Manual Setup](#manual-setup)

## Architecture Overview

### Current Implementation

The qBittorrent VPN setup uses **VPN-Confinement** to isolate qBittorrent in a network namespace with a dedicated WireGuard interface.

**Key Components:**

- VPN-Confinement namespace: `qbittor`
- WireGuard interface: `qbittor0` (created automatically by VPN-Confinement)
- Interface IP: `10.2.0.2/32`
- Gateway: `10.2.0.1` (ProtonVPN WireGuard gateway)
- BitTorrent port: `6881` (mapped via VPN-Confinement)

### Architecture Benefits

✅ **Complete Traffic Isolation:**

- All qBittorrent traffic routes through VPN
- No IP leaks possible - qBittorrent can only use VPN interface
- Network namespace prevents accidental leaks

✅ **Automatic Port Forwarding:**

- NAT-PMP support for ProtonVPN port forwarding
- Automatic port mapping renewal
- Better peer connectivity and download speeds

✅ **Secure Configuration:**

- WireGuard configuration stored in SOPS
- No manual network setup required
- Declarative NixOS configuration

### Recommended Architecture (Future Improvement)

The current implementation works well, but for future improvements, consider:

#### Option 1: Dedicated Namespace Service + NetworkNamespacePath (Recommended)

- Use systemd's native `NetworkNamespacePath` support
- No `CAP_SYS_ADMIN` needed for qbittorrent service
- Cleaner separation of concerns
- Better error handling and logging

See [Architecture Best Practices](#architecture-best-practices) section below.

## Configuration

### VPN-Confinement Setup

**File:** `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix`

The VPN-Confinement configuration:

- Creates network namespace `qbittor`
- Sets up WireGuard interface `qbittor0`
- Configures port mappings for BitTorrent (port 6881)
- Manages WireGuard connection lifecycle

### qBittorrent Configuration

**File:** `modules/nixos/services/media-management/qbittorrent-standard.nix`

Key settings when VPN is enabled:

```nix
BitTorrent = {
  Session = {
    # Bind to VPN interface
    InterfaceName = "qbittor0";
  };
};

Network = {
  # Enable NAT-PMP port forwarding
  PortForwardingEnabled = true;
};
```

### WireGuard Configuration

**Storage:** SOPS secrets (`vpn-confinement-qbittorrent`)

**Requirements:**

- Must be generated with **NAT-PMP (port forwarding) enabled**
- Must use a **P2P server** (double-arrow icon in ProtonVPN)
- Requires paid ProtonVPN plan for port forwarding

**How to generate:**

1. Sign in to [Proton VPN Account](https://account.protonvpn.com/account)
2. Go to **Account** → **Downloads** → **WireGuard configuration**
3. Select a **P2P server**
4. Enable **"NAT-PMP (port forwarding)"**
5. Download and store in SOPS

## Port Forwarding

### ProtonVPN Port Forwarding

Port forwarding enables incoming BitTorrent connections, improving download speeds and peer connectivity.

#### Automatic Port Forwarding Service

A systemd service (`protonvpn-port-forwarding`) automatically forwards ports:

**Service Details:**

- **Service name:** `protonvpn-port-forwarding.service`
- **Gateway IP:** `10.2.0.1` (ProtonVPN WireGuard default gateway)
- **BitTorrent port:** `6881` (configurable)
- **Protocol:** Both UDP and TCP
- **Renewal interval:** Every 45 seconds (60-second lifetime)

**How It Works:**

1. Service starts after VPN namespace is ready
2. `natpmpc` requests port forwarding from ProtonVPN gateway
3. ProtonVPN assigns a public port (e.g., 53186) and forwards to private port 6881
4. Port mapping is renewed every 45 seconds
5. qBittorrent listens on port 6881 (private port inside namespace)

**Port Configuration:**

- **qBittorrent listening port:** `6881` (private port inside VPN namespace)
- **ProtonVPN public port:** Randomly assigned (e.g., 53186), changes on reconnection
- **Port forwarding:** Public port → Private port 6881 (handled by ProtonVPN gateway)

#### Verification

**Check Service Status:**

```bash
sudo systemctl status protonvpn-port-forwarding.service
```

**Check Service Logs:**

```bash
sudo journalctl -u protonvpn-port-forwarding.service -f
```

Expected output:

```
Mapped public port 53186 to private port 6881 UDP, lifetime 60s
Mapped public port 53186 to private port 6881 TCP, lifetime 60s
```

**Verify in qBittorrent WebUI:**

1. Open: `http://192.168.15.1:8080/`
2. Go to **Options** → **Connection**
3. Check **"Port forwarding status"** - should show as active

### NAT-PMP Configuration

NAT-PMP (NAT Port Mapping Protocol) allows qBittorrent to automatically configure port forwarding.

**Enabled in configuration:**

```nix
Network = {
  PortForwardingEnabled = true;
};
```

**What This Does:**

- qBittorrent sends NAT-PMP requests to the gateway/router
- Requests forwarding for port 6881 (TCP and UDP)
- Gateway responds if NAT-PMP is supported
- Enables incoming connections and improves speeds

**Note:** Most VPN providers don't support NAT-PMP/UPnP, but ProtonVPN does when configured correctly.

## Interface Binding

### Automatic Interface Binding

qBittorrent is automatically configured to bind to the VPN interface when VPN is enabled:

```nix
BitTorrent = {
  Session = {
    InterfaceName = "qbittor0";  # VPN interface name
  };
};
```

**What This Does:**

1. Forces all qBittorrent traffic through VPN
2. Prevents socket binding conflicts
3. Ensures UDP tracker announces use correct interface
4. Matches WebUI setting: Options > Advanced > Network Interface

**Interface Details:**

- **VPN-Confinement namespace:** `qbittor`
- **WireGuard interface:** `qbittor0` (pattern: `<namespace-name>0`)
- **Interface IP:** `10.2.0.2/32`

### Verification

**Check configuration:**

```bash
sudo cat /var/lib/qBittorrent/config/qBittorrent.conf | grep -i interface
# Should show: Session\InterfaceName=qbittor0
```

**Check in WebUI:**

- Go to: Options > Advanced > Network Interface
- Should show: `qbittor0` selected

**Verify interface binding:**

```bash
sudo ip netns exec qbittor ss -tunp | grep qbittorrent
# All sockets should show qbittor0 interface
```

## Performance Optimization

This section covers advanced WireGuard performance tuning techniques to maximize throughput and reduce latency for high-speed BitTorrent transfers.

### Automatic Optimizations

**Most performance optimizations are automatically applied** when the VPN namespace is created:

✅ **System-wide kernel tuning** (applied automatically via NixOS configuration):

- Network buffer sizes increased to 16MB
- TCP buffer sizes optimized for high throughput
- BBR congestion control enabled

✅ **Namespace-specific optimizations** (applied automatically via `qbittorrent-vpn-optimize.service`):

- Network buffer settings applied to VPN namespace
- BBR congestion control enabled in namespace
- MTU set to 1420 (if not already set in WireGuard config)

**Configuration files:**

- **Kernel tuning:** `modules/nixos/core/networking.nix`
- **Namespace optimizations:** `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix`

**Verify optimizations are applied:**

```bash
# Check optimization service status
sudo systemctl status qbittorrent-vpn-optimize.service

# Check service logs
sudo journalctl -u qbittorrent-vpn-optimize.service

# Verify sysctl settings in namespace
sudo ip netns exec qbittor sysctl net.core.rmem_max
sudo ip netns exec qbittor sysctl net.ipv4.tcp_congestion_control

# Check MTU
sudo ip netns exec qbittor ip link show qbittor0 | grep mtu
```

### Adjusting MTU (Maximum Transmission Unit)

One of the most significant factors affecting WireGuard's performance is the MTU size. The default MTU for most interfaces is typically set to 1500 bytes, but this can lead to packet fragmentation, which negatively impacts performance. By tuning the MTU, you can minimize overhead and reduce latency.

#### Finding the Optimal MTU

To find the optimal MTU value for your network interface, you need to test different values. Start with a lower value and gradually increase until you find the maximum that doesn't cause fragmentation.

**Test MTU from within the namespace:**

```bash
# Test different MTU values (start with 1420)
sudo ip netns exec qbittor ping -M do -s 1420 -c 4 10.2.0.1

# If successful, try increasing (e.g., 1440)
sudo ip netns exec qbittor ping -M do -s 1440 -c 4 10.2.0.1

# Continue until you find the maximum value that works
```

The optimal MTU is typically between 1280-1420 bytes for WireGuard, depending on your network path.

#### Configuring MTU

##### Method 1: Edit WireGuard Config File (Recommended - Persistent)

The MTU is automatically set to 1420 by the optimization service, but you can override it in the WireGuard config file for a custom value:

1. Decrypt and edit the WireGuard configuration stored in SOPS:

   ```bash
   # Find your SOPS secrets file location
   # Typically in secrets/ directory or configured in flake.nix

   # Decrypt the config (adjust path to your SOPS file)
   sops -d secrets/secrets.yaml | yq '.vpn-confinement-qbittorrent' > /tmp/wg-config.conf
   # OR if stored as a separate file:
   # sops -d /path/to/secrets/vpn-confinement-qbittorrent > /tmp/wg-config.conf

   # Edit the config
   nano /tmp/wg-config.conf
   ```

2. Add or modify the `MTU` setting in the `[Interface]` section:

   ```ini
   [Interface]
   PrivateKey = <your-private-key>
   Address = 10.2.0.2/32
   MTU = 1420
   ```

3. Re-encrypt and update SOPS:

   ```bash
   # Re-encrypt (adjust path as needed)
   sops -e /tmp/wg-config.conf > /path/to/secrets/vpn-confinement-qbittorrent
   # OR update in secrets.yaml:
   # sops -e -i secrets/secrets.yaml
   ```

4. Rebuild NixOS to apply changes:

   ```bash
   # Rebuild and switch (you'll need to run this manually)
   sudo nh os switch
   ```

**Note:** If MTU is set in the WireGuard config file, the optimization service will detect it and not override it.

##### Method 2: Modify Default MTU in NixOS Config (Alternative)

You can change the default MTU by modifying `qbittorrent-vpn-confinement.nix`:

```nix
# In modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix
defaultMTU = 1400;  # Change from 1420 to your preferred value
```

##### Method 3: Set MTU via Interface (Temporary - Testing Only)

For testing purposes, you can temporarily set the MTU on the interface:

```bash
sudo ip netns exec qbittor ip link set qbittor0 mtu 1420
```

**Note:** This change is temporary and will be lost on interface restart. Use Method 1 for permanent configuration.

#### Verifying MTU

Check the current MTU setting:

```bash
sudo ip netns exec qbittor ip link show qbittor0 | grep mtu
# Should show: mtu 1420 (or your configured value)
```

### Kernel Tuning for WireGuard

WireGuard runs in the Linux kernel, and optimizing the kernel's networking stack can significantly improve performance. These settings can be applied system-wide or specifically to the VPN namespace.

#### Increasing Network Buffers

WireGuard relies on the kernel's network buffers to handle data packets. By increasing buffer sizes, you can ensure the system handles larger data streams without dropping packets.

**Network buffers are automatically optimized** via:

- **System-wide:** `modules/nixos/core/networking.nix` sets buffer sizes to 16MB
- **Namespace:** `qbittorrent-vpn-optimize.service` applies the same settings to the VPN namespace

**Current configuration:**

```nix
# In modules/nixos/core/networking.nix
boot.kernel.sysctl = {
  "net.core.rmem_max" = 16777216;  # 16MB
  "net.core.wmem_max" = 16777216;  # 16MB
  "net.ipv4.tcp_rmem" = "4096 87380 16777216";
  "net.ipv4.tcp_wmem" = "4096 65536 16777216";
};
```

**Verify buffer settings:**

```bash
# Check system-wide
sysctl net.core.rmem_max net.core.wmem_max

# Check in VPN namespace
sudo ip netns exec qbittor sysctl net.core.rmem_max net.core.wmem_max
sudo ip netns exec qbittor sysctl net.ipv4.tcp_rmem net.ipv4.tcp_wmem
```

**Temporarily test different values (for testing only):**

```bash
# Apply to VPN namespace for testing
sudo ip netns exec qbittor sysctl -w net.core.rmem_max=16777216
sudo ip netns exec qbittor sysctl -w net.core.wmem_max=16777216
```

#### TCP Congestion Control Algorithm

The congestion control algorithm affects how network traffic is managed during periods of congestion. For high-speed data transfers, the BBR (Bottleneck Bandwidth and Round-trip propagation time) algorithm can help maximize throughput.

**BBR is automatically enabled** in both the system-wide configuration and the VPN namespace via:

- System-wide: `modules/nixos/core/networking.nix`
- Namespace: `qbittorrent-vpn-optimize.service`

**Verify BBR is enabled:**

```bash
# Check system-wide
sysctl net.ipv4.tcp_congestion_control
# Should show: net.ipv4.tcp_congestion_control = bbr

# Check in VPN namespace
sudo ip netns exec qbittor sysctl net.ipv4.tcp_congestion_control
# Should show: net.ipv4.tcp_congestion_control = bbr

# Check if BBR module is loaded
lsmod | grep tcp_bbr
```

**Note:** BBR requires kernel 4.9+ and the `tcp_bbr` module. Modern NixOS systems include this by default. If BBR is not available, the optimization service will gracefully skip enabling it.

### WireGuard Configuration Optimizations

#### PersistentKeepalive

For scenarios where the connection is idle for extended periods, WireGuard may drop the connection due to NAT timeouts. The `PersistentKeepalive` option ensures the connection remains active.

**Configure in WireGuard config:**

Edit your WireGuard configuration (stored in SOPS) and add to the `[Peer]` section:

```ini
[Peer]
PublicKey = <peer-public-key>
Endpoint = <vpn-server-endpoint>
AllowedIPs = 0.0.0.0/0,::/0
PersistentKeepalive = 25
```

Setting this value to 25 ensures the client sends a keepalive packet every 25 seconds, preventing the connection from being closed by intermediate routers or NAT devices.

**Typical values:**

- `25` - Recommended for most scenarios (keeps connection alive without excessive overhead)
- `0` - Disabled (default, may cause connection drops behind NAT)
- `10-60` - Adjust based on your NAT timeout settings

#### Interface Configuration

The WireGuard interface can be configured with additional options for better performance. These are typically set automatically by VPN-Confinement, but you can verify:

```bash
# Check interface status
sudo ip netns exec qbittor wg show qbittor0

# Check interface statistics
sudo ip netns exec qbittor ip -s link show qbittor0
```

### Optimizing Cipher Performance

WireGuard uses efficient cryptographic algorithms, but ensuring hardware acceleration is enabled can improve performance.

#### Hardware-Accelerated Encryption

Many modern processors support AES-NI, which accelerates AES encryption. WireGuard uses ChaCha20 by default, which is highly efficient on modern processors even without hardware acceleration.

**Check CPU features:**

```bash
# Check for AES-NI support
grep -m1 -o aes /proc/cpuinfo

# Check for other crypto accelerators
grep -E 'aes|sse|avx' /proc/cpuinfo
```

**Note:** WireGuard's ChaCha20 implementation is already highly optimized and performs well on modern CPUs. Hardware acceleration is less critical than with older VPN protocols.

#### Cipher Selection

WireGuard automatically selects the best cipher based on available hardware. The default ChaCha20Poly1305 is excellent for most use cases. No manual configuration is typically needed.

### CPU Affinity and Interrupt Coalescing

For systems with multiple CPU cores, you can optimize WireGuard performance by binding processes to specific cores and enabling interrupt coalescing.

#### CPU Affinity

Binding WireGuard processes to specific CPU cores can improve cache locality and reduce context switching overhead.

**Check current CPU affinity:**

```bash
# Find WireGuard processes
ps aux | grep -E 'wg|wireguard'

# Check current affinity
taskset -p <pid>
```

**Set CPU affinity (requires modifying VPN-Confinement or systemd service):**

This would require modifying the VPN-Confinement module or creating a wrapper script. For most use cases, the kernel scheduler handles CPU assignment efficiently.

**Example wrapper script approach:**

```nix
# In qbittorrent-vpn-confinement.nix, you could modify the service:
systemd.services.vpn-namespace@qbittor = {
  serviceConfig = {
    ExecStartPre = "+${pkgs.writeShellScript "set-cpu-affinity" ''
      # Bind to CPUs 0-1 (adjust based on your system)
      taskset -c 0,1 ${pkgs.wireguard-tools}/bin/wg-quick up qbittor0
    ''}";
  };
};
```

**Note:** CPU affinity tuning is typically only beneficial on high-end systems with many cores and high network throughput. For most users, the default scheduler is sufficient.

#### Interrupt Coalescing

Enabling interrupt coalescing can reduce overhead from high-frequency network interrupts, which is important in high-throughput environments.

**Check current interrupt settings:**

```bash
# Check interface interrupt settings
sudo ethtool -c qbittor0 2>/dev/null || echo "ethtool not available for WireGuard interface"

# For physical interfaces, you can check:
sudo ethtool -c <physical-interface>
```

**Note:** WireGuard interfaces are virtual and don't expose traditional interrupt coalescing settings. The kernel handles interrupt batching automatically for virtual interfaces.

### Performance Monitoring

Monitor WireGuard performance to verify optimizations are working:

**Check interface statistics:**

```bash
# Show detailed interface stats
sudo ip netns exec qbittor ip -s link show qbittor0

# Monitor in real-time
watch -n 1 'sudo ip netns exec qbittor ip -s link show qbittor0'
```

**Check WireGuard statistics:**

```bash
# Show WireGuard interface stats
sudo ip netns exec qbittor wg show qbittor0

# Monitor transfer rates
sudo ip netns exec qbittor wg show qbittor0 transfer
```

**Monitor network performance:**

```bash
# Test throughput (from within namespace)
sudo ip netns exec qbittor iperf3 -c <test-server> -p 5201

# Check for packet drops
sudo ip netns exec qbittor ip -s link show qbittor0 | grep -E "drop|error"
```

### Recommended Optimization Checklist

1. ✅ **MTU Tuning:** Test and set optimal MTU (typically 1280-1420)
2. ✅ **Network Buffers:** Increase `rmem_max` and `wmem_max` to 16MB
3. ✅ **TCP Buffers:** Configure TCP buffer sizes for high throughput
4. ✅ **BBR Algorithm:** Enable BBR congestion control
5. ✅ **PersistentKeepalive:** Set to 25 seconds to prevent NAT timeouts
6. ⚠️ **CPU Affinity:** Only if you have specific performance requirements
7. ⚠️ **Hardware Acceleration:** Verify but typically not needed for ChaCha20

### Performance Testing

After applying optimizations, test performance:

#### Speed Testing Script

A dedicated script is available to monitor torrent speeds through the VPN:

```bash
# Monitor VPN interface traffic in real-time
sudo scripts/utils/test-qbittorrent-vpn-speed.sh

# Show test torrent suggestions
scripts/utils/test-qbittorrent-vpn-speed.sh --suggest

# Customize monitoring interval (default: 2 seconds)
MONITOR_INTERVAL=1 sudo scripts/utils/test-qbittorrent-vpn-speed.sh
```

**Features:**

- Real-time download/upload speed monitoring
- Peak speed tracking
- Total data transferred statistics
- Average speed calculations
- Works directly with VPN namespace interface

**Example output:**

```
Time         Download        Upload          Max DL          Max UL
=======================================================================
14:23:15     12.45 MB/s      1.23 MB/s       12.45 MB/s      1.23 MB/s
14:23:17     15.67 MB/s      1.45 MB/s       15.67 MB/s      1.45 MB/s
14:23:19     11.23 MB/s      1.12 MB/s       15.67 MB/s      1.45 MB/s
```

#### Manual Testing

```bash
# Test download speed with qBittorrent
# Monitor in qBittorrent WebUI: Options > Speed

# Test latency
sudo ip netns exec qbittor ping -c 10 10.2.0.1

# Check for packet loss
sudo ip netns exec qbittor mtr -r -c 10 10.2.0.1

# Monitor interface traffic manually
watch -n 1 'sudo ip netns exec qbittor ip -s link show qbittor0'
```

**Expected improvements:**

- Reduced latency (lower ping times)
- Higher throughput (faster download/upload speeds)
- Fewer retransmissions (better connection stability)
- Lower CPU usage (more efficient packet handling)

## qBittorrent Bottleneck Analysis

After optimizing the network/VPN layer, check qBittorrent settings to ensure there are no application-level bottlenecks.

### Quick Bottleneck Check Script

Use the provided script to check for common throttling issues:

```bash
sudo scripts/utils/check-qbittorrent-throttling.sh
```

This script checks:

- Speed limits (download/upload)
- Connection limits
- Traffic control rules
- Systemd resource limits
- VPN connectivity
- uTP rate limiting

### WebUI Settings to Check

#### 1. Speed Limits (Options → Speed)

**Critical Settings:**

- **Global download rate limit:** Should be `0` (unlimited)
- **Global upload rate limit:** Should be `0` (unlimited)
- **Alternative rate limits:** Check if scheduled limits are enabled
- **Per-torrent limits:** Verify individual torrents don't have limits set

**How to check:**

1. Open qBittorrent WebUI: `http://192.168.15.1:8080/`
2. Go to **Options** → **Speed**
3. Verify both global limits are set to `0` (unlimited)

**If limits are set:**

- Set to `0` to remove limits
- Click **Apply**
- Restart qBittorrent: `sudo systemctl restart qbittorrent`

#### 2. Connection Limits (Options → BitTorrent)

**Current Configuration (from your setup):**

- Max connections: `2000` (global)
- Max connections per torrent: `200`
- Max uploads: `200` (global)
- Max uploads per torrent: `5`

**When to adjust:**

- **Too low:** If you have many active torrents, increase limits
- **Too high:** If experiencing connection issues, reduce slightly
- **For high-speed connections:** Your current settings are good

**Recommended for high-speed VPN:**

- Max connections: `2000-5000` (depends on RAM)
- Max connections per torrent: `200-500`
- Max uploads: `200-500`
- Max uploads per torrent: `5-10`

**How to check:**

1. Go to **Options** → **BitTorrent**
2. Scroll to **Connection Limits** section
3. Verify values match your configuration

#### 3. Disk Cache (Options → Advanced → Disk Cache) ⚠️ **CRITICAL**

**Current Configuration:**

- Disk cache size: `-1` (uses OS cache/RAM - optimal)

**What this means:**

- `-1` = Enable OS cache (uses available RAM)
- `0` = Disable cache (not recommended - **MAJOR BOTTLENECK**)
- `>0` = Fixed cache size in MB

**⚠️ IMPORTANT: If Statistics show "Total buffer size: 0 B":**

This indicates the cache is **NOT working**, which is a **major performance bottleneck**. Even with `-1` configured, qBittorrent may not be using the cache properly.

**How to check:**

1. Go to **Options** → **Advanced**
2. Find **Disk Cache** section
3. Check the value:
   - Should show: `-1` or "Enable OS cache" or "Automatic"
   - If it shows `0`, that's the problem!

**If cache shows 0 B in Statistics:**

##### Option 1: Set explicit cache size (Recommended)

1. Go to **Options** → **Advanced** → **Disk Cache**
2. Change from `-1` (OS cache) to a fixed size like `512` MB (or higher if you have RAM)
3. Click **Apply**
4. Restart qBittorrent: `sudo systemctl restart qbittorrent`
5. Check Statistics again - should show buffer size > 0

##### Option 2: Verify config file

```bash
# Check actual config value
sudo grep -i "DiskCacheSize" /var/lib/qBittorrent/config/qBittorrent.conf

# Should show: DiskCacheSize=-1 or DiskCacheSize=512 (or similar)
# If it shows DiskCacheSize=0, that's the problem!
```

**Recommended cache sizes:**

- **512 MB** - Minimum for decent performance
- **1024 MB (1 GB)** - Good for moderate usage
- **2048 MB (2 GB)** - Optimal for high-speed downloads
- **4096 MB (4 GB)** - Maximum for systems with lots of RAM

**Why cache is critical:**

- Without cache, every read/write goes directly to disk
- This causes severe I/O bottlenecks, especially with many connections
- Cache allows qBittorrent to batch disk operations
- Can improve speeds by 2-10x depending on disk type

#### 4. Protocol Settings (Options → BitTorrent)

**Current Configuration:**

- Protocol: `TCP` (good for VPN)
- uTP rate limit: `Enabled` (may affect speeds)

**uTP Rate Limiting:**

- If enabled, uTP connections may be throttled
- For maximum speed, consider disabling if you're using TCP protocol

**How to check:**

1. Go to **Options** → **BitTorrent**
2. Check **Protocol** setting
3. Go to **Options** → **Connection**
4. Check **uTP rate limit enabled** setting

**To disable uTP rate limiting:**

- Uncheck "uTP rate limit enabled"
- Click **Apply**

#### 5. Queue Settings (Options → BitTorrent)

**Current Configuration:**

- Queueing enabled: `true`
- Max active checking torrents: `1`
- Max active uploads: `0` (unlimited)
- Max active torrents: `0` (unlimited)

**Potential bottlenecks:**

- **Max active checking torrents: `1`** - Limits how many torrents can check files simultaneously
  - If you add many torrents, they'll queue for checking
  - Increase to `2-4` if you have fast storage
- **Queueing enabled** - Can limit concurrent downloads
  - If you want unlimited concurrent downloads, you can disable queueing
  - But queueing helps manage resources better

**How to check:**

1. Go to **Options** → **BitTorrent**
2. Scroll to **Torrent Queueing** section
3. Review active torrent limits

#### 6. Interface Binding (Options → Advanced)

**Critical for VPN:**

- Network Interface: Should be set to `qbittor0` (VPN interface)

**How to check:**

1. Go to **Options** → **Advanced**
2. Find **Network Interface** setting
3. Should show: `qbittor0` selected

**If not set correctly:**

- Select `qbittor0` from dropdown
- Click **Apply**
- Restart qBittorrent

#### 7. Port Forwarding Status (Options → Connection)

**Check port forwarding:**

1. Go to **Options** → **Connection**
2. Check **"Port forwarding status"**
3. Should show as **active** (green/working)

**If not working:**

- Verify `protonvpn-port-forwarding.service` is running
- Check service logs: `sudo journalctl -u protonvpn-port-forwarding.service`
- See [Port Forwarding](#port-forwarding) section for troubleshooting

### Performance Monitoring in WebUI

#### Transfer Tab

Monitor real-time performance:

1. Go to **Transfer** tab
2. Check columns:
   - **Download speed** - Should match your connection speed
   - **Upload speed** - Should utilize available bandwidth
   - **Peers** - More peers = better speeds (usually)
   - **Seeds** - More seeds = faster downloads

**What to look for:**

- **Low speeds with many peers:** May indicate connection limits too low
- **High speeds but frequent drops:** May indicate network/VPN issues
- **Consistent low speeds:** Check speed limits and connection limits

#### Statistics Tab

Check overall performance:

1. Go to **View** → **Statistics** (or click stats icon)
2. Review:
   - **Total downloaded/uploaded**
   - **Average download/upload speeds**
   - **Connection statistics**
   - **DHT nodes** (should show connected nodes)

**What to look for:**

- **Low average speeds:** Indicates consistent bottleneck
- **High connection failures:** May indicate connection limits too high or network issues
- **Low DHT nodes:** May affect peer discovery

### Common Bottleneck Scenarios

#### Scenario 1: Low Download Speed Despite Many Peers

**Possible causes:**

1. Speed limit set in qBittorrent
2. Connection limits too low
3. Upload slots too low (affects download speed via tit-for-tat)
4. VPN bandwidth limitation
5. Disk I/O bottleneck

**Check:**

```bash
# 1. Check speed limits
sudo scripts/utils/check-qbittorrent-throttling.sh

# 2. Check disk I/O
sudo iotop -o -d 1

# 3. Check VPN interface stats
sudo ip netns exec qbittor ip -s link show qbittor0
```

#### Scenario 2: High CPU Usage

**Possible causes:**

1. Too many connections
2. Encryption overhead
3. Disk cache issues
4. Many active torrents

**Solutions:**

- Reduce max connections if CPU is maxed out
- Check if disk cache is working (should be using RAM)
- Reduce number of active torrents

#### Scenario 3: Connection Drops/Failures

**Possible causes:**

1. Connection limits too high
2. Network/VPN instability
3. Port forwarding issues
4. Interface binding issues

**Check:**

```bash
# Check connection statistics in WebUI Statistics tab
# Check VPN connectivity
sudo ip netns exec qbittor ping -c 10 10.2.0.1

# Check port forwarding
sudo systemctl status protonvpn-port-forwarding.service
```

### Recommended Settings for High-Speed VPN

Based on your current configuration, here are optimal settings:

**Speed:**

- Global download limit: `0` (unlimited)
- Global upload limit: `0` (unlimited)

**BitTorrent:**

- Max connections: `2000-5000` (adjust based on RAM)
- Max connections per torrent: `200-500`
- Max uploads: `200-500`
- Max uploads per torrent: `5-10`
- Protocol: `TCP` (good for VPN)

**Advanced:**

- Disk cache: `-1` (OS cache - optimal)
- Network interface: `qbittor0` (VPN interface)
- uTP rate limit: `Disabled` (if using TCP protocol)

**Queue:**

- Max active checking: `2-4` (if you have fast storage)
- Max active uploads: `0` (unlimited)
- Max active torrents: `0` (unlimited)

### Verification Checklist

After checking settings, verify everything is optimal:

- [ ] Speed limits are set to `0` (unlimited)
- [ ] Connection limits are appropriate for your setup
- [ ] Disk cache is set to `-1` (OS cache)
- [ ] Network interface is bound to `qbittor0`
- [ ] Port forwarding status shows as active
- [ ] No traffic control rules limiting bandwidth
- [ ] VPN interface is working correctly
- [ ] No systemd resource limits restricting qBittorrent

**Quick verification command:**

```bash
# Run the throttling check script
sudo scripts/utils/check-qbittorrent-throttling.sh

# Check qBittorrent service status
sudo systemctl status qbittorrent

# Check VPN optimization service
sudo systemctl status qbittorrent-vpn-optimize.service
```

## Troubleshooting

### UDP Tracker Errors

**Problem:** UDP trackers report "Device or resource busy" errors

**Status:** Known qBittorrent issue with UDP tracker socket binding in network namespaces

**Symptoms:**

- UDP trackers show "Not working" with "Device or resource busy"
- TCP trackers work fine
- DHT, LSD, and PeX work correctly
- UDP connectivity from namespace works (`nc -vzu` succeeds)

**Root Cause:**
qBittorrent has a known issue binding UDP sockets for tracker announces in network namespaces. When qBittorrent tries to send UDP tracker announces, socket binding can conflict or hit resource limits.

**Workarounds:**

1. **Interface Binding:** Ensure qBittorrent is bound to VPN interface (already configured)
2. **Use TCP Trackers:** Remove UDP trackers from torrents (not recommended)
3. **Wait for Fix:** Monitor qBittorrent releases for namespace UDP fixes
4. **Alternative Client:** Consider using a different BitTorrent client if UDP trackers are critical

**Impact:**

- Downloads may still work via TCP trackers or DHT/PeX
- BitTorrents with multiple trackers may still work
- Peer connections work (can still download/upload)

### Port Forwarding Issues

**Service Fails to Start:**

- **Error:** "VPN namespace qbittor not found"
- **Solution:** Ensure VPN-Confinement namespace is configured and starts before this service

**Port Forwarding Fails:**

- **WireGuard config doesn't have NAT-PMP enabled:** Regenerate config with NAT-PMP enabled
- **Wrong gateway IP:** Verify gateway IP: `sudo ip netns exec qbittor ip route | grep default`
- **Not connected to P2P server:** Ensure WireGuard config is for a P2P server
- **Free ProtonVPN plan:** Port forwarding requires a paid plan

**qBittorrent Doesn't Use Forwarded Port:**

- Ensure `PortForwardingEnabled = true` in qBittorrent config
- qBittorrent's NAT-PMP should automatically detect the forwarded port
- If not working, manually configure the port in qBittorrent WebUI

### Gateway IP Issues

If your ProtonVPN gateway IP is not `10.2.0.1`:

1. Find the actual gateway:

   ```bash
   sudo ip netns exec qbittor ip route | grep default
   ```

2. Update `protonvpnGateway` in `qbittorrent-vpn-confinement.nix`

### NAT-PMP State File Permissions

**Issue:** Permission errors for `.natpmp-state` directory

**Solution:** Already fixed in configuration - qBittorrent user has correct permissions

## Manual Setup

### Quick Test: Manual Interface Binding

If you want to test interface binding immediately without rebuilding NixOS:

#### Method 1: Via WebUI (Easiest)

1. Open qBittorrent WebUI: `http://192.168.15.1:8080/`
2. Navigate to: Options > Advanced
3. Set **"Network Interface"** to `qbittor0`
4. Click **Apply** or **OK**
5. Restart qBittorrent: `sudo systemctl restart qbittorrent`

#### Method 2: Via Config File

1. Edit config: `sudo nano /var/lib/qBittorrent/config/qBittorrent.conf`
2. Find `[BitTorrent]` section and add:

   ```ini
   [BitTorrent]
   Session\InterfaceName=qbittor0
   ```

3. Save and restart: `sudo systemctl restart qbittorrent`

**Note:** Manual changes will be overwritten when you rebuild NixOS configuration.

## Architecture Best Practices

### Recommended Future Improvements

#### Option 1: Dedicated Namespace Service + NetworkNamespacePath (Recommended)

**Benefits:**

- ✅ systemd manages namespace lifecycle (proper dependencies)
- ✅ No `CAP_SYS_ADMIN` needed for qbittorrent service
- ✅ Cleaner separation of concerns
- ✅ Better error handling and logging
- ✅ Follows NixOS service patterns

**Structure:**

1. `qbittorrent-vpn-namespace.service` - Creates and manages namespace (oneshot, RemainAfterExit)
2. WireGuard interface created normally (can be moved to namespace by namespace service)
3. qbittorrent service uses `NetworkNamespacePath` pointing to `/var/run/netns/wg-qbittorrent`

**Example Implementation:**

```nix
systemd.services.qbittorrent = {
  after = [ "qbittorrent-vpn-namespace.service" ];
  requires = [ "qbittorrent-vpn-namespace.service" ];

  serviceConfig = {
    # Use systemd's native namespace support
    NetworkNamespacePath = lib.mkIf vpnEnabled "/var/run/netns/${namespace}";
    ExecStart = "${lib.getExe cfg.qbittorrent.package} --webui-port=${toString cfg.qbittorrent.webUI.port}";
    # No CAP_SYS_ADMIN needed!
    NoNewPrivileges = true;
  };
};
```

#### Option 2: Simpler Interface Binding (Less Isolation)

- Bind qbittorrent to WireGuard interface IP address
- Use firewall rules to prevent leaks
- Less isolation - if VPN drops, might leak (but firewall helps)

#### Option 3: Policy-Based Routing (Most Complex)

- Use iptables/nftables to route traffic from namespace through WireGuard
- WireGuard stays in default namespace
- Full routing control but more complex setup

## Related Files

- **VPN-Confinement config:** `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix`
- **qBittorrent config:** `modules/nixos/services/media-management/qbittorrent-standard.nix`
- **WireGuard config:** Stored in SOPS as `vpn-confinement-qbittorrent`

## Notes

- **Port assignment:** ProtonVPN assigns a random public port (e.g., 53186), which forwards to your private port (6881)
- **Port changes:** The public port may change when reconnecting to VPN - the service handles this automatically
- **qBittorrent listening port:** Keep qBittorrent configured to listen on port **6881** (the private port)
- **Security:** Port forwarding only works through ProtonVPN's secure gateway - your real IP is never exposed
- **Interface name:** Hardcoded as `qbittor0` based on VPN-Confinement's naming pattern (`<namespace-name>0`)

## References

- [ProtonVPN Port Forwarding Manual Setup](https://protonvpn.com/support/port-forwarding-manual-setup)
- [VPN-Confinement Documentation](https://github.com/placek/vpn-confinement)
