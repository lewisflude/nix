# Phase 1 Network Performance Optimization - Complete

## Summary

Applied comprehensive network and CPU tuning to eliminate latency spikes and optimize routing/VPN performance for a high-bandwidth home server with ZFS, MergerFS, VPNs, and virtualization.

## Changes Applied

### 1. CPU C-State Limiting (`boot.kernelParams`)

**Problem:** Deep CPU sleep states (C3/C6) take microseconds to wake up, causing packet processing delays on 1Gbps links where packets arrive every ~12 microseconds.

**Solution:** Limit CPU to C1 sleep state for consistent low-latency packet processing.

```nix
boot.kernelParams = [
  "processor.max_cstate=1"   # Limit CPU sleep states
  "intel_idle.max_cstate=1"  # Intel-specific C-state limiting
];
```

**Trade-off:** Slight increase in idle power consumption (~5-10W) for dramatically reduced latency jitter.

### 2. LRO/GRO Offloading Tuning (`systemd.services.network-tuning`)

**Problem:** Large Receive Offload (LRO) aggregates packets at the hardware level, destroying packet headers needed for routing, VPN encapsulation, and VLAN forwarding. This forces the kernel to re-segment packets in software, burning CPU and causing jitter.

**Solution:** Disable LRO (hardware offload) but keep GRO (software-friendly Generic Receive Offload) enabled.

```nix
systemd.services.network-tuning = {
  description = "Disable LRO and enable GRO on eno2 for router/VPN performance";
  after = [ "network.target" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${pkgs.ethtool}/bin/ethtool -K eno2 lro off gro on";
  };
};
```

### 3. MergerFS Caching (No Change Required)

**Current Config:** `cache.files=partial` in MergerFS configuration.

**Why Correct:** Applications like qBittorrent use `mmap()` for file I/O, which breaks if caching is completely disabled (`direct_io`). The `partial` setting provides optimal balance for torrent workloads.

**Action:** **No change needed** - existing configuration is optimal.

## Verification Steps

After rebuilding the system (`sudo nixos-rebuild switch`), verify the changes:

### 1. Verify CPU C-State Limiting

```bash
# Check current C-state limit (should show "1")
cat /sys/module/intel_idle/parameters/max_cstate

# Alternative check
cat /sys/module/processor/parameters/max_cstate
```

**Expected Output:** `1`

### 2. Verify LRO is Disabled

```bash
# Check LRO status on eno2 (should be "off")
ethtool -k eno2 | grep large-receive-offload

# Check GRO status (should be "on")
ethtool -k eno2 | grep generic-receive-offload
```

**Expected Output:**

```
large-receive-offload: off
generic-receive-offload: on
```

### 3. Verify Service Started

```bash
# Check network-tuning service status
systemctl status network-tuning.service
```

**Expected Output:** Should show `active (exited)` with exit code 0.

## Performance Impact

### Expected Improvements

1. **Reduced Latency Jitter:** CPU always ready to process packets (no wake-up delays)
2. **Better VPN Performance:** Proper packet headers preserved through routing
3. **Improved VLAN Forwarding:** No re-segmentation overhead
4. **Consistent Throughput:** Eliminates micro-stutters from LRO re-segmentation

### Before/After Testing

Run these tests before and after the optimization:

```bash
# Latency consistency test (run from remote client to server)
ping -c 100 <server-ip> | tail -1

# VPN throughput test (through VLAN 2 interface)
./scripts/test-vlan2-speed.sh

# qBittorrent connectivity check
./scripts/test-qbittorrent-connectivity.sh
```

**What to Look For:**

- **Ping:** Lower standard deviation in RTT (more consistent latency)
- **Throughput:** Higher sustained speeds with fewer drops
- **qBittorrent:** Better peer connections and upload consistency

## Technical Background

### Why LRO Breaks Routing

LRO operates at the hardware level, combining multiple incoming packets into one giant "super-packet" before the CPU sees it. This:

1. **Destroys IP/TCP headers** needed for routing decisions
2. **Breaks VLAN tags** that identify which network the packet belongs to
3. **Confuses VPN encapsulation** which needs original packet boundaries
4. **Forces kernel re-segmentation** which burns CPU unnecessarily

**GRO vs LRO:**

- **GRO (Generic Receive Offload):** Software-based aggregation that preserves headers and works correctly with routing/VPN
- **LRO (Large Receive Offload):** Hardware-based aggregation that's great for pure servers but terrible for routers

### Why C-State Limiting Matters

Modern CPUs aggressively sleep to save power:

- **C0:** CPU active (no sleep)
- **C1:** Light sleep (~1μs wake time)
- **C3:** Medium sleep (~10-20μs wake time)
- **C6:** Deep sleep (~50-100μs wake time)

On a 1Gbps link:

- **Packet arrival rate:** 1 packet every ~12μs (at 1500 byte MTU)
- **C6 wake time:** 50-100μs = **4-8 packets delayed**

Result: Packet processing "stutters" as CPU wakes from deep sleep.

**Solution:** Limit to C1 (1μs wake) which is negligible compared to packet arrival rate.

## Files Modified

- `modules/nixos/core/networking.nix` - Added CPU C-state limiting and LRO/GRO tuning

## References

- [Kernel TCP Tuning](https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt)
- [Intel C-States Documentation](https://www.kernel.org/doc/Documentation/admin-guide/pm/intel_idle.rst)
- [Understanding Network Offload](https://lwn.net/Articles/358910/)
- [BBR Congestion Control](https://queue.acm.org/detail.cfm?id=3022184)

## Next Steps

After verifying these optimizations:

1. **Monitor power consumption** - C-state limiting increases idle power (~5-10W)
2. **Run performance benchmarks** - Compare before/after throughput and latency
3. **Check VPN stability** - Ensure ProtonVPN port forwarding remains stable
4. **Monitor qBittorrent seeding** - Verify improved peer connectivity

## Rollback Instructions

If issues arise, rollback by commenting out the new sections:

```nix
# Comment out in modules/nixos/core/networking.nix:
# boot.kernelParams = [ ... ];
# systemd.services.network-tuning = { ... };
```

Then rebuild: `sudo nixos-rebuild switch`

---

**Optimization Level:** Phase 1 - Hardware/Kernel Tuning
**Status:** ✅ Complete
**Date:** 2025-11-26
