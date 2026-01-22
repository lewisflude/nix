# Arch Wiki Performance Resources

Recommended Arch Wiki articles for further performance optimization of this NixOS configuration.

**Generated**: 2025-01-21  
**System**: Jupiter (64GB RAM, 16-core, ZFS + XFS, Gaming, Niri compositor)

## 🎯 High Priority - Directly Applicable

### 1. [Improving performance](https://wiki.archlinux.org/title/Improving_performance) ⭐

**Main performance guide covering everything**

**Relevant sections**:
- Storage devices (SSD/NVMe optimization)
- Watchdogs (disable for better performance)
- Systemd optimization
- tmpfs for /tmp (RAM disk)
- Compiling with optimizations

**Already implemented**: VM tuning, I/O schedulers, CPU governor  
**Still missing**: tmpfs, watchdog disable, makepkg optimizations

---

### 2. [Solid state drive](https://wiki.archlinux.org/title/Solid_state_drive) ⭐⭐

**SSD/NVMe optimization**

**Topics**:
- TRIM support and automation
- NVMe-specific optimizations
- Filesystem choices (you use ZFS + XFS)
- I/O schedulers (you already have this!)
- Discard options

**Action**: Check if TRIM is enabled for SSDs

---

### 3. [Improving performance/Boot process](https://wiki.archlinux.org/title/Improving_performance/Boot_process) ⭐

**Faster boot times**

**Topics**:
- Analyzing boot with systemd-analyze
- Disabling unnecessary services
- initramfs optimization
- Parallel service startup

**Current status**: Quiet boot enabled, but boot time not optimized

---

### 4. [PipeWire](https://wiki.archlinux.org/title/PipeWire) ⭐

**Audio performance tuning**

**Topics**:
- Quantum and buffer sizes
- Real-time scheduling (you have musnix!)
- Reducing audio latency
- Bluetooth audio quality

**Your setup**: Comprehensive real-time audio already configured  
**Check for**: Browser audio latency, Discord/gaming audio tweaks

---

### 5. [Chromium](https://wiki.archlinux.org/title/Chromium)

**Browser performance (applies to Google Chrome)**

**Topics**:
- Hardware acceleration (Wayland + Chrome)
- GPU process configuration
- Memory management flags
- V8 optimization flags

**Missing**: Chrome launch flags for better performance

---

## 🔧 Medium Priority - Some Applicability

### 6. [systemd](https://wiki.archlinux.org/title/Systemd) - Optimization section

**systemd tweaks**

**Topics**:
- DefaultTimeoutStartSec (faster boot)
- Masking unused services
- Journal size limits

---

### 7. [Zram](https://wiki.archlinux.org/title/Zram)

**Compressed RAM swap**

**Your status**: Documented but disabled (correct for 64GB RAM system)

---

### 8. [Benchmarking](https://wiki.archlinux.org/title/Benchmarking)

**Measuring improvements**

**Tools**:
- fio (disk)
- sysbench (CPU)
- iperf3 (network)
- MangoHud (gaming - you have this)
- Frame timing analysis

**Missing**: Systematic benchmarking before/after changes

---

### 9. [tmpfs](https://wiki.archlinux.org/title/Tmpfs)

**RAM disks for speed**

**Use cases**:
- `/tmp` in RAM (boot.tmp.useTmpfs)
- Browser cache in RAM
- Compilation directories in RAM

**Impact**: Faster compilation, less SSD wear  
**Trade-off**: Uses RAM, data lost on reboot

---

### 10. [Profile-sync-daemon](https://wiki.archlinux.org/title/Profile-sync-daemon)

**Browser profiles in RAM**

**Topics**:
- Chrome/Firefox profiles in tmpfs
- Periodic sync to disk
- Faster browser startup

**Trade-off**: More RAM usage, potential data loss on crashes

---

## 📊 Lower Priority - Niche/Advanced

### 11. [Wayland](https://wiki.archlinux.org/title/Wayland) - Performance section

**Compositor performance**

**Topics**:
- VSync configuration
- Tearing prevention
- Multi-monitor optimization

**Note**: Niri-specific optimizations might differ from general Wayland advice

---

### 12. [Silent boot](https://wiki.archlinux.org/title/Silent_boot)

**Status**: ✅ Already implemented (quiet boot params in boot.nix)

---

### 13. [CPU frequency scaling](https://wiki.archlinux.org/title/CPU_frequency_scaling)

**Status**: ✅ Already covered (performance governor for gaming)

---

### 14. [Power management](https://wiki.archlinux.org/title/Power_management)

**Desktop optimization**

**Topics**:
- Idle power consumption
- C-states (already tweaked for gaming!)
- PCIe ASPM

---

## 🚀 Quick Wins Ready to Implement

### 1. Disable Watchdogs (~1-2% CPU savings)

```nix
# Add to modules/nixos/system/cpu-performance.nix or disk-performance.nix
boot.kernelParams = [
  "nowatchdog"           # Disable hardware watchdog
  "nmi_watchdog=0"       # Disable NMI watchdog
];

boot.blacklistedKernelModules = [
  "iTCO_wdt"             # Intel TCO watchdog
  "iTCO_vendor_support"
];
```

**Reference**: [Improving performance - Watchdogs](https://wiki.archlinux.org/title/Improving_performance#Watchdogs)

---

### 2. Enable /tmp in RAM (faster, less SSD wear)

```nix
# Add to modules/nixos/core/boot.nix or memory.nix
boot.tmp = {
  useTmpfs = true;       # Use RAM for /tmp
  tmpfsSize = "50%";     # Use up to 50% RAM (32GB on Jupiter)
  cleanOnBoot = true;
};
```

**Reference**: [tmpfs](https://wiki.archlinux.org/title/Tmpfs)

**Impact**: 
- Faster temporary file operations
- Reduced SSD wear
- Automatic cleanup on reboot

**Trade-off**: 
- Uses up to 32GB RAM
- Data lost on reboot (expected for /tmp)

---

### 3. Chrome Performance Flags

```nix
# Add to home/nixos/browser.nix
programs.chromium = {
  enable = true;
  package = pkgs.google-chrome;
  commandLineArgs = [
    # GPU acceleration (Wayland)
    "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
    "--enable-wayland-ime"
    "--ozone-platform-hint=auto"
    
    # Performance
    "--disable-features=UseChromeOSDirectVideoDecoder"
    "--enable-zero-copy"
    "--enable-gpu-rasterization"
    
    # Smooth scrolling
    "--enable-smooth-scrolling"
    
    # Reduce memory usage
    "--process-per-site"
    "--memory-pressure-thresholds=1,2"
  ];
};
```

**Reference**: [Chromium - Hardware video acceleration](https://wiki.archlinux.org/title/Chromium#Hardware_video_acceleration)

---

### 4. TRIM for SSDs (if not already enabled)

```nix
# Add to modules/nixos/system/disk-performance.nix
services.fstrim = {
  enable = true;
  interval = "weekly";  # Run TRIM weekly
};
```

**Reference**: [Solid state drive - TRIM](https://wiki.archlinux.org/title/Solid_state_drive#TRIM)

**Check current status**:
```bash
systemctl status fstrim.timer
```

---

### 5. Systemd Optimization

```nix
# Create modules/nixos/core/systemd.nix
systemd = {
  # Faster service startup timeout
  extraConfig = ''
    DefaultTimeoutStartSec=10s
    DefaultTimeoutStopSec=10s
  '';
  
  # Journal size limits (prevent unbounded growth)
  services.systemd-journald.serviceConfig = {
    SystemMaxUse = "1G";        # Max 1GB on disk
    SystemMaxFileSize = "100M"; # Max 100MB per file
    MaxRetentionSec = "1month"; # Keep logs for 1 month
  };
};
```

**Reference**: [systemd - Journal size limit](https://wiki.archlinux.org/title/Systemd/Journal#Journal_size_limit)

---

## 📈 Create a Benchmarking Suite

Based on [Benchmarking article](https://wiki.archlinux.org/title/Benchmarking), create comprehensive suite:

```bash
# scripts/diagnostics/benchmark-system.sh

# Boot time analysis
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain

# Disk I/O (ZFS pools)
fio --name=randread --ioengine=libaio --iodepth=16 --rw=randread \
    --bs=4k --direct=1 --size=1G --numjobs=4 --runtime=60 \
    --group_reporting --filename=/mnt/disk1/test

# CPU benchmark
sysbench cpu --threads=16 run

# Memory benchmark  
sysbench memory --memory-block-size=1M --memory-total-size=10G run

# Network
iperf3 -c server_ip

# Gaming frame times
# Use MangoHud logs and analyze 1% and 0.1% lows
```

**Tools to install**:
- fio (disk benchmarking)
- sysbench (CPU/memory)
- iperf3 (network)
- stress-ng (stress testing)

---

## 🎯 Recommended Reading Order

1. **[Improving performance](https://wiki.archlinux.org/title/Improving_performance)** - Start here for overview
2. **[Solid state drive](https://wiki.archlinux.org/title/Solid_state_drive)** - Storage optimization
3. **[Improving performance/Boot process](https://wiki.archlinux.org/title/Improving_performance/Boot_process)** - Faster startup
4. **[Chromium](https://wiki.archlinux.org/title/Chromium)** - Browser optimization
5. **[tmpfs](https://wiki.archlinux.org/title/Tmpfs)** - RAM disk benefits
6. **[Benchmarking](https://wiki.archlinux.org/title/Benchmarking)** - Measure everything

---

## 📊 Performance Maturity Assessment

| Area | Status | Arch Wiki Article | Priority | Notes |
|------|--------|-------------------|----------|-------|
| **Gaming** | ✅ Excellent | Steam, Gaming | - | Comprehensive setup |
| **VM/Memory** | ✅ Excellent | Improving performance | - | Optimized sysctl |
| **I/O Scheduling** | ✅ Excellent | Improving performance | - | BFQ for HDD/SSD, none for NVMe |
| **CPU Governor** | ✅ Excellent | CPU frequency scaling | - | Performance mode |
| **Network** | ✅ Good | Improving performance | - | TCP BBR enabled |
| **Real-time Audio** | ✅ Excellent | PipeWire, musnix | - | Pro audio setup |
| **SSD TRIM** | ❓ Unknown | Solid state drive | **High** | Need to verify |
| **Watchdogs** | ❌ Not disabled | Improving performance | **High** | Free 1-2% CPU |
| **tmpfs /tmp** | ❌ Not configured | tmpfs | **Medium** | Faster, less wear |
| **Browser flags** | ❌ Not optimized | Chromium | **Medium** | Hardware accel |
| **Boot time** | ❓ Not measured | Boot process | **Medium** | Unknown baseline |
| **Systemd** | ⚠️ Default | systemd | **Low** | Could tune timeouts |
| **Benchmarking** | ❌ No suite | Benchmarking | **Low** | Need baseline |

---

## 💡 Implementation Strategy

### Phase 1 - Low Risk, High Impact (Do First)
1. ✅ Check TRIM status (`systemctl status fstrim.timer`)
2. ✅ Enable TRIM if not active
3. ✅ Disable watchdogs (free performance)
4. ✅ Add Chrome performance flags

### Phase 2 - Medium Risk, Good Impact
1. Enable tmpfs for /tmp (test with 25% first)
2. Optimize systemd timeouts
3. Measure boot time and optimize services

### Phase 3 - Low Priority, Nice to Have
1. Create benchmarking suite
2. Profile-sync-daemon for browser
3. Advanced Wayland/Niri tuning

---

## 🔗 Additional Resources

### Related Arch Wiki Pages
- [Gaming](https://wiki.archlinux.org/title/Gaming)
- [Steam](https://wiki.archlinux.org/title/Steam) (already covered in STEAM_GAMING_GUIDE.md)
- [ZFS](https://wiki.archlinux.org/title/ZFS)
- [Xanmod](https://wiki.archlinux.org/title/Kernel#Xanmod) (you're using this!)
- [Wayland](https://wiki.archlinux.org/title/Wayland)

### NixOS-Specific
- [NixOS Manual - Kernel](https://nixos.org/manual/nixos/stable/#sec-kernel-config)
- [NixOS Manual - Boot](https://nixos.org/manual/nixos/stable/#sec-boot)
- [NixOS Manual - Performance](https://nixos.wiki/wiki/Performance)

### Benchmarking Tools
- [Phoronix Test Suite](https://www.phoronix-test-suite.com/) - Comprehensive benchmarking
- [UnixBench](https://github.com/kdlucas/byte-unixbench) - Classic Unix benchmarks
- [stress-ng](https://github.com/ColinIanKing/stress-ng) - Stress testing

---

## 📝 Notes

### What Makes This Config Special

This NixOS configuration already exceeds typical Arch Linux setups in several areas:

- **Declarative**: Everything reproducible via Nix
- **Gaming**: Comprehensive optimizations (ananicy-cpp, gamemode, Steam Input)
- **Real-time Audio**: musnix with RT kernel support
- **Network**: TCP BBR, optimized buffers
- **Storage**: ZFS + XFS with BFQ scheduling
- **Documentation**: Extensive guides (you're reading one!)

### Performance Philosophy

1. **Measure First**: Always benchmark before optimizing
2. **Incremental Changes**: One change at a time
3. **Document Everything**: Why you made each change
4. **Validate Impact**: Benchmark after each change
5. **Security Trade-offs**: Understand what you're disabling

### Warning: Don't Cargo Cult

Not all "performance tips" apply to your system:
- ❌ Skip laptop power-saving tips (you're desktop)
- ❌ Skip low-memory optimizations (you have 64GB)
- ❌ Skip old-CPU workarounds (modern 16-core)
- ✅ Focus on: I/O, latency, gaming, audio

---

## 🎬 Next Steps

1. **Read** [Improving performance](https://wiki.archlinux.org/title/Improving_performance) article
2. **Check** current TRIM status
3. **Measure** current boot time: `systemd-analyze`
4. **Decide** which quick wins to implement
5. **Test** one change at a time
6. **Document** results in this config

---

**Last Updated**: 2025-01-21  
**Maintainer**: This file tracks performance improvement opportunities  
**See Also**: `docs/PERFORMANCE_OPTIMIZATIONS.md`, `docs/STEAM_GAMING_GUIDE.md`
