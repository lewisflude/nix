# Network Testing & Optimization Scripts

Scripts for network performance testing, MTU optimization, and speed benchmarking. These tools help diagnose and optimize network connectivity for both regular interfaces and VPN namespaces.

**Integration**: Standalone diagnostic tools

## Available Scripts (3 scripts)

### MTU Optimization

#### `optimize-mtu.sh`

**Integration**: standalone (manual execution)
**Purpose**: Automatically discover and optimize MTU (Maximum Transmission Unit) for regular network and VPN interfaces using Path MTU Discovery

**Usage**:

```bash
# Test both regular network and VPN (recommended)
sudo ./scripts/network/optimize-mtu.sh

# Test only VPN (prioritize qBittorrent/VPN performance)
sudo ./scripts/network/optimize-mtu.sh --vpn-only

# Test only regular network
sudo ./scripts/network/optimize-mtu.sh --regular-only

# Test and apply settings
sudo ./scripts/network/optimize-mtu.sh --apply

# Dry-run to see recommendations
sudo ./scripts/network/optimize-mtu.sh --apply --dry-run
```

**What it does**:

1. Uses binary search with ping + "Don't Fragment" flag to find optimal MTU
2. Tests both regular network interface and VPN namespace
3. Discovers the largest packet size that doesn't fragment
4. Provides specific recommendations for:
   - NixOS configuration (`networking.interfaces.<iface>.mtu`)
   - WireGuard configuration (`MTU = <value>` in SOPS secret)
   - UniFi Dream Machine setup (DHCP options or per-port settings)

**How it works**:

- Sends ping packets with increasing sizes and DF (Don't Fragment) flag
- Uses binary search to efficiently find optimal MTU (typically 8-12 tests)
- Accounts for IP/ICMP header overhead (28 bytes)
- Tests against reliable hosts (1.1.1.1 for regular, 8.8.8.8 for VPN)

**Output Example**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 MTU Optimization Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Regular Network (enp5s0):
  Current MTU: 1500
  Optimal MTU: 1500
  Status: ✓ OPTIMAL

VPN Namespace (qbt):
  Current MTU: 1420
  Optimal MTU: 1380
  Status: ⚠️ NEEDS ADJUSTMENT

Recommendations:

1. Update WireGuard configuration:
   # In your SOPS secret: secrets/protonvpn-wireguard.yaml
   MTU = 1380

2. Apply to NixOS configuration:
   networking.interfaces.wg0.mtu = 1380;

3. Rebuild system:
   nh os switch

Verification:
  ping -M do -s 1352 -c 5 8.8.8.8  # Should not fragment
```

**Critical for VPN**:
Proper MTU is essential for VPN performance! WireGuard adds ~80 bytes overhead, so MTU must be lowered to avoid fragmentation. The script automatically accounts for this.

**UniFi Dream Machine Integration**:
The script provides two methods for applying MTU on UniFi:

1. Network-wide via DHCP Option 26
2. Per-port in device settings (recommended for specific devices)

---

### Speed Testing

#### `test-vlan2-speed.sh`

**Integration**: standalone diagnostic tool
**Purpose**: Test network speed through VLAN 2 (isolated network segment)

**Usage**:

```bash
./scripts/network/test-vlan2-speed.sh
```

**Tests**:

- Download speed from VLAN 2 host
- Upload speed to VLAN 2 host
- Latency/ping to VLAN 2 gateway
- Packet loss percentage
- MTU discovery

**Use cases**:

- Verify VLAN 2 connectivity
- Benchmark isolated network performance
- Troubleshoot segmentation issues
- Measure VPN performance impact

**Output Example**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 VLAN 2 Speed Test
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Testing connection to VLAN 2 gateway (10.2.0.1)...
✓ Gateway reachable (latency: 2.3ms)

Download: 850 Mbps
Upload:   450 Mbps
Latency:  2.3ms (avg)
Jitter:   0.5ms
Loss:     0%

✓ VLAN 2 performance is optimal
```

---

#### `test-sped.sh`

**Integration**: standalone diagnostic tool
**Purpose**: Simple speed test wrapper using common speed test tools

**Usage**:

```bash
./scripts/network/test-sped.sh
```

**Tests**:

- Internet download speed
- Internet upload speed
- Latency to test server
- ISP information

**Uses**: Attempts to use `speedtest-cli`, `fast-cli`, or `curl` benchmarks in order of availability.

**Output Example**:

```
Running speed test...

Download: 950 Mbps
Upload:   500 Mbps
Latency:  15ms
Server:   London, UK (Vodafone)
```

**Quick usage**:

```bash
# Run speed test
./scripts/network/test-sped.sh

# Compare regular vs VPN speed
./scripts/network/test-sped.sh  # Regular
sudo ip netns exec qbt ./scripts/network/test-sped.sh  # VPN
```

---

## Common Workflows

### 1. Diagnose Slow Network Performance

```bash
# Step 1: Check MTU is optimal
sudo ./scripts/network/optimize-mtu.sh

# Step 2: Test actual speeds
./scripts/network/test-sped.sh

# Step 3: If VPN is slow, test VPN specifically
sudo ip netns exec qbt ./scripts/network/test-sped.sh

# Step 4: Check VPN MTU
sudo ./scripts/network/optimize-mtu.sh --vpn-only
```

### 2. Optimize qBittorrent VPN Performance

```bash
# Discover optimal MTU for VPN
sudo ./scripts/network/optimize-mtu.sh --vpn-only

# Apply recommendations to SOPS secret
# Edit: secrets/protonvpn-wireguard.yaml
# Set: MTU = <recommended-value>

# Rebuild system
nh os switch

# Verify improvements
./scripts/media/test-vpn-port-forwarding.sh
```

### 3. Benchmark Network Improvements

```bash
# Before changes
./scripts/network/test-sped.sh > baseline.txt
./scripts/network/test-vlan2-speed.sh >> baseline.txt

# Make changes (MTU, routing, etc.)

# After changes
./scripts/network/test-sped.sh > after.txt
./scripts/network/test-vlan2-speed.sh >> after.txt

# Compare
diff baseline.txt after.txt
```

---

## MTU Background

### What is MTU?

**MTU (Maximum Transmission Unit)** is the largest packet size that can be transmitted over a network without fragmentation.

- **Standard Ethernet MTU**: 1500 bytes
- **VPN overhead**: ~80 bytes (WireGuard), ~150 bytes (OpenVPN)
- **Optimal VPN MTU**: Usually 1380-1420 bytes

### Why MTU Matters

#### Fragmentation = Performance Loss

- When packets exceed MTU, they're fragmented into smaller packets
- Fragmentation increases latency and reduces throughput
- Can cause packet loss and connection instability

#### VPNs Need Lower MTU

- VPN protocols add encryption/encapsulation overhead
- If VPN MTU = Network MTU, packets will fragment
- Result: Slow speeds, high latency, packet loss

### Path MTU Discovery (PMTUD)

The `optimize-mtu.sh` script uses **Path MTU Discovery**:

1. Send packets with "Don't Fragment" (DF) flag set
2. If packet is too large, receive ICMP "Fragmentation Needed" response
3. Binary search to find largest non-fragmenting size
4. Account for IP/ICMP header overhead (28 bytes)

**Formula**: `MTU = Optimal Packet Size + 28 bytes`

---

## Troubleshooting

### MTU optimization fails

**Symptoms**: Script can't find optimal MTU, all packets fragment

**Solutions**:

1. Check firewall allows ICMP: `sudo iptables -L | grep ICMP`
2. Verify target host responds to ping: `ping -c 1 8.8.8.8`
3. Test manually: `ping -M do -s 1472 -c 1 8.8.8.8`
4. Check network interface exists: `ip link show`

### VPN speed is slow even with optimal MTU

**Check**:

1. VPN server location (distance affects latency)
2. VPN server load (try different server)
3. Network congestion (test at different times)
4. ISP throttling VPN traffic

**Diagnose**:

```bash
# Test VPN latency
sudo ip netns exec qbt ping -c 10 8.8.8.8

# Compare VPN vs regular speeds
./scripts/network/test-sped.sh  # Regular
sudo ip netns exec qbt ./scripts/network/test-sped.sh  # VPN
```

### Speed tests fail in VPN namespace

**Symptoms**: `test-sped.sh` hangs or fails when run in VPN namespace

**Solutions**:

1. Check VPN connectivity: `sudo ip netns exec qbt ping 8.8.8.8`
2. Verify DNS resolution: `sudo ip netns exec qbt nslookup google.com`
3. Check routing: `sudo ip netns exec qbt ip route show`

---

## Dependencies

Required packages:

- `iproute2` - Network interface management
- `iputils` - ping command
- `curl` - Speed testing fallback
- `speedtest-cli` (optional) - Speed testing
- `fast-cli` (optional) - Netflix speed test

Install missing dependencies:

```bash
nix-shell -p iproute2 iputils curl speedtest-cli
```

---

## Integration with Other Scripts

### Used by Media Scripts

```bash
# MTU optimization improves VPN performance
./scripts/network/optimize-mtu.sh --vpn-only
# Then test qBittorrent
./scripts/media/test-vpn-port-forwarding.sh
```

### Used in Diagnostics

```bash
# Network speed affects SSH performance
./scripts/network/test-sped.sh
./scripts/diagnostics/diagnose-ssh-slowness.sh hostname
```

---

## See Also

- [qBittorrent VPN Optimization Guide](../../docs/QBITTORRENT_VPN_OPTIMIZATION.md)
- [Media Scripts](../media/README.md) - VPN port forwarding
- [Diagnostic Scripts](../diagnostics/README.md) - SSH performance
- [Network Configuration](../../modules/nixos/networking/) - NixOS network config
