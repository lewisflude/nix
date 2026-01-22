# Boot Performance Optimization

This document covers boot performance analysis and optimization for this NixOS configuration.

## Current Boot Performance

Last analyzed: 2026-01-21

```
Startup finished in:
- Firmware:   32.200s  (UEFI/BIOS - check BIOS settings)
- Loader:       395ms  (systemd-boot - optimal)
- Kernel:       570ms  (optimal)
- Initrd:     6.704s   (can be improved)
- Userspace: 63.900s   (was slow due to ollama-models)
Total: 1min 43.772s
```

### Bottlenecks Identified

1. **ollama-models.service** - 1min 75ms
   - Pulls llama2 model at boot
   - **Fixed**: Added to `delayedServices`

2. **Device detection** - 7.184s
   - NVMe device enumeration
   - Normal for complex storage setups

3. **Firmware time** - 32.2s
   - UEFI/BIOS initialization
   - Can be reduced in BIOS settings (see recommendations)

## Implemented Optimizations

### 1. Service Delay (Boot Optimization Feature)

Non-essential services are delayed until after boot completes:

```nix
host.features.bootOptimization = {
  enable = true;
  delayedServices = [
    "ollama"
    "ollama-models"  # This was the main bottleneck!
    "open-webui"
  ];
  delaySeconds = 30;
};
```

**Expected Impact**: Reduces userspace boot time by ~60 seconds

### 2. Initramfs Optimization

```nix
boot.initrd = {
  systemd.enable = true;  # Parallel initialization
  compressor = "lz4";     # Faster decompression
  compressorArgs = [ "-l" ];  # Fast mode
};
```

**Trade-off**: Slightly larger initramfs (~10-20% larger) but faster decompression
**Expected Impact**: Reduces initrd time by 1-3 seconds

### 3. Silent Boot Configuration

Reduced logging overhead during boot:

```nix
boot.kernelParams = [
  "quiet"
  "loglevel=3"
  "rd.systemd.show_status=false"
  "rd.udev.log_level=3"
  "udev.log_priority=3"
];
```

**Expected Impact**: Minor reduction (100-500ms), improves visual experience

## Analysis Tools

### systemd-analyze Commands

```bash
# Overall boot time breakdown
systemd-analyze

# Show slowest services
systemd-analyze blame

# Show boot critical path
systemd-analyze critical-chain

# Generate SVG visualization
systemd-analyze plot > boot-plot.svg
```

### Identify Slow Services

```bash
# Show services taking > 1 second
systemd-analyze blame | awk '$1 ~ /s$/ && $1+0 > 1'

# Show services on critical path
systemd-analyze critical-chain graphical.target
```

## Additional Optimization Opportunities

### Firmware/BIOS Settings (32s firmware time)

Check these BIOS/UEFI settings to reduce firmware time:

1. **Fast Boot / Quick Boot**
   - Enable if available
   - Can reduce firmware time by 50-80%

2. **POST Delay**
   - Disable memory testing
   - Disable full memory check
   - Disable unnecessary hardware initialization

3. **Boot Device Order**
   - Remove unused boot devices
   - Set NVMe as first boot device

4. **CSM/Legacy Boot**
   - Disable Compatibility Support Module (CSM)
   - Use pure UEFI mode

5. **Network Stack**
   - Disable PXE boot if not needed
   - Disable IPv4/IPv6 network stack in UEFI

6. **USB Initialization**
   - Disable or reduce USB detection timeout

**Potential Impact**: Reduce firmware time from 32s to 5-10s

### Device Detection (7.184s NVMe detection)

This is mostly unavoidable with multiple NVMe drives but can check:

```bash
# Check if staggered spin-up is enabled (unlikely with SSDs)
sudo dmesg | grep -i "SSS\|staggered"
```

If present, add to kernel params:
```nix
boot.kernelParams = [ "libahci.ignore_sss=1" ];
```

### Filesystem Mount Optimization

For non-critical filesystems (like `/home` if separate):

```nix
fileSystems."/home" = {
  device = "/dev/disk/by-uuid/...";
  fsType = "ext4";
  options = [
    "noatime"           # Don't update access times
    "x-systemd.automount"  # Mount on first access
    "noauto"            # Don't mount at boot
  ];
};
```

**Impact**: Reduces boot time, mounts on-demand

### Service Socket Activation

For services that support it, use socket activation:

```nix
# Instead of starting service at boot
services.cups.enable = true;

# Use socket activation (starts on first print job)
services.cups.startSocket = true;  # If supported
```

## Expected Results After Optimization

With all optimizations applied:

```
Firmware:    10s     (from 32s - requires BIOS tuning)
Loader:      400ms   (unchanged)
Kernel:      570ms   (unchanged)
Initrd:      4s      (from 6.7s)
Userspace:   3-5s    (from 64s - delayed services)
───────────────────
Total:       ~18s   (from 1m 44s)
```

**Realistic improvement**: 1m 44s → ~20-25s boot time

## Monitoring Boot Performance

### After Rebuild

Test the changes:

```bash
# After applying changes, reboot and check
sudo reboot

# Then analyze
systemd-analyze
systemd-analyze blame | head -20
systemd-analyze critical-chain
```

### Track Over Time

Create baseline measurements:

```bash
# Save baseline
systemd-analyze > ~/boot-baseline-$(date +%Y%m%d).txt
systemd-analyze blame >> ~/boot-baseline-$(date +%Y%m%d).txt

# Compare after changes
systemd-analyze > ~/boot-optimized-$(date +%Y%m%d).txt
systemd-analyze blame >> ~/boot-optimized-$(date +%Y%m%d).txt
```

## Trade-offs and Considerations

### Service Delay

**Pros**:
- Much faster boot to usable system
- Critical services start immediately
- Non-essential services start in background

**Cons**:
- Services take 30s after boot to become available
- Need to identify which services can be safely delayed

### LZ4 vs ZSTD Compression

**LZ4**:
- Faster decompression (better for boot)
- Larger initramfs size
- Better for SSDs/NVMe

**ZSTD**:
- Better compression ratio
- Slower decompression
- Better for slow storage or network boot

### Systemd in Initrd

**Pros**:
- Parallel initialization
- Consistent with main system
- Better error handling

**Cons**:
- Slightly larger initramfs
- May not work with some exotic setups

## Related Documentation

- [Silent Boot](https://wiki.archlinux.org/title/Silent_boot) - Arch Wiki
- [Improving Performance/Boot Process](https://wiki.archlinux.org/title/Improving_performance/Boot_process) - Arch Wiki
- [systemd-analyze(1)](https://www.freedesktop.org/software/systemd/man/systemd-analyze.html)

## See Also

- `docs/PERFORMANCE_OPTIMIZATIONS.md` - System-wide performance tuning
- `modules/nixos/features/boot-optimization.nix` - Boot optimization implementation
- `modules/nixos/core/boot.nix` - Core boot configuration
