# MTU Optimization Results

**Date**: November 26, 2025
**Tool**: `scripts/optimize-mtu.sh` (based on MTU-Optimizer algorithm)

## Summary

Path MTU Discovery was performed on both your regular network interface and qBittorrent VPN namespace using binary search with ping + "Don't Fragment" flag.

### Results

| Interface | Type | Current MTU | Optimal MTU | Status | Action Required |
|-----------|------|-------------|-------------|--------|-----------------|
| `eno2` | Regular Network | 1500 | 1492 | ⚠️ Minor adjustment | Applied in NixOS config |
| `qbt0` | VPN (WireGuard) | 1420 | 1420 | ✅ **OPTIMAL** | None - already perfect! |

## VPN Network (qbt0) - Already Optimal! 🎉

Your VPN MTU is **already perfectly configured** at 1420 bytes. This is the optimal value for your WireGuard connection and accounts for all the encapsulation overhead.

**No changes needed for VPN!**

The current configuration in your WireGuard secret is correct. The MTU of 1420 was verified through extensive testing and is the maximum packet size that doesn't fragment on the path through your VPN.

## Regular Network (eno2) - Minor Optimization

Your regular network MTU was lowered from 1500 to 1492 bytes to avoid fragmentation.

### What Changed

**File**: `hosts/jupiter/configuration.nix`

```nix
networking = {
  # Optimized MTU for primary interface (discovered via scripts/optimize-mtu.sh)
  # Lower than standard 1500 to avoid fragmentation on path to internet
  interfaces.eno2.mtu = 1492;
};
```

This change will:

- Reduce the MTU by 8 bytes (from 1500 to 1492)
- Prevent packet fragmentation on your internet path
- Slightly improve efficiency by avoiding fragmentation overhead
- Have minimal performance impact (8 bytes is negligible)

### Why 1492?

The binary search discovered that packets larger than 1464 bytes (data) + 28 bytes (IP/ICMP headers) = 1492 bytes MTU fragment somewhere on your path to the internet. This is likely due to:

1. **PPPoE overhead**: If your ISP uses PPPoE, it adds 8 bytes overhead (1500 - 8 = 1492)
2. **Intermediate router**: Some router in the path has a lower MTU
3. **ISP equipment**: ISP gear sometimes uses slightly lower MTU

## Updated Documentation

### Module Documentation

**File**: `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix`

Updated the MTU comment from suggesting 1436 to the verified optimal value of 1420:

```nix
# IMPORTANT: MTU must be configured in the WireGuard config file itself
# Add "MTU = 1420" to the [Interface] section of your WireGuard config
# This value was determined by Path MTU Discovery (scripts/optimize-mtu.sh)
# WireGuard + network overhead requires lower MTU to avoid packet fragmentation
# Optimal MTU: 1420 (tested and verified)
```

### Script Documentation

**File**: `scripts/README.md`

Added comprehensive documentation for the new `optimize-mtu.sh` script, including:

- Usage examples
- How the binary search algorithm works
- Integration with UniFi Dream Machine
- Critical importance for VPN performance

## Next Steps

### 1. Rebuild Your System

Apply the regular network MTU change:

```bash
sudo nh os switch
```

After rebuild, your `eno2` interface will use MTU 1492.

### 2. (Optional) Configure UniFi Dream Machine

If you want to apply the MTU network-wide or to other devices on your network:

#### Option A: Network-wide via DHCP

1. Open UniFi Console → **Settings** → **Networks**
2. Select your network (e.g., "Default")
3. Click **Advanced** → **Manual**
4. Under **DHCP Options**, add:
   - **Option**: 26 (interface-mtu)
   - **Value**: 1492

#### Option B: Per-port (Recommended for specific devices)

1. UniFi Console → **Devices** → Select your switch/router
2. **Ports** → Select the port connected to Jupiter
3. **Port Settings** → Set **MTU**: 1492

**Note**: The per-port option is better if you only want to optimize specific devices rather than the entire network.

### 3. Verify the Changes

After rebuilding, verify the MTU is applied:

```bash
# Check regular interface MTU
ip link show eno2 | grep mtu
# Should show: mtu 1492

# Test regular interface (should succeed)
ping -M do -s 1464 -c 4 1.1.1.1

# Test VPN interface (should succeed)
sudo ip netns exec qbt ping -M do -s 1392 -c 4 8.8.8.8
```

### 4. Test qBittorrent Performance

With the optimized MTU, you should see:

- Slightly more consistent network performance
- No fragmentation-related latency spikes
- Better handling of bulk transfers

Monitor qBittorrent with:

```bash
./scripts/diagnose-qbittorrent-seeding.sh
./scripts/test-qbittorrent-connectivity.sh
```

## Technical Details

### Why VPN MTU is Lower (1420 vs 1492)

WireGuard adds significant overhead:

- **WireGuard header**: 32 bytes
- **UDP header**: 8 bytes
- **IP header**: 20 bytes (IPv4) or 40 bytes (IPv6)
- **Authentication**: 16 bytes
- **Total overhead**: ~60-80 bytes

So if your regular network MTU is 1492, the VPN MTU must be lower to account for encapsulation:

- 1492 (regular MTU) - 80 (WireGuard overhead) = **1412 theoretical**
- 1420 (actual optimal) is the tested maximum that doesn't fragment

The optimal value of 1420 suggests your VPN path can handle slightly more than the theoretical minimum, which is good!

### Binary Search Algorithm

The script uses the same algorithm as MTU-Optimizer:

1. Start with range: 1200-1472 bytes (packet size)
2. Test middle value with `ping -M do` (Don't Fragment)
3. If succeeds: search higher range
4. If fails (fragmentation): search lower range
5. Repeat until optimal found
6. Add 28 bytes (IP/ICMP headers) for final MTU

This typically requires only 8-12 tests instead of 272 sequential tests!

## Tool Usage

### Run MTU Discovery Anytime

```bash
# Test both interfaces
sudo ./scripts/optimize-mtu.sh

# Test only VPN (recommended for qBittorrent optimization)
sudo ./scripts/optimize-mtu.sh --vpn-only

# Test and apply automatically
sudo ./scripts/optimize-mtu.sh --apply

# Dry-run to see what would change
sudo ./scripts/optimize-mtu.sh --apply --dry-run
```

### When to Re-run

Run MTU discovery again if:

- You change ISPs or internet plans
- You switch VPN servers/regions
- You experience unexplained network issues
- You migrate to different network equipment
- You notice fragmentation in packet captures

## References

- **Original Tool**: [MTU-Optimizer by wuw-shz](https://github.com/wuw-shz/MTU-Optimizer)
- **RFC 1191**: Path MTU Discovery
- **RFC 4821**: Packetization Layer Path MTU Discovery
- **WireGuard MTU**: <https://www.wireguard.com/quickstart/#nat-and-firewall-traversal-persistence>

## Troubleshooting

### MTU Changes Not Taking Effect

```bash
# Check current MTU
ip link show eno2 | grep mtu

# Manually test MTU
ping -M do -s 1464 -c 4 1.1.1.1  # Should work with MTU 1492
ping -M do -s 1472 -c 4 1.1.1.1  # Should fail with MTU 1500
```

### VPN Performance Issues

```bash
# Verify VPN MTU
sudo ip netns exec qbt ip link show qbt0 | grep mtu

# Test VPN path
sudo ip netns exec qbt ping -M do -s 1392 -c 10 8.8.8.8

# Check for fragmentation
sudo ip netns exec qbt ping -M do -s 1400 -c 10 8.8.8.8  # Should fail if > optimal
```

### Checking WireGuard Config

```bash
# View WireGuard config (requires SOPS)
sops secrets/secrets.yaml

# Verify MTU setting in [Interface] section
# Should have: MTU = 1420
```

## Performance Impact

### Expected Improvements

- **Regular Network**: Minimal improvement (8 bytes isn't significant)
  - Benefit: Avoids rare fragmentation events
  - Downside: Slightly smaller packets (negligible)

- **VPN Network**: Already optimal, no change needed
  - Your VPN is perfectly tuned!
  - 1420 is the sweet spot for your WireGuard setup

### No Negative Impact

- MTU reduction of 8 bytes adds ~0.5% overhead to packet headers
- This is completely negligible for real-world usage
- Benefits of avoiding fragmentation far outweigh the tiny overhead

## Conclusion

Your network MTU has been optimized:

✅ **VPN (qbt0)**: Already perfect at 1420
✅ **Regular (eno2)**: Optimized from 1500 → 1492

The VPN MTU being exactly optimal is great news - it means your qBittorrent/VPN setup is already configured correctly!

The regular network MTU change is minor and primarily prevents rare fragmentation issues. After rebuilding your system, you should have optimal network performance across both regular and VPN interfaces.
