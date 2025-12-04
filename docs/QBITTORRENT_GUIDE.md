# qBittorrent VPN Setup & Management Guide

Complete guide for qBittorrent with ProtonVPN in a network namespace.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Optimization Configuration](#optimization-configuration)
- [Post-Deployment Validation](#post-deployment-validation)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)

---

## Architecture Overview

### System Design

```
┌─────────────────────────────────────────────────────┐
│ Host Network (192.168.10.0/24)                       │
│                                                      │
│  ┌───────────────────────────────────────────────┐  │
│  │ VPN Namespace: qbt                            │  │
│  │                                                │  │
│  │  ┌──────────────────────────────────────────┐ │  │
│  │  │ WireGuard (wg0): 10.2.0.2/32             │ │  │
│  │  │ Gateway: 10.2.0.1                        │ │  │
│  │  │ ProtonVPN Endpoint                       │ │  │
│  │  └──────────────────────────────────────────┘ │  │
│  │                                                │  │
│  │  ┌──────────────────────────────────────────┐ │  │
│  │  │ qBittorrent                              │ │  │
│  │  │ - Interface: qbt0                        │ │  │
│  │  │ - Port: Dynamic (via NAT-PMP)           │ │  │
│  │  │ - WebUI: 8080 (bridged to host)         │ │  │
│  │  └──────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────┘  │
│                                                      │
│  ┌───────────────────────────────────────────────┐  │
│  │ Systemd Timer: protonvpn-portforward.timer   │  │
│  │ - Runs every: 45 seconds                     │  │
│  │ - Auto-updates port forwarding               │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

### Configuration Overview

Your qBittorrent setup:

- **VPN Namespace**: `qbt`
- **VPN Interface**: `qbt0` (IP: `10.2.0.2`)
- **Torrent Port**: Dynamic (assigned via NAT-PMP port forwarding)
- **WebUI Port**: `8080` (accessible via reverse proxy)
- **VPN Provider**: ProtonVPN

---

## Optimization Configuration

### Storage Architecture

**Two-tier storage design:**

```
Downloads Flow:
┌─────────────┐
│ Torrent     │
│ File (50GB) │
└──────┬──────┘
       │
       ▼
┌──────────────────────────┐
│ SSD Staging (Fast I/O)   │ ← /mnt/nvme/qbittorrent/incomplete
│ - Download at 100+ MB/s  │
│ - Low latency writes     │
└──────┬───────────────────┘
       │
       ▼ (Radarr/Sonarr move)
┌──────────────────────────┐
│ HDD Final Storage (24TB) │ ← /mnt/storage/{movies,tv,etc}
│ - Sequential reads only  │
│ - Jellyfin streaming     │
└──────────────────────────┘
```

**Benefits:**

- Faster download speeds (SSD = 500+ MB/s vs HDD = 100-150 MB/s)
- Better Jellyfin reliability (no contention with downloads)
- Extended HDD lifespan (fewer random I/O patterns)
- Automatic category organization

### Performance Parameters

| Setting | Default | Optimized | Reasoning |
|---------|---------|-----------|-----------|
| Disk Cache | 128 MiB | 512 MiB | More RAM for write buffering to SSD |
| Max Active Torrents | 200 | 150 | Prevent HDD saturation with streaming |
| Max Active Uploads | ∞ (200) | 75 | Reduce seeding I/O during peak viewing |
| Max Uploads | 200 | 150 | Better upload slot allocation |
| Max Uploads/Torrent | 5 | 10 | Improved seed ratio without overhead |

### Configuration Files Modified

#### 1. Host Configuration (`hosts/jupiter/default.nix`)

```nix
host.services.mediaManagement.qbittorrent = {
  incompleteDownloadPath = "/mnt/nvme/qbittorrent/incomplete";
  diskCacheSize = 512;        # MiB
  maxActiveTorrents = 150;
  maxActiveUploads = 75;
  maxUploads = 150;
  maxUploadsPerTorrent = 10;
};
```

#### 2. Network Configuration

**VPN Confinement**: Remains unchanged

```
qBittorrent → WireGuard (qbt namespace) → ProtonVPN → Internet
```

**Port Forwarding**: Automated via NAT-PMP

```
ProtonVPN (3600s lease) → Refreshed every 45 minutes → Dynamic port
```

**Key Settings:**

- DHT: Enabled (peer discovery)
- PEX: Enabled (peer distribution)
- UPnP: Disabled (conflicts with VPN)
- uTP/TCP: Mixed mode (prevents starvation)

---

## Post-Deployment Validation

### Quick Verification

**One-liner to check everything:**

```bash
./scripts/test-vpn-port-forwarding.sh
```

**Manual quick checks:**

```bash
# 1. Check service status
systemctl status qbittorrent

# 2. Verify VPN IP
sudo ip netns exec qbt curl -s https://api.ipify.org

# 3. Check port forwarding
sudo systemctl status protonvpn-portforward.timer

# 4. Test WebUI
curl -s http://localhost:8080/api/v2/app/webapiVersion
```

### Phase 1: Service Verification (5 minutes)

#### Service Status Check

```bash
# All should show "active (running)"
systemctl status qbittorrent
systemctl status jellyfin
systemctl status radarr
systemctl status sonarr
```

✅ Checklist:

- [ ] qBittorrent: `active (running)`
- [ ] Jellyfin: `active (running)`
- [ ] Radarr: `active (running)`
- [ ] Sonarr: `active (running)`

#### Service Logs Check

```bash
# Check for startup errors
journalctl -u qbittorrent -n 50 --no-pager | grep -i "error\|warning\|critical" || echo "No errors found"
```

- [ ] No critical errors in logs
- [ ] No permission denied errors

### Phase 2: Storage Configuration (5 minutes)

#### Directory Structure

```bash
# Verify SSD staging directory
ls -ld /mnt/nvme/qbittorrent/incomplete

# Verify ownership
stat /mnt/nvme/qbittorrent/incomplete
```

- [ ] `/mnt/nvme/qbittorrent/incomplete` exists
- [ ] Owner is `qbittorrent:media`
- [ ] Permissions allow write (755 or 775)

#### Disk Space Check

```bash
# Check SSD space
df -h /mnt/nvme/qbittorrent/incomplete

# Check HDD space
df -h /mnt/storage
```

- [ ] SSD has at least 50GB free
- [ ] HDD has at least 200GB free

#### Category Directories

```bash
# Verify category directories
ls -ld /mnt/storage/{movies,tv,music,books,pc}
```

- [ ] All category directories exist

### Phase 3: VPN & Port Forwarding (5 minutes)

#### VPN Namespace Verification

```bash
# Verify namespace exists
sudo ip netns list | grep qbt

# Check VPN IP (should NOT be your ISP IP)
sudo ip netns exec qbt curl -s https://api.ipify.org
```

- [ ] qBittorrent running in `qbt` namespace
- [ ] IP address is ProtonVPN (not ISP)

#### Port Forwarding Verification

```bash
# Run comprehensive monitoring
./scripts/monitor-protonvpn-portforward.sh

# Or manual check
sudo ip netns exec qbt natpmpc -a 1 0 tcp 60 -g 10.2.0.1 | grep "Mapped public port"
```

- [ ] Port forwarding is active
- [ ] Timer is running: `systemctl status protonvpn-portforward.timer`

#### qBittorrent Configuration

```bash
# Verify port is listening
sudo ip netns exec qbt ss -tuln | grep qbittorrent
```

- [ ] qBittorrent listening on assigned port
- [ ] Interface binding is `qbt0`

### Phase 4: Integration Testing (10 minutes)

#### Radarr/Sonarr Configuration

**Radarr** (<http://192.168.10.210:7878>):

1. Go to **Settings → Download Clients**
2. Verify qBittorrent client configured
3. Test connection

**Sonarr** (<http://192.168.10.210:8989>):

1. Go to **Settings → Download Clients**
2. Verify qBittorrent client configured
3. Test connection

#### Download Test

```bash
# Add a test torrent (Linux ISO, etc.)
# Verify:
# 1. Downloads to /mnt/nvme/qbittorrent/incomplete
# 2. Moves to correct category path when complete
# 3. Shows in Jellyfin after processing
```

- [ ] Radarr → qBittorrent integration working
- [ ] Sonarr → qBittorrent integration working
- [ ] Files moving to correct final locations

### Phase 5: Performance Baseline (10 minutes)

#### Metrics Collection

```bash
# One-time report
./scripts/monitor-hdd-storage.sh

# Save baseline
./scripts/monitor-hdd-storage.sh > ~/qbittorrent-baseline-$(date +%Y%m%d).txt
```

**Record baselines:**

- [ ] SSD usage for staging
- [ ] HDD usage for final storage
- [ ] HDD I/O utilization (should be <40%)
- [ ] Service status (all running)

#### Expected Performance

| Metric | Expected Range | Notes |
|--------|---|---|
| Download Speed | 150-300 MB/s | Depends on swarm and ISP |
| Seeding Upload | 50-100 Mbps | Depends on ISP upload limit |
| HDD Utilization | 20-40% | During active seeding+streaming |
| Jellyfin Streaming | 0% buffering | 4K should play smoothly |

---

## Troubleshooting

### Common Issues

#### Issue: Jellyfin Stuttering During Seeding

**Symptoms:** 4K movies buffer while qBittorrent seeds

**Solutions:**

1. Reduce `maxActiveTorrents` to 100-120
2. Reduce `maxActiveUploads` to 50
3. Temporarily pause some torrents while streaming

#### Issue: Port Forwarding Not Working

**Symptoms:** No incoming peer connections

**Quick Verification:**

```bash
# Run verification script
./scripts/verify-qbittorrent-vpn.sh
```

**Common Causes:**

1. **VPN Namespace Issues**

   ```bash
   # Check namespace exists
   sudo ip netns list | grep qbt

   # Check gateway reachable
   sudo ip netns exec qbt ping -c 3 10.2.0.1
   ```

2. **NAT-PMP Fails**

   ```bash
   # Check service logs
   journalctl -u protonvpn-portforward.service -n 50

   # Verify ProtonVPN account has port forwarding enabled
   ```

3. **Timer Not Running**

   ```bash
   # Check timer status
   systemctl status protonvpn-portforward.timer

   # Start if needed
   sudo systemctl start protonvpn-portforward.timer
   ```

#### Issue: qBittorrent Not Seeding

**Diagnostic Steps:**

1. **Run Comprehensive Check**

   ```bash
   ./scripts/diagnose-qbittorrent-seeding.sh
   ```

2. **Check VPN Firewall**

   ```bash
   # Verify iptables allows connections
   sudo ip netns exec qbt iptables -L INPUT -n -v
   ```

3. **Verify qBittorrent Settings**
   - Max uploads > 0
   - Interface binding: `qbt0`
   - Port matches NAT-PMP assignment

#### Issue: SSD Filling Up

**Symptoms:** `/mnt/nvme/qbittorrent/incomplete` >80% full

**Solutions:**

1. Check Radarr/Sonarr completed download handling is enabled
2. List stalled downloads:

   ```bash
   ls -lh /mnt/nvme/qbittorrent/incomplete/
   ```

3. Manually move/remove stalled files
4. Reduce concurrent downloads

#### Issue: Download Speeds Below Expected

**Symptoms:** Only 50-100 MB/s on fast connection

**Solutions:**

1. Check connection limits in qBittorrent UI
2. Verify peer count (high = faster)
3. Test ISP throttling:

   ```bash
   ./scripts/test-sped.sh
   ```

4. Ensure VPN doesn't have bandwidth limits

### Diagnostic Scripts

```bash
# Comprehensive seeding diagnostic
./scripts/diagnose-qbittorrent-seeding.sh

# Test qBittorrent connectivity
./scripts/test-qbittorrent-connectivity.sh

# Full health check
./scripts/test-qbittorrent-seeding-health.sh

# Monitor VPN and port forwarding
./scripts/monitor-protonvpn-portforward.sh

# Complete verification following setup guide
./scripts/verify-qbittorrent-vpn.sh
```

### VPN Namespace Troubleshooting

**Namespace doesn't exist:**

```bash
# Check service
systemctl status qbt.service

# Restart if needed
sudo systemctl restart qbt.service
```

**Can't reach gateway:**

```bash
# Check WireGuard status
sudo ip netns exec qbt wg show

# Verify SOPS secrets
ls -la /run/secrets/ | grep vpn
```

---

## Maintenance

### Daily Monitoring

```bash
# Quick status check
./scripts/monitor-hdd-storage.sh

# Continuous monitoring during peak hours
./scripts/monitor-hdd-storage.sh --continuous --interval 10
```

### Weekly Checks

```bash
# Full diagnostics
./scripts/verify-qbittorrent-vpn.sh

# HDD health
sudo smartctl -H /dev/sd[abc]
```

### Monthly Tasks

1. **Archive Old Media**

   ```bash
   # Check space usage
   du -sh /mnt/storage/* | sort -hr

   # Consider archiving content >6 months old
   ```

2. **Cleanup Old Torrents**
   - Remove completed torrents from qBittorrent UI
   - Frees space for new downloads

3. **Review Performance**
   - Check if adjustments needed based on usage patterns
   - Review seeding ratios

### Monitoring Commands

```bash
# Service status
systemctl status qbittorrent jellyfin radarr sonarr

# Port forwarding status
systemctl list-timers | grep protonvpn

# Recent service logs
journalctl -u protonvpn-portforward.service --since "24 hours ago"

# Disk usage
df -h /mnt/nvme/qbittorrent/incomplete /mnt/storage
```

---

## Advanced Configuration

### Tuning for High Seed Counts (10+ concurrent)

```nix
# In hosts/jupiter/default.nix
host.services.mediaManagement.qbittorrent = {
  maxActiveTorrents = 200;
  maxActiveUploads = 100;
  maxUploads = 200;
};
```

### Tuning for Older/Slower HDDs

```nix
# Reduce limits to match HDD speed
host.services.mediaManagement.qbittorrent = {
  maxActiveTorrents = 100;
  maxActiveUploads = 50;
  maxUploads = 100;
};
```

### Tuning for Large SSD (500GB+)

```nix
# Increase cache
host.services.mediaManagement.qbittorrent = {
  diskCacheSize = 1024;  # 1GB
};
```

---

## Rollback Plan

If issues occur after configuration changes:

### Rollback NixOS Configuration

```bash
# Revert to previous generation
sudo nixos-rebuild switch --rollback

# Or specific generation
nix-env --list-generations
sudo nixos-rebuild switch --profile /nix/var/nix/profiles/system --switch-generation N
```

### Restore qBittorrent Config Only

```bash
# Stop service
sudo systemctl stop qbittorrent

# Restore backup (if created)
cp -r ~/.backup/qbittorrent-backup-YYYYMMDD/* /var/lib/qBittorrent/

# Restart
sudo systemctl start qbittorrent
```

---

## References

- **ProtonVPN Port Forwarding**: `docs/PROTONVPN_PORT_FORWARDING_SETUP.md`
- **Monitoring Script**: `scripts/monitor-hdd-storage.sh`
- **VPN Namespace Config**: `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix`
- **qBittorrent Service**: `modules/nixos/services/media-management/qbittorrent.nix`

---

## Success Criteria

✅ **System is working correctly when:**

1. ✅ NAT-PMP query returns a valid port
2. ✅ qBittorrent config matches the port
3. ✅ qBittorrent is listening on assigned port
4. ✅ External port checker confirms port is open
5. ✅ Torrents show incoming peer connections
6. ✅ Traffic only goes through VPN (no leaks)
7. ✅ Port forwarding persists across restarts
8. ✅ NAT-PMP lease renews automatically
9. ✅ Jellyfin streams without buffering
10. ✅ Monitoring scripts report 0 issues

---

**Document Version**: 1.0
**Last Updated**: 2025-11-13
**Maintainer**: System Administrator
