# Data Migration Guide: Containers → Native Services

This guide walks you through migrating your existing container data to the new native NixOS services.

## Overview

The migration process:
1. ✅ Creates backups of all container data
2. ✅ Stops old container services
3. ✅ Copies data to native service directories
4. ✅ Fixes permissions for new service users
5. ✅ Starts native services
6. ✅ Verifies everything works

**Estimated time:** 15-30 minutes  
**Downtime:** ~5-10 minutes (services will be briefly offline)

## Pre-Migration Checklist

### 1. Verify Current Setup

Check what containers are running:
```bash
systemctl list-units "podman-*" --state=running
```

Check container data exists:
```bash
ls -lh /var/lib/containers/media-management/
ls -lh /var/lib/containers/productivity/
```

### 2. Free Disk Space

Ensure you have enough space for backups (~2x current data):
```bash
df -h /var/lib
```

The script creates backups before migrating, so you need space for:
- Original container data
- Backup copy
- New native service data

### 3. Note Important Settings

Before migration, record any custom settings from your services:
- API keys (you'll need to re-enter these)
- Download client connections (will need reconfiguration)
- Custom paths or settings

## Migration Methods

### Method 1: Automated Script (Recommended)

We've created a migration script that handles everything automatically.

#### Test Run (Dry Run)
```bash
# See what would be done without making changes
sudo bash scripts/maintenance/migrate-container-data.sh --dry-run
```

#### Actual Migration
```bash
# Perform the actual migration
sudo bash scripts/maintenance/migrate-container-data.sh
```

The script will:
- Show you what it's going to do
- Ask for confirmation
- Create timestamped backups
- Migrate all data
- Start native services
- Report any issues

### Method 2: Manual Migration

If you prefer manual control or need to migrate specific services:

#### Step-by-Step for Each Service

**Example: Radarr**

```bash
# 1. Stop services
sudo systemctl stop podman-radarr
sudo systemctl stop radarr

# 2. Backup container data
sudo cp -a /var/lib/containers/media-management/radarr \
         /var/lib/container-backups/radarr-$(date +%Y%m%d)

# 3. Copy to native location
sudo mkdir -p /var/lib/radarr
sudo cp -a /var/lib/containers/media-management/radarr/* /var/lib/radarr/

# 4. Fix permissions
sudo chown -R media:media /var/lib/radarr

# 5. Start native service
sudo systemctl start radarr

# 6. Check status
sudo systemctl status radarr
sudo journalctl -u radarr -n 50
```

**Repeat for other services:**
- `prowlarr`
- `sonarr`
- `lidarr`
- `readarr`
- `whisparr` (if you use it)
- `qbittorrent`
- `sabnzbd`
- `jellyfin` (note: config in `/config` subdirectory)
- `jellyseerr`
- `ollama` (if using AI tools)
- `open-webui` (if using AI tools)

## Service-Specific Notes

### Jellyfin
Jellyfin has two directories in containers:
- `config/` → `/var/lib/jellyfin`
- `cache/` → `/var/cache/jellyfin` (can be regenerated if needed)

```bash
sudo systemctl stop jellyfin
sudo mkdir -p /var/lib/jellyfin /var/cache/jellyfin
sudo cp -a /var/lib/containers/media-management/jellyfin/config/* /var/lib/jellyfin/
sudo cp -a /var/lib/containers/media-management/jellyfin/cache/* /var/cache/jellyfin/
sudo chown -R media:media /var/lib/jellyfin /var/cache/jellyfin
sudo systemctl start jellyfin
```

### Unpackerr
Unpackerr has minimal state. The configuration is now in your NixOS config.
You may need to set API keys in the configuration file later.

### AI Tools (Ollama/Open WebUI)
Models are large (~4GB+ each). Migration preserves downloaded models.

```bash
# Ollama
sudo systemctl stop ollama
sudo cp -a /var/lib/containers/productivity/ollama/* /var/lib/ollama/
sudo chown -R aitools:aitools /var/lib/ollama
sudo systemctl start ollama

# Open WebUI
sudo systemctl stop open-webui
sudo cp -a /var/lib/containers/productivity/openwebui/* /var/lib/open-webui/
sudo chown -R aitools:aitools /var/lib/open-webui
sudo systemctl start open-webui
```

## Post-Migration Verification

### 1. Check All Services Started

```bash
# Media services
systemctl status prowlarr radarr sonarr lidarr readarr qbittorrent sabnzbd jellyfin jellyseerr

# AI tools (if enabled)
systemctl status ollama open-webui

# Check for failures
systemctl list-units --state=failed
```

### 2. Verify Web UIs

Open each service and verify:
- ✅ Settings are preserved
- ✅ Library data is intact
- ✅ Queue history visible
- ✅ No errors in logs

**Service URLs:**
- Prowlarr: http://localhost:9696
- Radarr: http://localhost:7878
- Sonarr: http://localhost:8989
- Lidarr: http://localhost:8686
- Readarr: http://localhost:8787
- qBittorrent: http://localhost:8080
- SABnzbd: http://localhost:8082
- Jellyfin: http://localhost:8096
- Jellyseerr: http://localhost:5055
- Open WebUI: http://localhost:7000

### 3. Reconnect Services

You may need to reconfigure connections between services:

**In Radarr/Sonarr/etc:**
1. Go to Settings → Download Clients
2. Test connections to qBittorrent/SABnzbd
3. If they fail, update URLs (should still be `localhost:8080` or `localhost:8082`)

**In Prowlarr:**
1. Go to Settings → Apps
2. Test connections to Radarr/Sonarr
3. API keys should be preserved, but re-test connections

**In Jellyseerr:**
1. Go to Settings → Jellyfin
2. Test connection to Jellyfin
3. Should still be `http://localhost:8096`

### 4. Check Logs for Errors

```bash
# Check each service for errors
sudo journalctl -u prowlarr -n 100
sudo journalctl -u radarr -n 100
sudo journalctl -u sonarr -n 100
sudo journalctl -u jellyfin -n 100

# Check for permission errors
sudo journalctl | grep -i "permission denied"
```

## Troubleshooting

### Service Won't Start

**Check logs:**
```bash
sudo journalctl -u <service-name> -n 50
```

**Common issues:**
1. **Permission errors** → Run: `sudo chown -R media:media /var/lib/<service>`
2. **Port conflicts** → Check if old container still running: `systemctl stop podman-<service>`
3. **Missing files** → Verify data was copied: `ls -la /var/lib/<service>`

### Data Not Showing Up

**Verify data was copied:**
```bash
ls -la /var/lib/<service-name>
```

**Check ownership:**
```bash
ls -ld /var/lib/<service-name>
# Should show: drwxr-xr-x media media
```

**Re-copy if needed:**
```bash
sudo systemctl stop <service>
sudo rm -rf /var/lib/<service>/*
sudo cp -a /var/lib/containers/media-management/<service>/* /var/lib/<service>/
sudo chown -R media:media /var/lib/<service>
sudo systemctl start <service>
```

### Jellyfin Transcoding Not Working

Grant hardware access:
```bash
# Check if media user is in video/render groups
groups media

# If not, the module should have done this, but you can manually add:
sudo usermod -aG video,render media
sudo systemctl restart jellyfin
```

### API Keys Not Working

Some services may need API keys re-entered:
1. Go to service settings
2. Find API key section (Settings → General → Security)
3. Regenerate API key if needed
4. Update in dependent services

## Rollback Procedure

If you need to rollback to containers:

### 1. Stop Native Services
```bash
sudo systemctl stop prowlarr radarr sonarr lidarr readarr qbittorrent sabnzbd jellyfin jellyseerr
```

### 2. Revert Configuration
```bash
cd /home/lewis/.config/nix

# Edit hosts/jupiter/default.nix
# Set: mediaManagement.enable = false;
# Set: containers.enable = true;

sudo nixos-rebuild switch
```

### 3. Restore Container Data (if needed)
```bash
# From backup
sudo cp -a /var/lib/container-backups/<timestamp>/* /var/lib/containers/media-management/
```

### 4. Start Container Services
```bash
sudo systemctl start podman-prowlarr podman-radarr podman-sonarr
# etc...
```

## Cleanup After Successful Migration

**After 1-2 weeks of stable operation:**

### 1. Remove Old Container Data
```bash
# Keep backups, remove source
sudo rm -rf /var/lib/containers/media-management
sudo rm -rf /var/lib/containers/productivity
```

### 2. Remove Old Container Services Module
```bash
# Remove deprecated container configs
rm -rf modules/nixos/services/containers/
```

### 3. Optional: Remove Old Documentation
```bash
rm -f CONTAINER-IMPROVEMENTS.md CONTAINERS-QUICKSTART.md \
      docs/CONTAINERS-SETUP.md MIGRATE-CONFIGS.md \
      TEST-CONTAINERS.md TESTING-GUIDE.md HOW-TO-TEST.md
```

### 4. Keep Backups
**Don't delete backups immediately!** Keep them for at least 30 days:
```bash
# Backups are in:
ls -lh /var/lib/container-backups-*/
```

## Migration Checklist

Print this out or keep it open during migration:

- [ ] ✅ Pre-migration backup created
- [ ] ✅ Disk space verified (>50% free)
- [ ] ✅ Applied new NixOS configuration (`nixos-rebuild switch`)
- [ ] ✅ Ran migration script (or manual steps)
- [ ] ✅ All services started successfully
- [ ] ✅ Verified web UIs accessible
- [ ] ✅ Tested service connections (Prowlarr → Radarr/Sonarr)
- [ ] ✅ Tested download clients (qBittorrent/SABnzbd)
- [ ] ✅ Checked logs for errors
- [ ] ✅ Jellyfin playback tested
- [ ] ✅ No permission errors in logs
- [ ] ✅ Documented any custom settings needed
- [ ] ✅ Scheduled cleanup in 2-4 weeks

## Support

If you run into issues:

1. **Check logs first:** `journalctl -u <service-name> -n 100`
2. **Verify permissions:** `ls -la /var/lib/<service>`
3. **Test service manually:** Try starting it and watch logs in real-time
4. **Restore from backup:** Backups are in `/var/lib/container-backups-<timestamp>`

## Summary

This migration process:
- ✅ Preserves all your data
- ✅ Creates safety backups
- ✅ Can be rolled back
- ✅ Takes ~15-30 minutes
- ✅ Results in cleaner, more maintainable setup

Good luck with the migration! 🚀
