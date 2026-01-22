# Performance Optimizations Guide

This document explains the comprehensive performance optimizations applied to this NixOS configuration, based on the [Arch Linux Performance Guide](https://wiki.archlinux.org/title/Improving_performance).

## Overview

The configuration includes two main performance modules:

1. **System Performance** (`modules/nixos/system/disk-performance.nix`) - VM, I/O, network, and memory
2. **CPU Performance** (`modules/nixos/system/cpu-performance.nix`) - CPU scheduling and frequency scaling

## Modules Overview

This configuration uses six main performance modules:

1. **System Performance** (`modules/nixos/system/disk-performance.nix`) - VM, I/O, network, and memory
2. **CPU Performance** (`modules/nixos/system/cpu-performance.nix`) - CPU scheduling and frequency scaling
3. **I/O Priority** (`modules/nixos/system/io-priority.nix`) - Background task scheduling
4. **Gaming Latency** (`modules/nixos/system/gaming-latency.nix`) - Response time consistency for gaming
5. **PCI Latency** (`modules/nixos/system/pci-latency.nix`) - PCI Express bus latency tuning
6. **Scheduler** (`modules/nixos/system/scheduler.nix`) - Alternative CPU schedulers (sched_ext)

## Module: System Performance (diskPerformance)

Location: `modules/nixos/system/disk-performance.nix`

### VM/Memory Tuning (`enableVMTuning`)

**Purpose:** Optimize memory management and cache behavior for systems with large RAM.

**Key Settings:**

```nix
vm.swappiness = 10              # Prefer keeping things in RAM (default: 60)
vm.dirty_ratio = 40             # 40% of RAM can be dirty before forced flush
vm.dirty_background_ratio = 15  # Start background flush at 15%
vm.dirty_writeback_centisecs = 6000  # Flush every 60s (vs default 5s)
vm.vfs_cache_pressure = 50      # Prefer keeping cache (default: 100)
```

**Trade-offs:**
- ✅ Better performance with lots of RAM
- ✅ Fewer disk writes (extends SSD life)
- ⚠️ More data loss potential on unexpected power loss

### I/O Tuning (`enableIOTuning`)

**Purpose:** Optimize disk I/O schedulers and queue depths per device type.

**I/O Schedulers:**
- **HDDs:** BFQ (Budget Fair Queuing) - best responsiveness for rotational media
- **SSDs:** BFQ - good for SATA SSDs with fairness
- **NVMe:** none - no scheduling overhead for ultra-fast drives

**Queue Depth & Read-ahead:**
- HDD: NCQ depth=31, read-ahead=2MB (sequential media workloads)
- SSD: read-ahead=512KB (balanced)
- NVMe: queue depth=1023, read-ahead=512KB (maximum parallelism)

**Why BFQ?**
- Focuses on low latency over maximum throughput
- Excellent for desktop responsiveness
- Prevents starvation of interactive tasks
- Can significantly improve application startup times on HDDs

### Network Tuning (`enableNetworkTuning`)

**Purpose:** Optimize TCP/IP stack for modern high-speed networks.

**Key Features:**
- **TCP BBR** congestion control (better than cubic)
- **Large buffers** (64MB) for high-bandwidth transfers
- **TCP FastOpen** enabled
- **MTU probing** enabled
- **Aggressive keepalive** settings

**Benefits:**
- Better throughput on fast networks
- Lower latency for remote connections
- Improved SSH performance
- Better for streaming and large file transfers

### OOM Handling (`enableOOMHandling`)

**Purpose:** Prevent system freezes under memory pressure.

**How it works:**
- systemd-oomd monitors memory pressure using PSI (Pressure Stall Information)
- Proactively kills processes before kernel OOM killer
- Prioritizes killing user processes over system services
- Default threshold: 20 seconds of sustained pressure

**Why needed:**
- Traditional OOM killer only activates when completely out of memory
- System can become unresponsive for minutes before OOM killer acts
- systemd-oomd acts earlier, keeping system responsive

### zram (`enableZram`)

**Purpose:** Compressed RAM swap to reduce SSD writes and improve memory efficiency.

**When to enable:**
- Systems with limited RAM (< 16GB recommended)
- Laptops to extend battery life
- Systems with slow swap devices

**When to disable:**
- Systems with plenty of RAM (64GB+)
- Systems with fast dedicated swap
- Minimal benefit on high-RAM gaming systems

**Settings:**
```nix
algorithm = "zstd"           # Fast compression
memoryPercent = 50           # Use 50% of RAM
priority = 100               # Higher than disk swap
```

### Core Dumps (`disableCoreDumps`)

**Purpose:** Save disk space and improve performance.

**Impact:**
- No core dumps written on application crashes
- Faster process termination
- Less disk I/O

**Trade-off:** Harder to debug crashes (but rarely needed on desktop systems)

## Module: I/O Priority Management (ioPriority)

Location: `modules/nixos/system/io-priority.nix`

### Purpose

Prevents background tasks from impacting gaming and desktop responsiveness by using Linux I/O scheduling classes (ionice).

### How It Works

Linux provides three I/O scheduling classes:
- **Best-effort** (default) - Normal priority
- **Realtime** - Highest priority (dangerous, root only)
- **Idle** - Only uses disk when no other I/O is happening

This module automatically sets maintenance tasks to **idle** priority:
- SSD TRIM operations
- ZFS scrubbing and trimming
- Nix garbage collection

### Configuration

```nix
nixosConfig.ioPriority = {
  enable = true;
  backgroundServices = [ "docker" "backup" ]; # Add custom services here
};
```

### Benefits

- Gaming and interactive applications get full I/O bandwidth
- Background tasks run without impacting performance
- System stays responsive during maintenance operations
- No need to manually nice or ionice processes

### When NOT to Enable

- Servers where background tasks need predictable completion times
- Systems where you want fast nix builds (though builds will still be reasonably fast)

## Module: CPU Performance (cpuPerformance)

Location: `modules/nixos/system/cpu-performance.nix`

### IRQ Balancing (`enableIrqbalance`)

**Default:** Disabled

**Why disabled by default:**
- Known to cause stuttering in games
- Can interfere with video playback
- Modern kernels handle IRQ distribution well

**When to enable:**
- Specific server workloads
- Systems with many high-throughput devices
- Never on gaming/desktop systems

### CPU Frequency Scaling

**Purpose:** Balance performance and power efficiency.

**Governors:**
- `performance` - Maximum frequency always (gaming/desktop)
- `powersave` - Lowest frequency (laptops)
- `schedutil` - Kernel scheduler-driven (good middle ground)
- `ondemand` - Load-based (legacy)

**Jupiter Config:** `performance` for gaming workstation

### CPU Exploit Mitigations (`disableMitigations`)

**Default:** Disabled (mitigations enabled)

**Performance Impact:**
- Modern CPUs (Intel 10th gen+, Ryzen 1000+): 0-5% improvement
- Older CPUs: up to 25% improvement

**Security Risk:**
- Vulnerable to Spectre, Meltdown, and similar attacks
- Do NOT rely on VMs for security isolation if disabled
- Only disable if you understand and accept the risks

**Recommendation:** Keep disabled unless you have a specific need

## XFS Optimizations

Location: `modules/nixos/features/xfs.nix`

### Metadata Scrubbing

**Purpose:** Detect corruption early before it spreads.

**Schedule:** Weekly (configurable)

**How it works:**
- Runs `xfs_scrub_all` to verify metadata consistency
- Runs at idle I/O priority (doesn't impact performance)
- Logs any issues found

### Writeback Tuning

**Purpose:** Reduce write frequency for better HDD performance.

**Setting:** `fs.xfs.xfssyncd_centisecs = 10000` (100 seconds vs default 30s)

**Trade-off:**
- ✅ Better performance, fewer writes
- ⚠️ More data loss potential on power failure

### Mount Options

Applied to `/mnt/disk1` and `/mnt/disk2`:

```
logbufs=8          # More in-memory log buffers
logbsize=256k      # Larger log buffer size
allocsize=64m      # Preallocation for buffered I/O
largeio            # Optimize for large sequential I/O (media files)
swalloc            # Stripe-width allocation for large files
```

**Purpose:** Optimize XFS for large sequential media files.

## Gaming Optimizations

### vm.max_map_count

**Location**: `modules/nixos/system/disk-performance.nix`

```nix
vm.max_map_count = 2147483642  # When gaming.enable = true
```

**Purpose:** Modern games (Star Citizen, Cyberpunk 2077, etc.) require high memory map counts.

**Default:** 262144 (too low for many games)

### Steam Shader Pre-compilation

**Location**: `home/nixos/apps/gaming.nix`

**Purpose:** Use all CPU cores for significantly faster shader compilation on first game launch.

```
~/.steam/steam/steam_dev.cfg:
  unShaderBackgroundProcessingThreads 16
```

**Impact:** Reduces shader compilation time by up to 16x on a 16-core system.

### HTTP2 Disabled for Downloads

**Location**: `home/nixos/apps/gaming.nix`

**Purpose:** Some network configurations experience better download speeds with HTTP/1.1.

**Trade-off:** May reduce downloads speeds on some networks, but improves on others.

### Steam Input Security

**Location**: `modules/nixos/features/gaming.nix`

**Purpose:** Restrict uinput access to `steam` group instead of all logged-in users.

**Security:** Prevents sandbox escape via uinput device creation.

See `docs/STEAM_GAMING_GUIDE.md` for comprehensive gaming documentation.

## Module: Gaming Latency (gamingLatency)

Location: `modules/nixos/system/gaming-latency.nix`

Based on [Arch Wiki Gaming optimizations](https://wiki.archlinux.org/title/Gaming#Tweaking_kernel_parameters_for_response_time_consistency).

**Purpose:** Reduce jitter and stuttering in games by prioritizing consistent frame times over raw throughput.

### Memory Tuning (`enableMemoryTuning`)

**Key Settings:**

```nix
vm.compaction_proactiveness = 0        # Disable proactive compaction (causes jitter)
vm.watermark_boost_factor = 1          # Defragment only one pageblock at a time
vm.min_free_kbytes = 1048576          # Reserve 1GB to avoid allocation stalls
vm.watermark_scale_factor = 500        # 5% watermark distance
vm.swappiness = 10                     # Avoid swapping (overrides other settings)
vm.lru_gen.enabled = 5                 # Multi-Gen LRU with reduced locking
vm.zone_reclaim_mode = 0               # Disable zone reclaim (prevents latency spikes)
vm.page_lock_unfairness = 1            # Reduce page lock acquisition latency
```

**Transparent Hugepages:**
- Default: Disabled (`never`) for consistent latency
- Enable if using games with TCMalloc (Dota 2, CS:GO) which need THP for performance
- Mode: `madvise` = only when application requests

**Benefits:**
- Eliminates memory allocation stalls that cause stuttering
- Reduces lock contention during memory operations
- More consistent frame times

**Trade-offs:**
- Slightly lower peak throughput
- Reserves more memory (1-5% of RAM)

### Scheduler Tuning (`enableSchedulerTuning`)

**Key Settings:**

```nix
kernel.sched_child_runs_first = 0           # Parent (game) runs first
kernel.sched_autogroup_enabled = 1          # Better desktop responsiveness
kernel.sched_cfs_bandwidth_slice_us = 3000  # 3ms slices (vs 5ms default)
```

**debugfs Settings** (via systemd-tmpfiles):

```nix
/sys/kernel/debug/sched/base_slice_ns = 3000000        # 3ms minimum run time
/sys/kernel/debug/sched/migration_cost_ns = 500000     # 500μs migration cost
/sys/kernel/debug/sched/nr_migrate = 8                 # Migrate 8 tasks at once
```

**Benefits:**
- Lower scheduling latency (shorter time slices = faster preemption)
- Better cache locality (higher migration cost)
- Prioritizes main game thread over spawned processes

**Trade-offs:**
- More context switches = slightly higher overhead
- Better for latency, not maximum throughput

### Configuration Options

```nix
nixosConfig.gamingLatency = {
  enable = true;
  enableMemoryTuning = true;              # Reduce allocation stalls
  enableSchedulerTuning = true;            # Lower latency scheduling
  enableTransparentHugepages = false;      # Disable for consistent latency
  minFreeKilobytes = 1048576;             # 1GB (adjust for your RAM)
  watermarkScaleFactor = 500;             # 5% (adjust for your RAM)
};
```

**Recommended Settings by RAM:**
- **16GB:** minFreeKilobytes = 524288 (512MB), watermarkScaleFactor = 300 (3%)
- **32GB:** minFreeKilobytes = 786432 (768MB), watermarkScaleFactor = 400 (4%)
- **64GB:** minFreeKilobytes = 1048576 (1GB), watermarkScaleFactor = 500 (5%)
- **128GB+:** minFreeKilobytes = 1572864 (1.5GB), watermarkScaleFactor = 500 (5%)

## Module: PCI Latency (pciLatency)

Location: `modules/nixos/system/pci-latency.nix`

Based on [Arch Wiki Gaming](https://wiki.archlinux.org/title/Gaming#Improve_PCI_Express_Latencies) and CachyOS settings.

**Purpose:** Reduce maximum cycles a PCI-E device can occupy the bus, improving responsiveness.

**How It Works:**
- Sets PCI latency timer values at boot via systemd service
- Different priorities for different device types
- Runs after `systemd-udev-settle.service`

**Default Values:**

```nix
defaultLatency = 32         # Most PCI devices (in units of 8 PCI clocks)
hostBridgeLatency = 0       # Host bridge (bus 0, device 0)
audioLatency = 80           # Audio devices get higher priority
```

**Configuration:**

```nix
nixosConfig.pciLatency = {
  enable = true;
  defaultLatency = 32;       # Conservative default (CachyOS uses 20)
  hostBridgeLatency = 0;     # Host bridge doesn't need bus time
  audioLatency = 80;         # Prevent audio dropouts
};
```

**Benefits:**
- More frequent bus arbitration = lower latency for waiting devices
- Reduces bus contention between GPU, storage, network, etc.
- Helps prevent micro-stutters caused by bus saturation

**Trade-offs:**
- Minimal - PCI latency timer is largely legacy on modern systems
- May have no measurable impact on PCIe 3.0+ systems
- Audio priority helps prevent crackling during heavy I/O

**Note:** This conflicts with [Professional audio optimizations](https://wiki.archlinux.org/title/Professional_audio#Optimizing_system_configuration) which recommend higher latency for audio. Choose based on your use case.

## Module: Scheduler (scheduler)

Location: `modules/nixos/system/scheduler.nix`

**Purpose:** Enable alternative CPU schedulers via sched_ext framework for improved gaming performance.

### Available Schedulers

The `scx-scheds` package provides multiple BPF-based schedulers:

- **scx_cosmos** - Recommended for gaming + desktop
  - Optimizes task-to-CPU locality (better cache hits)
  - Reduces lock contention
  - Prioritizes interactive tasks under load
  - Best all-around for mixed workloads

- **scx_lavd** - Gaming-focused scheduler
  - Specifically optimized for consistent gaming performance
  - Lower latency focus
  - May sacrifice some background task throughput

- **Others:** scx_rustland, scx_bpfland, scx_rusty, etc.

### Configuration

```nix
nixosConfig.scheduler = {
  enableScxScheds = true;              # Install scx-scheds package
  defaultScheduler = "scx_cosmos";     # Auto-start this scheduler (optional)
};
```

**Manual Scheduler Control:**

```bash
# List available schedulers
ls /run/current-system/sw/bin/scx_*

# Start a scheduler manually
sudo scx_sched scx_cosmos

# Stop (Ctrl+C)

# Check status
systemctl status scx-scheduler  # If using defaultScheduler
```

### Performance Testing

Test different schedulers with your games:

1. Disable auto-start: `defaultScheduler = null;`
2. Manually test each: `sudo scx_sched scx_cosmos`, `sudo scx_sched scx_lavd`
3. Benchmark with consistent workloads
4. Monitor frame time consistency (1% and 0.1% lows)

**Recommended Approach:**
- Start with `scx_cosmos` for balanced gaming + desktop
- Try `scx_lavd` if you want maximum gaming focus
- Compare frame time graphs (use MangoHud logging)

### Requirements

- Linux kernel 6.12+ (sched_ext support)
- BPF support (enabled in XanMod kernel)
- Root privileges (handled by systemd service)

## Module: TSC Clocksource (boot.enableTscClocksource)

Location: `modules/nixos/core/boot.nix`

Based on [Arch Wiki Gaming](https://wiki.archlinux.org/title/Gaming#Improve_clock_gettime_throughput).

**Purpose:** Use Time Stamp Counter (TSC) for ~50x higher `clock_gettime()` throughput compared to HPET/ACPI_PM.

**Why It Matters:**
- Games call `clock_gettime()` extensively for physics calculations, FPS tracking, timing
- HPET/ACPI_PM require slow hardware reads
- TSC is a simple CPU register read

**Performance Impact:**
- Zen 3 benchmarks: ~50x higher throughput
- Reduces overhead of time queries from microseconds to nanoseconds

**Configuration:**

```nix
nixosConfig.boot.enableTscClocksource = true;
```

**Kernel Parameters Added:**
```
tsc=reliable clocksource=tsc
```

**Requirements:**
- Modern CPU with invariant TSC:
  - Intel: Core 2nd gen (Sandy Bridge) and newer
  - AMD: Zen+ and newer (Ryzen 2000+)
- Check support: `dmesg | grep "TSC"`

**Verification:**

```bash
# Check active clocksource
cat /sys/devices/system/clocksource/clocksource*/current_clocksource
# Should output: tsc

# Check available clocksources
cat /sys/devices/system/clocksource/clocksource*/available_clocksource
```

**WARNING:**
- **Only enable if your CPU has a reliable TSC**
- If enabled and Firefox crashes randomly, **disable immediately**
- Unreliable TSC breaks monotonicity of CLOCK_MONOTONIC, causing crashes

**When NOT to Use:**
- Very old CPUs (pre-2011 Intel, pre-2018 AMD)
- Virtual machines (unless explicitly passed through)
- Systems showing TSC instability warnings in dmesg

## WiFi Performance Optimization

### Regulatory Domain

**Location**: `hosts/jupiter/configuration.nix`

```nix
boot.kernelParams = [ "cfg80211.ieee80211_regdom=GB" ];
```

**Purpose:** Sets the correct WiFi regulatory domain for your country.

**Why It Matters:**
- Default `00` (global) uses most restrictive settings
- Correct domain enables:
  - Proper frequency ranges
  - Optimal transmit power
  - 6GHz band access (WiFi 6E)
  - Better signal strength

**Trade-off:** None - this is purely beneficial if set correctly for your location.

**How to Check:**

```bash
# Check current setting
cat /sys/module/cfg80211/parameters/ieee80211_regdom

# Check detailed regulatory info
iw reg get
```

Replace `GB` with your country code (e.g., `US`, `DE`, `FR`, `AU`, etc.).

## PCIe Resizable BAR

**What It Is:** Allows CPU to access the full GPU VRAM instead of only 256MB at a time.

**Performance Impact:** 10-20% FPS improvement in games, especially at 1440p/4K.

**How to Enable:**

1. **BIOS Settings:**
   - Enable "Above 4G Decode" or "Resizable BAR"
   - Disable CSM/Legacy Boot (required)
   - Enable UEFI boot mode

2. **Verify It's Working:**

```bash
# Check BAR size (should match VRAM size, not 256M)
sudo dmesg | grep "BAR="

# Example output:
# [drm] Detected VRAM RAM=8176M, BAR=8192M  ✓ ENABLED
# [drm] Detected VRAM RAM=8176M, BAR=256M   ✗ DISABLED
```

3. **Diagnostic Script:**

```bash
./scripts/diagnostics/check-gaming-setup.sh
```

**Requirements:**
- Modern GPU (AMD RX 5000+, NVIDIA RTX 3000+, Intel Arc)
- Modern CPU (Intel 10th gen+, AMD Ryzen 3000+)
- UEFI firmware with Resizable BAR support

**Note:** Some older motherboards may need a BIOS update to support this feature.

## Jupiter-Specific Optimizations

### ZFS ARC Limit

```nix
zfs.zfs_arc_max = 17179869184  # 16GB (out of 64GB total)
```

**Why limited:**
- Gaming workload needs RAM for game assets
- Prevents ZFS from competing with games
- 16GB is plenty for system/home datasets

### Intel C-State Tuning

```nix
processor.max_cstate = 1
intel_idle.max_cstate = 1
```

**Purpose:** Minimize CPU latency spikes during gaming

**Trade-off:**
- ✅ Lower latency, more consistent frame times
- ⚠️ Higher power consumption
- ⚠️ More heat

### XanMod Kernel

**Why XanMod:**
- Optimized for desktop/gaming
- Lower latency than mainline
- Better scheduling for interactive workloads
- Compatible with ZFS 2.3.5

## Additional Arch Wiki Recommendations

### Alternative CPU Schedulers

The default Linux EEVDF scheduler is good, but alternatives exist:

**BORE** (Burst-Oriented Response Enhancer):
- Sacrifices some fairness for lower latency
- Better for gaming and desktop
- Available: `linux-cachyos-bore`

**linux-zen**:
- General gaming/desktop optimization
- Good alternative to xanmod

**SCX** (Extensible Schedulers):
- Dynamic scheduler switching without reboot
- Experimental but interesting

**Recommendation:** Stick with `linux-xanmod` (current) unless you want to benchmark alternatives.

### Disk Power Management (HDDs Only)

For `/mnt/disk1` and `/mnt/disk2` (the HDDs), you can tune:

```bash
# Check current settings
sudo hdparm -B /dev/sda  # APM level
sudo hdparm -W /dev/sda  # Write cache status

# Example optimization (via udev rule)
# - Disable APM (keeps drives spinning)
# - Enable write cache (better performance)
```

Add to `modules/nixos/system/disk-performance.nix` if needed.

## Validation & Monitoring

### Check I/O Schedulers

```bash
# List all schedulers
grep "" /sys/block/*/queue/scheduler

# Check specific device
cat /sys/block/nvme0n1/queue/scheduler
```

### Monitor OOM Events

```bash
# Check systemd-oomd status
systemctl status systemd-oomd

# View OOM logs
journalctl -u systemd-oomd
```

### Network Performance

```bash
# Check TCP congestion control
sysctl net.ipv4.tcp_congestion_control

# Should show: bbr
```

### CPU Frequency

```bash
# Current frequencies
cat /proc/cpuinfo | grep MHz

# Governor in use
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

### Memory Pressure

```bash
# Check if OOM handling is working
cat /proc/pressure/memory

# Should show "some" and "full" percentages
```

### I/O Priority

```bash
# Check I/O priority of a process
ionice -p <PID>

# Check systemd service I/O priority
systemctl show fstrim.service | grep IOScheduling

# Should show:
# IOSchedulingClass=3  (idle)
# IOSchedulingPriority=7
```

### WiFi Regulatory Domain

```bash
# Check kernel parameter
cat /sys/module/cfg80211/parameters/ieee80211_regdom

# Should show your country code (e.g., GB), not 00
```

### PCIe Resizable BAR

```bash
# Quick check
sudo dmesg | grep "BAR="

# Full diagnostic
./scripts/diagnostics/check-gaming-setup.sh
```

## Benchmarking

Before claiming performance improvements, benchmark:

1. **Boot time:** `systemd-analyze`
2. **Disk I/O:** `hdparm -t /dev/sdX` or `fio`
3. **Network:** `iperf3`
4. **Gaming:** Frame time consistency (1% and 0.1% lows)
5. **Responsiveness:** Subjective but important

## Fine-Tuning Per System

These settings are optimized for Jupiter (64GB RAM, gaming workstation). Other systems may need adjustments:

**Low-RAM systems (< 16GB):**
```nix
enableZram = true
vm.swappiness = 60  # Default
vm.dirty_ratio = 20  # Lower
```

**Laptops:**
```nix
scalingGovernor = "schedutil"  # Balance power
enableNetworkTuning = false  # May impact WiFi
```

**Servers:**
```nix
enableOOMHandling = true  # Important
disableCoreDumps = false  # May need debugging
scalingGovernor = "schedutil"
```

## References

- [Arch Linux Performance Guide](https://wiki.archlinux.org/title/Improving_performance)
- [Kernel BFQ Documentation](https://docs.kernel.org/block/bfq-iosched.html)
- [systemd-oomd Documentation](https://www.freedesktop.org/software/systemd/man/systemd-oomd.html)
- [TCP BBR Congestion Control](https://queue.acm.org/detail.cfm?id=3022184)
- [XFS Documentation](https://xfs.wiki.kernel.org/)

## See Also

- [`ARCH_WIKI_PERFORMANCE_RESOURCES.md`](ARCH_WIKI_PERFORMANCE_RESOURCES.md) - Curated list of Arch Wiki performance articles with implementation suggestions
- [`STEAM_GAMING_GUIDE.md`](STEAM_GAMING_GUIDE.md) - Gaming-specific performance optimizations
