# qBittorrent Optimization - Post-Rebuild Validation Checklist

## Pre-Rebuild Checklist

Before running `nh os switch`, complete these steps:

### Preparation

- [ ] Read `/home/lewis/.config/nix/docs/QBITTORRENT_OPTIMIZATION.md`
- [ ] Backup current qBittorrent configuration (optional but recommended)

  ```bash
  cp -r /var/lib/qbittorrent ~/.backup/qbittorrent-backup-$(date +%Y%m%d) 2>/dev/null || true
  ```

- [ ] Note any active torrents (you may want to pause them)
- [ ] Ensure `/mnt/nvme/qbittorrent/incomplete` directory will be created
- [ ] Check available disk space (need at least 50GB free on SSD)

### Directory Creation (Must Run Before Rebuild)

```bash
# These commands MUST run BEFORE the NixOS rebuild
sudo mkdir -p /mnt/nvme/qbittorrent/incomplete
sudo chown qbittorrent:media /mnt/nvme/qbittorrent/incomplete
sudo chmod 0775 /mnt/nvme/qbittorrent/incomplete

# Verify it was created
ls -ld /mnt/nvme/qbittorrent/incomplete
```

---

## Phase 1: NixOS Rebuild

### Build & Deploy

```bash
cd /home/lewis/.config/nix

# Optional: Check for configuration errors
nix flake check

# Run the rebuild (this is YOUR command to run, not automated)
nh os switch

# Rebuild should complete without errors
# Expected time: 5-15 minutes depending on changes
```

### Post-Rebuild Verification

- [ ] System rebooted successfully (if `nh` asked)
- [ ] No kernel panics in dmesg

  ```bash
  dmesg | tail -20
  ```

- [ ] No boot-time errors in systemd

  ```bash
  journalctl -b | grep -i error | head -10
  ```

---

## Phase 2: Service Verification (5 minutes)

### Service Status Check

```bash
# All these should show "active (running)"
systemctl status qbittorrent
systemctl status jellyfin
systemctl status radarr
systemctl status sonarr
```

- [ ] qBittorrent: `active (running)` ✓
- [ ] Jellyfin: `active (running)` ✓
- [ ] Radarr: `active (running)` ✓
- [ ] Sonarr: `active (running)` ✓

### Service Logs Check

```bash
# Check for startup errors
journalctl -u qbittorrent -n 50 --no-pager | grep -i "error\|warning\|critical" || echo "No errors found"
journalctl -u jellyfin -n 50 --no-pager | grep -i "error\|warning" || echo "No errors found"
```

- [ ] No critical errors in qBittorrent logs
- [ ] No critical errors in Jellyfin logs
- [ ] No permission denied errors

---

## Phase 3: Storage Configuration Verification (5 minutes)

### Directory Structure

```bash
# Verify SSD staging directory
ls -ld /mnt/nvme/qbittorrent/incomplete
stat /mnt/nvme/qbittorrent/incomplete

# Verify ownership
find /mnt/nvme/qbittorrent -type d -exec ls -ld {} \;
```

- [ ] `/mnt/nvme/qbittorrent/incomplete` exists and is readable
- [ ] Owner is `qbittorrent:media` or accessible by qBittorrent
- [ ] Permissions allow write access (755 or 775)

### Disk Space Check

```bash
# Check SSD space for staging
df -h /mnt/nvme/qbittorrent/incomplete

# Check HDD space for final storage
df -h /mnt/storage

# Expected: Both should have plenty of free space
```

- [ ] SSD has at least 50GB free
- [ ] HDD has at least 200GB free (for new downloads)
- [ ] Storage health shown in `monitor-hdd-storage.sh` output

### Category Directories

```bash
# Verify category directories exist on HDD
ls -ld /mnt/storage/{movies,tv,music,books,pc}
```

- [ ] `/mnt/storage/movies` exists
- [ ] `/mnt/storage/tv` exists
- [ ] `/mnt/storage/music` exists
- [ ] `/mnt/storage/books` exists
- [ ] `/mnt/storage/pc` exists

---

## Phase 4: qBittorrent Configuration Verification (10 minutes)

### Web UI Access

```bash
# Test qBittorrent WebUI connectivity
curl -s http://localhost:8080/api/v2/app/webapiVersion
# Should return a version number, e.g., "v2.8.17"
```

- [ ] WebUI accessible at `http://192.168.1.210:8080`
- [ ] Login with username: `lewis`
- [ ] Can view main qBittorrent dashboard

### Configuration Verification

**Via Web UI (<http://192.168.1.210:8080>):**

1. **Settings → Bittorrent**
   - [ ] Max active torrents: Should be around **150** (check exact value)
   - [ ] Max active uploads: Should be around **75**
   - [ ] Max connections: Should be **2000**
   - [ ] Max connections per torrent: Should be **200**

   ```bash
   # Or check via API
   curl -s http://localhost:8080/api/v2/app/preferences | jq '.max_active_torrents, .max_active_uploads'
   ```

2. **Settings → Speed**
   - [ ] Max uploads: Should be around **150**
   - [ ] Max uploads per torrent: Should be **10** (improved from 5)

3. **Settings → Downloads**
   - [ ] Save path should point to: `/mnt/nvme/qbittorrent/incomplete` ✓
   - [ ] Or use `API` to verify:

     ```bash
     curl -s http://localhost:8080/api/v2/app/preferences | jq '.save_path'
     # Output should show: "/mnt/nvme/qbittorrent/incomplete"
     ```

4. **Settings → Advanced**
   - [ ] Disk cache: Should be **512 MiB** (up from 128)
   - [ ] Disk cache TTL: Should be **60 seconds**
   - [ ] Upload choking algorithm: **Fastest upload** (selected)
   - [ ] Upload slots behavior: **Fixed slots** (selected)

### API Verification (Automated)

```bash
# Complete settings dump
curl -s http://localhost:8080/api/v2/app/preferences | jq '{
  save_path,
  max_active_torrents,
  max_active_uploads,
  max_connec,
  max_connec_per_torrent,
  max_uploads,
  max_uploads_per_torrent,
  disk_cache,
  disk_cache_ttl
}'

# Expected output (approximate):
# {
#   "save_path": "/mnt/nvme/qbittorrent/incomplete",
#   "max_active_torrents": 150,
#   "max_active_uploads": 75,
#   "max_connec": 2000,
#   "max_connec_per_torrent": 200,
#   "max_uploads": 150,
#   "max_uploads_per_torrent": 10,
#   "disk_cache": 512,
#   "disk_cache_ttl": 60
# }
```

- [ ] All values match expected optimization targets
- [ ] No API errors in response

### Categories Verification

```bash
# List all categories via API
curl -s http://localhost:8080/api/v2/torrents/categories

# Expected output (with save paths):
# {
#   "radarr": {"name": "radarr", "savePath": "/mnt/storage/movies"},
#   "sonarr": {"name": "sonarr", "savePath": "/mnt/storage/tv"},
#   "lidarr": {"name": "lidarr", "savePath": "/mnt/storage/music"},
#   ...
# }
```

**Via Web UI:**

1. Go to **View → Torrent Categories**
2. Verify each category has correct save path:
   - [ ] `radarr` → `/mnt/storage/movies`
   - [ ] `sonarr` → `/mnt/storage/tv`
   - [ ] `lidarr` → `/mnt/storage/music`
   - [ ] `readarr` → `/mnt/storage/books`
   - [ ] `pc` → `/mnt/storage/pc`
   - [ ] `movies` → `/mnt/storage/movies`
   - [ ] `tv` → `/mnt/storage/tv`

---

## Phase 5: VPN & Networking Verification (5 minutes)

### VPN Namespace Verification

```bash
# Verify qBittorrent is running in VPN namespace
ip netns exec qbt ip addr show
# Should show network interfaces in the namespace

# Verify VPN IP (should NOT be your ISP IP)
ip netns exec qbt curl -s https://api.ipify.org
# Expected: ProtonVPN IP address (different from ISP)
```

- [ ] qBittorrent running in `qbt` namespace
- [ ] Can reach internet through VPN
- [ ] IP address is ProtonVPN (not ISP)

### Port Forwarding Verification

```bash
# Check current forwarded port
show-protonvpn-port

# Expected output: A port number between 40000-65000
```

- [ ] Port forwarding is active and showing a port
- [ ] Port matches in qBittorrent settings (typically 62000 but may be different)

```bash
# Verify external port accessibility (from external IP/device)
# Test from a different network if possible, or use a port checker service
# Expected: Your qBittorrent port is accessible from internet
```

- [ ] Port forwarding working (tested from external device/service)

### Firewall Rules

```bash
# Verify firewall allows WebUI on host
sudo nft list ruleset | grep 8080 || echo "WebUI port configured in namespace mapping"

# Verify qBittorrent can reach internet
ip netns exec qbt curl -I https://www.example.com 2>&1 | grep -E "^HTTP|Connection refused"
# Should show HTTP response, not "Connection refused"
```

- [ ] WebUI port (8080) is accessible from local network
- [ ] qBittorrent can reach peers on internet

---

## Phase 6: Integration Testing - Radarr/Sonarr (10 minutes)

### Radarr Configuration

**Access:** <http://192.168.1.210:7878>

1. Go to **Settings → Download Clients**
2. Add new download client (if not already configured):
   - [ ] Type: qBittorrent
   - [ ] Name: qBittorrent
   - [ ] Host: `192.168.1.210` (or `127.0.0.1` if on same machine)
   - [ ] Port: `8080`
   - [ ] Category: `radarr`
   - [ ] Test connection: Should show "Success"
   - [ ] Save

3. Verify existing configuration:

   ```bash
   # Test Radarr → qBittorrent connectivity
   curl -s "http://localhost:7878/api/v3/health" | jq '.[] | select(.type=="DownloadClient")'
   ```

   - [ ] Download client health check passes

### Sonarr Configuration

**Access:** <http://192.168.1.210:8989>

1. Go to **Settings → Download Clients**
2. Add new download client (if not already configured):
   - [ ] Type: qBittorrent
   - [ ] Name: qBittorrent
   - [ ] Host: `192.168.1.210`
   - [ ] Port: `8080`
   - [ ] Category: `sonarr`
   - [ ] Test connection: Should show "Success"
   - [ ] Save

3. Verify existing configuration:

   ```bash
   # Test Sonarr → qBittorrent connectivity
   curl -s "http://localhost:8989/api/v3/health" | jq '.[] | select(.type=="DownloadClient")'
   ```

   - [ ] Download client health check passes

### Download Integration Test

**Test 1: Movie Download (via Radarr)**

1. In Radarr, add a small movie (something you can download quickly)
2. Wait for search to complete
3. Select a result and click "Add and Download"
4. In qBittorrent, verify:
   - [ ] New torrent appears with category `radarr`
   - [ ] Downloads to `/mnt/nvme/qbittorrent/incomplete`
5. Wait for download to complete, then verify:
   - [ ] File is moved to `/mnt/storage/movies/` by Radarr
   - [ ] File appears in Jellyfin library within 24 hours

**Test 2: TV Show Download (via Sonarr)**

1. In Sonarr, add a TV show season (1-3 episodes)
2. Wait for search to complete
3. Select and add to library, triggering automatic download
4. In qBittorrent, verify:
   - [ ] New torrents appear with category `sonarr`
   - [ ] Download to `/mnt/nvme/qbittorrent/incomplete`
5. Wait for downloads to complete, then verify:
   - [ ] Files moved to `/mnt/storage/tv/` by Sonarr
   - [ ] Episodes appear in Jellyfin within 24 hours

- [ ] Radarr → qBittorrent integration working
- [ ] Sonarr → qBittorrent integration working
- [ ] Files moving to correct final locations

---

## Phase 7: Jellyfin Streaming Test (10 minutes)

### Basic Streaming

```bash
# Access Jellyfin
# URL: http://192.168.1.210:8096
```

- [ ] Jellyfin accessible and responsive
- [ ] Can play a local 1080p movie without buffering

### Stress Testing (Streaming + Seeding)

```bash
# Start monitoring in one terminal
monitor-hdd-storage.sh --continuous --interval 5

# In qBittorrent, start 2-3 large torrent uploads
# (or wait for Radarr/Sonarr downloads to complete)

# In Jellyfin, start a 4K movie stream
# Monitor for 5 minutes
```

**Observations:**

- [ ] Jellyfin video plays smoothly (no buffering)
- [ ] qBittorrent continues uploading at normal speeds
- [ ] HDD utilization stays below 50% (from monitor script)
- [ ] No "disk I/O errors" in logs

---

## Phase 8: Performance Baseline (10 minutes)

### Baseline Metrics

Run the monitoring script and capture baseline metrics:

```bash
# One-time report
monitor-hdd-storage.sh

# Save output for comparison
monitor-hdd-storage.sh > ~/qbittorrent-baseline-$(date +%Y%m%d).txt

# Continuous monitoring (run for 2-3 minutes)
monitor-hdd-storage.sh --continuous --interval 10 | head -100
```

**Record these baselines:**

- [ ] SSD usage for staging
- [ ] HDD usage for final storage
- [ ] HDD I/O utilization (should be <40%)
- [ ] Service status (all running)
- [ ] Temperature readings

### Download Speed Baseline

```bash
# Download a well-seeded torrent (e.g., Linux ISO) and measure speed
# Expected: 150-300 MB/s with these optimizations
```

- [ ] Download speed is acceptable (>100 MB/s for well-seeded torrents)

---

## Phase 9: System Stability (1-24 hours)

### Short-term Monitoring (1 hour)

```bash
# Monitor system for 1 hour to catch any immediate issues
watch -n 10 'systemctl status qbittorrent jellyfin radarr sonarr | grep -E "Active|Restart"'

# Or use:
monitor-hdd-storage.sh --continuous --interval 30
```

- [ ] All services remain stable and running
- [ ] No unexpected service restarts
- [ ] No "out of memory" errors
- [ ] No disk errors

### Long-term Stability Check (Overnight)

```bash
# Let system run overnight (or 12+ hours)
# Check logs in morning:
journalctl -u qbittorrent --since "12 hours ago" | grep -i "error\|critical" || echo "No errors found"
journalctl -u jellyfin --since "12 hours ago" | grep -i "error" | head -5 || echo "No errors found"
```

- [ ] qBittorrent running stably (check after 12+ hours)
- [ ] Jellyfin stable (no streaming issues reported)
- [ ] No error accumulation in logs

---

## Phase 10: Rollback Plan (If Needed)

If you encounter issues after rebuild, you can rollback:

```bash
# Revert to previous system generation
sudo nixos-rebuild switch --rollback

# Or rebuild with specific generation
nix-env --list-generations
sudo nixos-rebuild switch --profile /nix/var/nix/profiles/system --remove-generations 7d
```

If you need to revert qBittorrent config only:

```bash
# Stop qBittorrent
sudo systemctl stop qbittorrent

# Restore backup if created
cp -r ~/.backup/qbittorrent-backup-YYYYMMDD/* /var/lib/qbittorrent/

# Restart
sudo systemctl start qbittorrent
```

---

## Final Verification Checklist

Run this command to create a final verification report:

```bash
cat > /tmp/qbittorrent-final-check.sh << 'EOF'
#!/bin/bash
echo "=== qBittorrent Optimization Final Verification ==="
echo ""
echo "1. Services Status:"
systemctl is-active qbittorrent jellyfin radarr sonarr | grep -c "active" | xargs -I {} echo "  {}/4 services running"
echo ""
echo "2. Storage Configuration:"
echo "  Incomplete path: $(curl -s http://localhost:8080/api/v2/app/preferences | jq -r '.save_path')"
echo "  Disk cache: $(curl -s http://localhost:8080/api/v2/app/preferences | jq '.disk_cache') MiB"
echo ""
echo "3. Performance Settings:"
curl -s http://localhost:8080/api/v2/app/preferences | jq '{max_active_torrents, max_active_uploads, max_uploads, max_uploads_per_torrent}'
echo ""
echo "4. Disk Space:"
df -h /mnt/nvme/qbittorrent/incomplete /mnt/storage | tail -2
echo ""
echo "5. VPN Status:"
echo "  Namespace running: $(ip netns list | grep -c '^qbt$')/1"
echo "  External IP: $(ip netns exec qbt curl -s https://api.ipify.org)"
echo ""
echo "=== All checks complete ==="
EOF

chmod +x /tmp/qbittorrent-final-check.sh
/tmp/qbittorrent-final-check.sh
```

- [ ] Final verification report looks good
- [ ] All critical items checked
- [ ] System ready for production use

---

## Post-Deployment Checklist

After validation passes:

- [ ] Document any custom changes you made
- [ ] Set up monitoring cron job (optional):

  ```bash
  # Run monitor daily at midnight
  echo "0 0 * * * /home/lewis/.config/nix/scripts/monitor-hdd-storage.sh > /var/log/hdd-monitor-daily.log 2>&1" | sudo tee -a /etc/cron.d/qbittorrent-monitor
  ```

- [ ] Schedule regular HDD health checks
- [ ] Consider setting up media backup strategy
- [ ] Note the rebuild date for future reference

---

## Support Resources

If issues arise, check:

1. **Configuration Guide**: `/home/lewis/.config/nix/docs/QBITTORRENT_OPTIMIZATION.md`
2. **Monitoring Script**: `/home/lewis/.config/nix/scripts/monitor-hdd-storage.sh`
3. **qBittorrent Logs**:

   ```bash
   journalctl -u qbittorrent -f
   ```

4. **System Logs**:

   ```bash
   journalctl -b | grep -i error | head -20
   ```

---

## Validation Summary

Total estimated time: **1-2 hours** for complete validation

- **Phase 1 (Rebuild)**: 10 minutes
- **Phase 2-3 (Verification)**: 10 minutes
- **Phase 4 (qBittorrent Config)**: 10 minutes
- **Phase 5 (VPN/Networking)**: 5 minutes
- **Phase 6 (Radarr/Sonarr)**: 15 minutes
- **Phase 7 (Jellyfin)**: 15 minutes
- **Phase 8 (Baselines)**: 10 minutes
- **Phase 9 (Stability)**: 1-24 hours (background)
- **Phase 10 (Rollback Planning)**: 5 minutes

**Next Steps**: Once all checks pass, your qBittorrent system is optimized and ready for production use!
