# Performance Remediation Plan

**Date Created**: 2025-11-26
**System**: Intel i9-13900K / 64GB RAM / RTX 4090
**Based on**: Benchmark results from `scripts/diagnostics/run_benchmarks.sh`

---

## Executive Summary

This document outlines a comprehensive plan to resolve all critical performance issues identified in the system benchmarks. Issues are categorized by severity and organized into phases for systematic resolution.

**Critical Issues Identified**:

1. CPU throttled by powersave governor (-200% performance)
2. Network running at 40% capacity (1Gb vs 2.5Gb)
3. Extreme TCP retransmissions (41k SYN retransmits)
4. Cache miss rate at 46% (should be <10%)
5. Memory pressure with 10GB swap usage
6. Abnormal kernel slab usage (12.3GB)
7. NVMe tail latencies up to 2 seconds

**Expected Performance Gains**:

- CPU-bound workloads: +100-300%
- Network throughput: +150%
- I/O latency: +20-50%
- Memory responsiveness: +30-40%

---

## Phase 1: Investigation & Baseline (1-2 hours)

### Objective

Gather detailed diagnostics to understand root causes before making changes.

### 1.1 CPU & Cache Investigation

**Check current CPU configuration:**

```bash
# Current governor settings
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | sort | uniq -c

# Frequency ranges
cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_min_freq
cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq

# CPU topology (P vs E cores)
lscpu --extended

# Check for thermal throttling
dmesg | grep -i "thermal\|throttle"
```

**Cache analysis:**

```bash
# L1/L2/L3 cache info
lscpu | grep -i cache

# Detailed cache topology
lstopo --of console

# Run cache-specific benchmark
perf stat -e cache-misses,cache-references,L1-dcache-load-misses,L1-icache-load-misses,LLC-load-misses stress-ng --cpu 4 --timeout 10s
```

**Expected findings**:

- All CPUs on powersave
- High LLC (Last Level Cache) misses
- Possible memory bandwidth saturation

---

### 1.2 Network Investigation

**Current network configuration:**

```bash
# Link status
ethtool eno2

# Driver info
ethtool -i eno2

# Ring buffer sizes
ethtool -g eno2

# Offload features
ethtool -k eno2

# Check for errors
ethtool -S eno2 | grep -i error

# Interface statistics
ip -s link show eno2

# Check switch capabilities (if managed switch)
sudo lldpcli show neighbors
```

**Test auto-negotiation:**

```bash
# Force different speeds to test
sudo ethtool -s eno2 speed 2500 duplex full autoneg off
sleep 5
ethtool eno2

# Reset to auto
sudo ethtool -s eno2 autoneg on
```

**TCP connection analysis:**

```bash
# Current connections by state
ss -s

# Check for specific errors
netstat -s | grep -i "retrans\|timeout\|failed"

# Active connection details
ss -ti | head -50
```

**Expected findings**:

- Link negotiated at 1000Mb instead of 2500Mb
- Possible duplex mismatch
- Switch might not support 2.5GBASE-T
- Cable quality issues (Cat5e instead of Cat6)

---

### 1.3 Memory Investigation

**Slab memory analysis:**

```bash
# Top slab consumers
sudo slabtop -o -s c | head -30

# Detailed slab info
sudo cat /proc/slabinfo | head -50

# Check for memory leaks
sudo slabtop -d 5 -o -s c
# Watch for continuously growing slabs
```

**Memory pressure indicators:**

```bash
# Current swap usage by process
sudo smem -s swap -r | head -20

# Memory fragmentation
cat /proc/buddyinfo

# Transparent hugepages status
cat /sys/kernel/mm/transparent_hugepage/enabled
cat /sys/kernel/mm/transparent_hugepage/defrag

# Check for OOM kills
dmesg | grep -i "out of memory\|oom"

# Memory cgroup pressure
cat /proc/pressure/memory
```

**Process memory analysis:**

```bash
# Top memory consumers
ps aux --sort=-%mem | head -20

# Check for memory leaks in long-running processes
sudo pmap -x $(pgrep -f "firefox|chrome|qbittorrent") | tail -1
```

**Expected findings**:

- High dentry/inode cache (common with many files)
- Possible ZFS ARC if using ZFS
- qBittorrent or other torrent client consuming excessive memory
- Firefox/browser with many tabs

---

### 1.4 Disk I/O Investigation

**NVMe health check:**

```bash
# SMART data
sudo smartctl -a /dev/nvme0n1
sudo smartctl -a /dev/nvme1n1
sudo smartctl -a /dev/nvme2n1

# NVMe specific info
sudo nvme smart-log /dev/nvme0n1
sudo nvme smart-log /dev/nvme1n1
sudo nvme smart-log /dev/nvme2n1

# Check for thermal throttling
sudo nvme smart-log /dev/nvme0n1 | grep -i "temperature\|throttle"

# Firmware version
sudo nvme id-ctrl /dev/nvme0n1 | grep -i firmware
```

**Filesystem analysis:**

```bash
# Check filesystem types
df -T

# Disk space usage (full disks = slow writes)
df -h

# Inode usage
df -i

# Check for filesystem errors
dmesg | grep -i "ext4\|xfs\|btrfs\|error"

# Mount options
mount | grep -E "nvme|sda|sdb|sdc"
```

**I/O scheduler check:**

```bash
# Current schedulers
for disk in nvme0n1 nvme1n1 nvme2n1 sda sdb sdc; do
  echo -n "$disk: "
  cat /sys/block/$disk/queue/scheduler 2>/dev/null || echo "N/A"
done

# Queue depth
for disk in nvme0n1 nvme1n1 nvme2n1; do
  echo -n "$disk: "
  cat /sys/block/$disk/queue/nr_requests
done
```

**Expected findings**:

- NVMe drives >80% full (causes write amplification)
- Thermal throttling (>70°C)
- Outdated firmware
- Suboptimal mount options (noatime missing)

---

### 1.5 Establish Baseline Metrics

**Create baseline test script:**

```bash
cat > /tmp/baseline_test.sh << 'EOF'
#!/usr/bin/env bash
echo "=== CPU Performance ==="
sysbench cpu --cpu-max-prime=20000 --threads=8 run | grep "events per second"

echo -e "\n=== Memory Bandwidth ==="
sysbench memory --memory-total-size=10G --threads=4 run | grep "MiB/sec"

echo -e "\n=== Disk Sequential Read ==="
fio --name=seq-read --rw=read --bs=1m --size=1G --numjobs=1 --runtime=10 --group_reporting --filename=/tmp/fio_test --direct=1 | grep -E "READ:|bw="

echo -e "\n=== Network Throughput (local) ==="
iperf3 -c 127.0.0.1 -t 5 2>/dev/null || echo "Start iperf3 server first: iperf3 -s"

echo -e "\n=== TCP Statistics ==="
ss -s

rm -f /tmp/fio_test
EOF

chmod +x /tmp/baseline_test.sh
nix-shell -p sysbench fio iperf3 --run "/tmp/baseline_test.sh"
```

**Save baseline:**

```bash
/tmp/baseline_test.sh > ~/baseline_before.txt 2>&1
```

---

## Phase 2: Quick Wins (Immediate fixes, <30 minutes)

### Objective

Apply immediate performance improvements with minimal risk.

### 2.1 Fix CPU Governor (CRITICAL - Priority 1)

**Temporary fix (immediate):**

```bash
# Apply immediately
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Verify
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | uniq
```

**Permanent NixOS fix:**

Create or update: `modules/nixos/performance/cpu-governor.nix`

```nix
{ config, lib, pkgs, ... }:

{
  # Set CPU governor to performance for maximum performance
  powerManagement.cpuFreqGovernor = "performance";

  # Alternative: Use ondemand with aggressive scaling
  # powerManagement.cpuFreqGovernor = "ondemand";

  # For hybrid CPUs (P+E cores), ensure all cores are managed
  boot.kernelParams = [
    # Disable CPU frequency scaling if issues persist
    # "intel_pstate=disable"
  ];

  # Disable CPU idle states for absolute minimum latency (optional, increases power)
  # boot.kernelParams = [ "intel_idle.max_cstate=1" ];

  # Install CPU frequency utilities
  environment.systemPackages = with pkgs; [
    cpufrequtils
    cpupower
  ];
}
```

**Validate:**

```bash
# Should show "performance" for all CPUs
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | uniq

# Run quick benchmark
sysbench cpu --cpu-max-prime=20000 --threads=8 run
# Should be 2-3x faster than baseline
```

**Expected gain**: +100-300% CPU performance

---

### 2.2 Reduce Swappiness (Priority 2)

**Temporary fix:**

```bash
sudo sysctl vm.swappiness=1
```

**Permanent fix in NixOS config:**

Add to `modules/nixos/performance/memory.nix`:

```nix
{ config, lib, pkgs, ... }:

{
  boot.kernel.sysctl = {
    # Reduce swap usage (default 60, reduce to 1)
    "vm.swappiness" = 1;

    # Increase cache pressure (default 100)
    "vm.vfs_cache_pressure" = 50;

    # Dirty page writeback tuning
    "vm.dirty_ratio" = 15;  # Reduced from 40
    "vm.dirty_background_ratio" = 5;  # Start background writeback earlier

    # Laptop mode (for better I/O scheduling)
    "vm.laptop_mode" = 0;  # Disable for desktop
  };
}
```

**Validate:**

```bash
sysctl vm.swappiness
# Should show: vm.swappiness = 1

# Monitor swap usage
watch -n 1 'free -h'
```

**Expected gain**: Reduced swap thrashing, +20-30% I/O responsiveness

---

### 2.3 Fix Network Link Speed (Priority 3)

**Temporary fix:**

```bash
# Try forcing 2.5G
sudo ethtool -s eno2 speed 2500 duplex full autoneg on
sleep 2
ethtool eno2 | grep Speed

# If that fails, try without autoneg
sudo ethtool -s eno2 speed 2500 duplex full autoneg off
```

**If 2.5G doesn't work, verify:**

1. Cable is Cat6 or better
2. Switch supports 2.5GBASE-T
3. Driver is up to date

**Permanent NixOS fix:**

Create: `modules/nixos/networking/ethernet-optimization.nix`

```nix
{ config, lib, pkgs, ... }:

{
  # Network interface optimization
  systemd.network.networks."10-eno2" = {
    matchConfig.Name = "eno2";

    networkConfig = {
      DHCP = "yes";
      # Or static IP if you use one
    };

    linkConfig = {
      # Force 2.5G if auto-negotiation fails
      # BitsPerSecond = "2.5G";
      # Duplex = "full";

      # Increase queue length
      TransmitQueues = 4;
      ReceiveQueues = 4;
    };
  };

  # Ethernet driver and performance tuning
  boot.extraModprobeConfig = ''
    # Intel ethernet driver options (adjust for your NIC)
    # For Intel I225/I226 2.5GbE
    options igc InterruptThrottleRate=3000,3000,3000,3000
  '';

  # Network performance tuning via udev
  services.udev.extraRules = ''
    # Optimize eno2 ring buffers and offloading
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="eno2", RUN+="${pkgs.ethtool}/bin/ethtool -G eno2 rx 4096 tx 4096 || true"
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="eno2", RUN+="${pkgs.ethtool}/bin/ethtool -K eno2 tso on gso on gro on || true"

    # Force link speed (uncomment if auto-negotiation fails)
    # ACTION=="add", SUBSYSTEM=="net", KERNEL=="eno2", RUN+="${pkgs.ethtool}/bin/ethtool -s eno2 speed 2500 duplex full autoneg on || true"
  '';

  # Install network tools
  environment.systemPackages = with pkgs; [
    ethtool
    iperf3
    mtr
  ];
}
```

**Validate:**

```bash
ethtool eno2 | grep -E "Speed|Duplex"
# Should show: Speed: 2500Mb/s

# Test throughput (requires iperf3 server on another machine)
iperf3 -c <server-ip> -t 30
```

**Expected gain**: +150% network throughput (1Gb → 2.5Gb)

---

### 2.4 Disable Transparent Huge Pages (if causing issues)

**Check current status:**

```bash
cat /sys/kernel/mm/transparent_hugepage/enabled
cat /sys/kernel/mm/transparent_hugepage/defrag
```

**If set to `[always]`, may cause latency spikes. Change to `madvise`:**

```bash
echo madvise | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo madvise | sudo tee /sys/kernel/mm/transparent_hugepage/defrag
```

**NixOS config (add to memory.nix):**

```nix
{
  # Transparent huge pages tuning
  boot.kernel.sysctl = {
    "vm.nr_hugepages" = 0;  # Disable pre-allocation
  };

  # Set THP to madvise (applications must request it)
  systemd.tmpfiles.rules = [
    "w /sys/kernel/mm/transparent_hugepage/enabled - - - - madvise"
    "w /sys/kernel/mm/transparent_hugepage/defrag - - - - madvise"
  ];
}
```

---

## Phase 3: Network Optimization (30-60 minutes)

### Objective

Resolve TCP retransmissions and optimize network stack.

### 3.1 TCP Stack Tuning

Create: `modules/nixos/networking/tcp-optimization.nix`

```nix
{ config, lib, pkgs, ... }:

{
  boot.kernel.sysctl = {
    # TCP buffer sizes (min, default, max in bytes)
    "net.ipv4.tcp_rmem" = "4096 87380 33554432";  # 32MB max
    "net.ipv4.tcp_wmem" = "4096 65536 33554432";  # 32MB max

    # Core network buffer sizes
    "net.core.rmem_max" = 33554432;  # 32MB
    "net.core.wmem_max" = 33554432;  # 32MB
    "net.core.rmem_default" = 262144;  # 256KB
    "net.core.wmem_default" = 262144;  # 256KB

    # Netdev budget (packets per poll)
    "net.core.netdev_budget" = 50000;
    "net.core.netdev_budget_usecs" = 5000;

    # TCP congestion control
    "net.ipv4.tcp_congestion_control" = "bbr";  # Google BBR

    # TCP fast open
    "net.ipv4.tcp_fastopen" = 3;  # Enable for both directions

    # Reduce TIME_WAIT sockets
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.ipv4.tcp_fin_timeout" = 30;

    # SYN cookies (helps with SYN floods)
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_syn_retries" = 3;  # Reduce from 6
    "net.ipv4.tcp_synack_retries" = 3;  # Reduce from 5

    # TCP keepalive tuning
    "net.ipv4.tcp_keepalive_time" = 600;  # 10 minutes
    "net.ipv4.tcp_keepalive_intvl" = 30;
    "net.ipv4.tcp_keepalive_probes" = 3;

    # TCP retransmission tuning
    "net.ipv4.tcp_retries2" = 8;  # Reduce from 15

    # Maximum number of SYN backlog
    "net.ipv4.tcp_max_syn_backlog" = 8192;
    "net.core.somaxconn" = 4096;

    # Enable TCP window scaling
    "net.ipv4.tcp_window_scaling" = 1;

    # Enable TCP timestamps
    "net.ipv4.tcp_timestamps" = 1;

    # Enable selective acknowledgment
    "net.ipv4.tcp_sack" = 1;

    # Disable TCP slow start after idle
    "net.ipv4.tcp_slow_start_after_idle" = 0;

    # MTU probing
    "net.ipv4.tcp_mtu_probing" = 1;

    # Connection tracking
    "net.netfilter.nf_conntrack_max" = 262144;

    # IPv6
    "net.ipv6.conf.all.forwarding" = 0;
    "net.ipv6.conf.default.forwarding" = 0;
  };

  # Load BBR module
  boot.kernelModules = [ "tcp_bbr" ];

  # Ensure required kernel parameters
  boot.kernelParams = [
    # Enable BBR
    "net.core.default_qdisc=fq"
  ];
}
```

**Validate:**

```bash
# Check BBR is active
sysctl net.ipv4.tcp_congestion_control
# Should show: net.ipv4.tcp_congestion_control = bbr

sysctl net.core.default_qdisc
# Should show: net.core.default_qdisc = fq

# Test connection quality
mtr -r -c 100 8.8.8.8 | tail -20
```

---

### 3.2 FQ Queue Discipline Tuning

The benchmark showed 1.4M throttled packets on queue :1. Tune FQ parameters:

Create: `modules/nixos/networking/qdisc-tuning.nix`

```nix
{ config, lib, pkgs, ... }:

{
  # Optimize FQ qdisc parameters
  systemd.services.fq-tuning = {
    description = "Tune FQ qdisc for eno2";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      # Wait for interface
      sleep 2

      # Apply FQ tuning to each queue
      ${pkgs.iproute2}/bin/tc qdisc replace dev eno2 root mq

      # Increase FQ limits (reduce throttling)
      for i in {1..4}; do
        ${pkgs.iproute2}/bin/tc qdisc replace dev eno2 parent :$i fq \
          limit 20000 \
          flow_limit 200 \
          buckets 2048 \
          quantum 3028 \
          initial_quantum 15140 \
          maxrate 2.5gbit || true
      done

      ${pkgs.iproute2}/bin/tc -s qdisc show dev eno2
    '';
  };

  environment.systemPackages = with pkgs; [
    iproute2
  ];
}
```

---

### 3.3 Hardware Offloading

**Check current offloads:**

```bash
ethtool -k eno2
```

**Enable recommended offloads:**

```bash
sudo ethtool -K eno2 tso on
sudo ethtool -K eno2 gso on
sudo ethtool -K eno2 gro on
sudo ethtool -K eno2 lro on  # If supported
sudo ethtool -K eno2 tx-nocache-copy on
```

**Add to udev rules in ethernet-optimization.nix** (already included above).

---

## Phase 4: Memory Optimization (1-2 hours)

### Objective

Resolve memory pressure and reduce slab usage.

### 4.1 Identify Slab Memory Consumers

**Run detailed analysis:**

```bash
sudo slabtop -o -s c > ~/slab_analysis.txt

# Check for common culprits
sudo cat /proc/slabinfo | grep -E "dentry|inode|buffer_head|ext4" | sort -k3 -n -r
```

**Common causes:**

- **dentry/inode cache**: Many files (torrent clients, file servers)
- **buffer_head**: Filesystem metadata
- **kmalloc**: Generic kernel allocations
- **nf_conntrack**: Connection tracking (firewall/NAT)

---

### 4.2 Reduce Dentry/Inode Cache Pressure

Create: `modules/nixos/performance/memory.nix` (extended)

```nix
{ config, lib, pkgs, ... }:

{
  boot.kernel.sysctl = {
    # Memory management
    "vm.swappiness" = 1;
    "vm.vfs_cache_pressure" = 150;  # Increase to reclaim dentry/inode cache more aggressively

    # Dirty page writeback
    "vm.dirty_ratio" = 15;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_writeback_centisecs" = 500;  # 5 seconds
    "vm.dirty_expire_centisecs" = 3000;  # 30 seconds

    # Memory compaction
    "vm.compaction_proactiveness" = 20;
    "vm.watermark_scale_factor" = 200;

    # OOM killer tuning
    "vm.oom_kill_allocating_task" = 0;
    "vm.overcommit_memory" = 1;  # Allow overcommit
    "vm.overcommit_ratio" = 80;

    # Huge pages (if using databases/VMs)
    # "vm.nr_hugepages" = 1024;  # 2GB of 2MB pages
  };

  # Transparent huge pages
  systemd.tmpfiles.rules = [
    "w /sys/kernel/mm/transparent_hugepage/enabled - - - - madvise"
    "w /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise"
    "w /sys/kernel/mm/transparent_hugepage/khugepaged/defrag - - - - 0"
  ];

  # Periodic cache dropping (aggressive - use with caution)
  systemd.services.drop-caches = {
    description = "Drop page cache, dentries and inodes periodically";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/sh -c 'echo 2 > /proc/sys/vm/drop_caches'";
    };
  };

  # Run every 6 hours (only if slab usage is problematic)
  # systemd.timers.drop-caches = {
  #   wantedBy = [ "timers.target" ];
  #   timerConfig = {
  #     OnBootSec = "1h";
  #     OnUnitActiveSec = "6h";
  #   };
  # };
}
```

---

### 4.3 Optimize Application Memory Usage

**qBittorrent memory limits** (if applicable):

If qBittorrent is consuming excessive memory, tune it:

```nix
# In your qBittorrent configuration module
{
  # Limit memory cache
  programs.qbittorrent.settings = {
    "Preferences/DiskWriteCacheSize" = 32;  # MB (default can be very high)
    "BitTorrent/Session/AnnounceToAllTrackers" = false;
    "BitTorrent/Session/AnnounceToAllTiers" = false;
  };
}
```

**Browser memory limits:**

Add to your home-manager config:

```nix
{
  programs.firefox = {
    policies = {
      # Memory reduction
      preferences = {
        "browser.cache.memory.capacity" = 51200;  # 50MB
        "browser.cache.memory.enable" = true;
        "browser.sessionhistory.max_total_viewers" = 2;  # Reduce bfcache
      };
    };
  };
}
```

---

### 4.4 Increase Physical Memory (if needed)

**If memory pressure persists after optimizations:**

Current: 64GB RAM
Recommendation: Consider adding another 64GB kit (128GB total) if:

- You regularly run VMs
- Heavy development workloads
- Running multiple browsers with hundreds of tabs
- Database workloads

**Check memory slot availability:**

```bash
sudo dmidecode -t memory | grep -E "Number Of Devices|Size|Speed|Type:"
```

---

## Phase 5: Disk I/O Optimization (1-2 hours)

### Objective

Reduce NVMe tail latencies and improve overall I/O performance.

### 5.1 NVMe Power Management

**Check current NVMe power state:**

```bash
sudo nvme get-feature -f 0x0c -H /dev/nvme0n1  # Power management
sudo nvme get-feature -f 0x02 -H /dev/nvme0n1  # Temperature threshold
```

**Disable APST (Autonomous Power State Transition) if causing latency:**

Create: `modules/nixos/hardware/nvme-optimization.nix`

```nix
{ config, lib, pkgs, ... }:

{
  # NVMe power management tuning
  boot.extraModprobeConfig = ''
    # Disable APST for consistent latency (increases power usage slightly)
    options nvme_core default_ps_max_latency_us=0
  '';

  # Kernel parameters for NVMe
  boot.kernelParams = [
    # Disable I/O scheduler for NVMe (use none/noop)
    "nvme_core.default_ps_max_latency_us=0"
  ];

  # I/O scheduler optimization
  services.udev.extraRules = ''
    # Set 'none' scheduler for NVMe devices
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"

    # Increase queue depth for NVMe
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/nr_requests}="2048"

    # Enable write cache (if not already)
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/write_cache}="write back"
  '';

  # Install NVMe tools
  environment.systemPackages = with pkgs; [
    nvme-cli
    smartmontools
  ];
}
```

---

### 5.2 Filesystem Mount Options

**Check current mount options:**

```bash
mount | grep -E "nvme|sda"
```

**Optimize mount options:**

Update your filesystem configuration (likely in `hosts/<hostname>/filesystems.nix`):

```nix
{ config, lib, ... }:

{
  fileSystems."/" = {
    device = "/dev/nvme0n1p1";  # Adjust to your setup
    fsType = "ext4";
    options = [
      "noatime"          # Don't update access times (big performance win)
      "nodiratime"       # Don't update directory access times
      "discard=async"    # Async TRIM for SSDs
      "commit=60"        # Increase commit interval (default 5 seconds)
      "barrier=0"        # Disable barriers if using UPS (risky otherwise)
    ];
  };

  # If using XFS
  # options = [
  #   "noatime"
  #   "nodiratime"
  #   "logbufs=8"
  #   "logbsize=256k"
  #   "largeio"
  #   "inode64"
  #   "swalloc"
  # ];

  # If using Btrfs
  # options = [
  #   "noatime"
  #   "compress=zstd:1"  # Compression
  #   "space_cache=v2"
  #   "ssd"
  #   "discard=async"
  # ];
}
```

**Apply immediately (for testing):**

```bash
sudo mount -o remount,noatime,nodiratime /
```

---

### 5.3 Readahead Tuning

**Check current readahead:**

```bash
blockdev --getra /dev/nvme0n1
# Default is usually 256 (128KB)
```

**Increase for better sequential performance:**

Add to `nvme-optimization.nix`:

```nix
{
  services.udev.extraRules = ''
    # Increase readahead for NVMe (4MB)
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{bdi/read_ahead_kb}="4096"

    # Moderate readahead for SATA SSD (1MB)
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{bdi/read_ahead_kb}="1024"

    # Lower readahead for HDDs (default is fine)
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{bdi/read_ahead_kb}="512"
  '';
}
```

---

### 5.4 Check for Thermal Throttling

**Monitor NVMe temperatures:**

```bash
# Real-time monitoring
watch -n 1 'sudo nvme smart-log /dev/nvme0n1 | grep -i temperature'

# Or use sensors
watch -n 1 'sensors | grep -i nvme'
```

**If temperatures > 70°C consistently:**

- Add heatsink to NVMe drives
- Improve case airflow
- Reduce ambient temperature

**Set thermal threshold:**

```bash
# Set warning at 70°C, critical at 80°C
sudo nvme set-feature -f 0x04 -v 0x014D /dev/nvme0n1  # 70°C warning
```

---

### 5.5 Filesystem Trim/Discard

**Check TRIM support:**

```bash
lsblk --discard
# Non-zero values in DISC-GRAN and DISC-MAX mean TRIM is supported
```

**Enable periodic TRIM:**

```nix
{
  # Enable fstrim.timer for periodic TRIM
  services.fstrim = {
    enable = true;
    interval = "weekly";  # or "daily"
  };
}
```

**Or use continuous discard** (already in mount options above with `discard=async`).

---

### 5.6 I/O Nice Levels for Background Tasks

**Reduce I/O priority of heavy I/O processes:**

```bash
# For qBittorrent (if running)
sudo ionice -c 3 -p $(pgrep qbittorrent)  # Idle class
sudo renice +10 $(pgrep qbittorrent)  # Lower CPU priority

# For other background tasks
sudo ionice -c 2 -n 7 -p <PID>  # Best-effort, lowest priority
```

**Make permanent via systemd service overrides** (if managing via systemd).

---

## Phase 6: Advanced CPU Optimizations (2-3 hours)

### Objective

Reduce cache misses and optimize for hybrid architecture.

### 6.1 CPU Affinity for Critical Applications

**Pin performance-critical apps to P-cores:**

```bash
# Check core topology
lscpu --extended=CPU,CORE,SOCKET,NODE,CACHE

# Identify P-cores vs E-cores
# P-cores typically have larger cache
```

For i9-13900K:

- Cores 0-23: P-cores (with hyperthreading) = 8 physical P-cores
- Cores 24-31: E-cores = 16 E-cores

**Pin application to P-cores:**

```bash
# Example: Pin to P-cores (0-15)
taskset -c 0-15 <command>

# Or for running process
taskset -cp 0-15 <PID>
```

**NixOS systemd service pinning:**

```nix
{
  systemd.services.my-performance-app = {
    serviceConfig = {
      CPUAffinity = "0-15";  # P-cores only
      CPUSchedulingPolicy = "fifo";
      CPUSchedulingPriority = 50;
    };
  };
}
```

---

### 6.2 Disable Simultaneous Multithreading (Testing)

**Test if SMT/Hyperthreading is causing cache contention:**

```bash
# Disable SMT temporarily
echo off | sudo tee /sys/devices/system/cpu/smt/control

# Run benchmarks
sysbench cpu --cpu-max-prime=20000 --threads=8 run

# Re-enable
echo on | sudo tee /sys/devices/system/cpu/smt/control
```

**If performance improves, disable permanently:**

```nix
{
  # Disable SMT/Hyperthreading
  boot.kernelParams = [ "nosmt" ];
}
```

**Note**: This reduces thread count from 32 to 24, but may improve cache efficiency.

---

### 6.3 Kernel Scheduler Tuning

Create: `modules/nixos/performance/scheduler.nix`

```nix
{ config, lib, pkgs, ... }:

{
  boot.kernel.sysctl = {
    # CPU scheduler tuning
    "kernel.sched_migration_cost_ns" = 5000000;  # 5ms (reduce migrations)
    "kernel.sched_min_granularity_ns" = 10000000;  # 10ms
    "kernel.sched_wakeup_granularity_ns" = 15000000;  # 15ms

    # Disable automatic NUMA balancing (you have single node)
    "kernel.numa_balancing" = 0;

    # Reduce context switch overhead
    "kernel.sched_nr_migrate" = 32;

    # Scheduler autogroup (helps desktop responsiveness)
    "kernel.sched_autogroup_enabled" = 0;  # Disable for servers/performance
  };

  # Use performance-oriented kernel if needed
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs.linuxPackages_xanmod;  # Performance kernel

  # Or real-time kernel for minimal latency
  # boot.kernelPackages = pkgs.linuxPackages_rt_latest;
}
```

---

### 6.4 Memory Access Optimization

**Profile memory access patterns:**

```bash
perf c2c record -a -- sleep 30
perf c2c report
```

**Check NUMA distances (even on single node):**

```bash
numactl --hardware
```

**Optimize memory allocation:**

```nix
{
  boot.kernel.sysctl = {
    # Memory locality
    "vm.zone_reclaim_mode" = 0;  # Already optimal

    # Disable automatic NUMA balancing
    "kernel.numa_balancing" = 0;
  };
}
```

---

## Phase 7: Create Unified NixOS Module (30 minutes)

### Objective

Consolidate all optimizations into reusable modules.

### 7.1 Create Performance Profile

Create: `modules/nixos/profiles/performance.nix`

```nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ../performance/cpu-governor.nix
    ../performance/memory.nix
    ../performance/scheduler.nix
    ../networking/tcp-optimization.nix
    ../networking/ethernet-optimization.nix
    ../networking/qdisc-tuning.nix
    ../hardware/nvme-optimization.nix
  ];

  # Performance monitoring tools
  environment.systemPackages = with pkgs; [
    # CPU
    cpufrequtils
    cpupower

    # Memory
    numactl

    # Disk
    nvme-cli
    smartmontools
    fio

    # Network
    ethtool
    iperf3
    mtr

    # Monitoring
    htop
    btop
    iotop
    nethogs
    sysstat

    # Benchmarking
    sysbench
    stress-ng
  ];

  # Enable performance monitoring
  services.sysstat.enable = true;

  # Disable unnecessary services
  services.power-profiles-daemon.enable = false;
  services.thermald.enable = lib.mkDefault false;  # Can conflict with performance mode
}
```

---

### 7.2 Enable Performance Profile

In your `hosts/<hostname>/configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  imports = [
    ../../modules/nixos/profiles/performance.nix
  ];

  # Override specific settings if needed
  # powerManagement.cpuFreqGovernor = lib.mkForce "ondemand";
}
```

---

### 7.3 Rebuild System

```bash
# Build first (don't activate)
sudo nixos-rebuild build --flake .#<hostname>

# Check what will change
nvd diff /run/current-system ./result

# If satisfied, activate
sudo nixos-rebuild switch --flake .#<hostname>

# Reboot to ensure all changes are applied
sudo reboot
```

---

## Phase 8: Validation & Monitoring (1-2 hours)

### Objective

Verify all optimizations are working and establish monitoring.

### 8.1 Re-run Benchmarks

```bash
# Run the same benchmark script
nix-shell -p iperf3 ethtool mtr fio sysstat smartmontools hdparm stress-ng numactl perf pciutils --run "./scripts/diagnostics/run_benchmarks.sh"

# Save new results
cp performance_results.txt performance_results_after.txt

# Run baseline test
/tmp/baseline_test.sh > ~/baseline_after.txt 2>&1

# Compare
diff -u ~/baseline_before.txt ~/baseline_after.txt
```

---

### 8.2 Specific Validation Tests

**CPU Performance:**

```bash
# Should be 2-3x faster
sysbench cpu --cpu-max-prime=20000 --threads=8 run

# Check governor
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | uniq
# Expected: performance

# Check frequencies
watch -n1 'grep MHz /proc/cpuinfo | sort -u'
# Should be at max turbo frequency
```

**Network:**

```bash
# Link speed
ethtool eno2 | grep Speed
# Expected: 2500Mb/s

# TCP congestion control
sysctl net.ipv4.tcp_congestion_control
# Expected: bbr

# Test throughput (needs server)
iperf3 -c <server> -t 30 -P 4
```

**Memory:**

```bash
# Swappiness
sysctl vm.swappiness
# Expected: 1

# Swap usage (monitor over time)
watch -n 5 'free -h'
# Should decrease

# Slab usage
sudo slabtop -o -s c | head -20
# Compare with previous
```

**Disk:**

```bash
# I/O scheduler
cat /sys/block/nvme0n1/queue/scheduler
# Expected: [none]

# Mount options
mount | grep nvme | grep noatime
# Should see noatime

# TRIM enabled
systemctl status fstrim.timer

# FIO benchmark (should have lower tail latencies)
fio --name=random-write --ioengine=libaio --iodepth=32 --rw=randwrite --bs=4k --direct=1 --size=1G --numjobs=4 --runtime=60 --group_reporting --filename=/tmp/fio_test
```

---

### 8.3 Setup Continuous Monitoring

Create: `modules/nixos/monitoring/performance-monitoring.nix`

```nix
{ config, lib, pkgs, ... }:

{
  # System activity reporter
  services.sysstat.enable = true;

  # Periodic performance reports
  systemd.services.perf-report = {
    description = "Generate periodic performance report";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "perf-report" ''
        REPORT_FILE=/var/log/perf-report-$(date +%Y%m%d-%H%M%S).txt

        echo "=== Performance Report $(date) ===" > $REPORT_FILE
        echo "" >> $REPORT_FILE

        echo "--- CPU Governor ---" >> $REPORT_FILE
        cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | uniq >> $REPORT_FILE
        echo "" >> $REPORT_FILE

        echo "--- Memory Usage ---" >> $REPORT_FILE
        free -h >> $REPORT_FILE
        echo "" >> $REPORT_FILE

        echo "--- Top Slab Consumers ---" >> $REPORT_FILE
        ${pkgs.procps}/bin/slabtop -o -s c --once | head -20 >> $REPORT_FILE
        echo "" >> $REPORT_FILE

        echo "--- Network Link ---" >> $REPORT_FILE
        ${pkgs.ethtool}/bin/ethtool eno2 | grep -E "Speed|Duplex" >> $REPORT_FILE
        echo "" >> $REPORT_FILE

        echo "--- TCP Statistics ---" >> $REPORT_FILE
        ss -s >> $REPORT_FILE
        echo "" >> $REPORT_FILE

        echo "--- Disk I/O ---" >> $REPORT_FILE
        ${pkgs.sysstat}/bin/iostat -x 1 5 >> $REPORT_FILE

        # Keep only last 7 days of reports
        find /var/log -name "perf-report-*.txt" -mtime +7 -delete
      '';
    };
  };

  systemd.timers.perf-report = {
    description = "Periodic performance report timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # Alert on high swap usage
  systemd.services.swap-alert = {
    description = "Alert on high swap usage";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "swap-alert" ''
        SWAP_USED=$(${pkgs.procps}/bin/free | ${pkgs.gawk}/bin/awk '/Swap:/ {print $3}')
        SWAP_TOTAL=$(${pkgs.procps}/bin/free | ${pkgs.gawk}/bin/awk '/Swap:/ {print $2}')

        if [ $SWAP_TOTAL -gt 0 ]; then
          SWAP_PCT=$((100 * SWAP_USED / SWAP_TOTAL))

          if [ $SWAP_PCT -gt 25 ]; then
            echo "WARNING: Swap usage at $SWAP_PCT%" | ${pkgs.systemd}/bin/systemd-cat -t swap-alert -p warning
          fi
        fi
      '';
    };
  };

  systemd.timers.swap-alert = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "15m";
    };
  };
}
```

---

### 8.4 Expected Performance Improvements

Based on fixes applied, expected gains:

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| **CPU Performance** | Throttled | 3.5-5.5 GHz | +200-300% |
| **Network Speed** | 1 Gb/s | 2.5 Gb/s | +150% |
| **TCP Retransmits** | 55k | <5k | -90% |
| **Swap Usage** | 10 GB | <1 GB | -90% |
| **Disk Write P99** | 295 ms | <50 ms | -80% |
| **Cache Miss Rate** | 46% | <10% | -78% |
| **Overall Responsiveness** | Sluggish | Snappy | +50-100% |

---

## Phase 9: Long-term Maintenance

### 9.1 Weekly Checks

```bash
# Check for thermal issues
sensors | grep -E "Core|Package|nvme"

# Monitor swap usage
free -h

# Check for TCP errors
nstat | grep -i "retrans\|timeout"

# Disk health
sudo smartctl -H /dev/nvme0n1
```

---

### 9.2 Monthly Tasks

```bash
# Review performance reports
ls -lh /var/log/perf-report-*.txt

# Check slab growth
sudo slabtop -o -s c

# Update firmware
# - Check motherboard BIOS
# - Check NVMe firmware: sudo nvme id-ctrl /dev/nvme0n1 | grep FR
# - Update if available

# Run full benchmark
./scripts/diagnostics/run_benchmarks.sh
```

---

### 9.3 Quarterly Reviews

- Review and update kernel version
- Check for NixOS-unstable improvements
- Re-evaluate hardware (any failing components?)
- Consider upgrades (more RAM, faster network switch, etc.)

---

## Rollback Plan

If any optimization causes issues:

### Quick Rollback (Individual Changes)

```bash
# CPU governor
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Network
sudo ethtool -s eno2 autoneg on

# Swappiness
sudo sysctl vm.swappiness=60

# Mount options
sudo mount -o remount,defaults /
```

### Full Rollback (NixOS)

```bash
# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or specific generation
sudo /nix/var/nix/profiles/system-<N>-link/bin/switch-to-configuration switch
```

---

## Summary Checklist

### Critical (Do First)

- [ ] Fix CPU governor to performance
- [ ] Reduce swappiness to 1
- [ ] Force network to 2.5G (if supported)
- [ ] Enable TCP BBR congestion control
- [ ] Add noatime to filesystem mounts

### Important (Do Soon)

- [ ] Tune FQ qdisc parameters
- [ ] Optimize TCP buffer sizes
- [ ] Disable NVMe APST
- [ ] Enable fstrim service
- [ ] Increase vfs_cache_pressure

### Nice to Have

- [ ] CPU affinity for critical apps
- [ ] Kernel scheduler tuning
- [ ] Performance monitoring service
- [ ] Regular health checks

### Validate

- [ ] Re-run benchmarks
- [ ] Compare before/after metrics
- [ ] Monitor for 48 hours
- [ ] Document actual improvements

---

## Additional Resources

- [NixOS Manual - Performance](https://nixos.org/manual/nixos/stable/#sec-performance)
- [Red Hat Performance Tuning Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/monitoring_and_managing_system_status_and_performance/index)
- [Arch Wiki - Improving Performance](https://wiki.archlinux.org/title/Improving_performance)
- [Linux Performance](http://www.brendangregg.com/linuxperf.html) by Brendan Gregg
- [NVMe Performance Guide](https://wiki.archlinux.org/title/Solid_state_drive/NVMe)

---

## End of Remediation Plan

Generated: 2025-11-26
Next Review: After Phase 8 completion
