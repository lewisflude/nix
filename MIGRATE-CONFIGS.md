# Migrating Configuration Files from Docker to Podman

This guide helps you migrate your existing configurations, databases, and settings from `/opt/stacks` to the new Nix-managed Podman containers.

## 🎯 What Gets Migrated

This will copy:
- ✅ **Databases** (SQLite files with your media, indexers, etc.)
- ✅ **API Keys** (saved connections between services)
- ✅ **Settings** (all your configurations)
- ✅ **Download client configs**
- ✅ **Custom scripts and filters**
- ✅ **Authentication settings**

## 🚀 Quick Migration (Automated)

### Option 1: Use the Migration Script

```bash
cd ~/.config/nix
./scripts/containers/migrate-configs.sh
```

The script will:
1. Create a backup of current configs
2. Stop Podman services
3. Copy configs from `/opt/stacks` to `/var/lib/containers`
4. Fix permissions
5. Restart services

**That's it!** Your services will have all their old settings.

---

## 🛠️ Manual Migration (Step-by-Step)

If you prefer to do it manually or migrate specific services:

### Step 1: Stop the Services

```bash
# Stop all media services
sudo systemctl stop podman-prowlarr podman-radarr podman-sonarr \
  podman-lidarr podman-whisparr podman-readarr \
  podman-qbittorrent podman-sabnzbd podman-jellyfin
```

### Step 2: Copy Configuration Files

For each service, copy the old config:

```bash
# Example: Prowlarr
sudo cp -r /opt/stacks/media-management/prowlarr/config/* \
  /var/lib/containers/media-management/prowlarr/

# Example: Radarr
sudo cp -r /opt/stacks/media-management/radarr/config/* \
  /var/lib/containers/media-management/radarr/

# Example: Sonarr
sudo cp -r /opt/stacks/media-management/sonarr/config/* \
  /var/lib/containers/media-management/sonarr/
```

**Or copy all at once:**

```bash
# Prowlarr
sudo rsync -av /opt/stacks/media-management/prowlarr/config/ \
  /var/lib/containers/media-management/prowlarr/

# Radarr
sudo rsync -av /opt/stacks/media-management/radarr/config/ \
  /var/lib/containers/media-management/radarr/

# Sonarr  
sudo rsync -av /opt/stacks/media-management/sonarr/config/ \
  /var/lib/containers/media-management/sonarr/

# Lidarr
sudo rsync -av /opt/stacks/media-management/lidarr/config/ \
  /var/lib/containers/media-management/lidarr/

# qBittorrent
sudo rsync -av /opt/stacks/media-management/qbittorrent/config/ \
  /var/lib/containers/media-management/qbittorrent/

# SABnzbd
sudo rsync -av /opt/stacks/media-management/sabnzbd/config/ \
  /var/lib/containers/media-management/sabnzbd/

# Jellyfin
sudo rsync -av /opt/stacks/media-management/jellyfin/config/ \
  /var/lib/containers/media-management/jellyfin/
```

### Step 3: Fix Permissions

```bash
sudo chown -R 1000:100 /var/lib/containers/media-management/*
```

### Step 4: Restart Services

```bash
sudo systemctl start podman-prowlarr podman-radarr podman-sonarr \
  podman-lidarr podman-qbittorrent podman-sabnzbd podman-jellyfin
```

### Step 5: Verify

```bash
# Check services are running
systemctl list-units 'podman-*' | grep running

# Test web interfaces
curl http://localhost:9696  # Prowlarr
curl http://localhost:7878  # Radarr
curl http://localhost:8989  # Sonarr
```

---

## 📋 Service Mapping

Docker Compose location → Podman location:

| Service | Old Path | New Path |
|---------|----------|----------|
| Prowlarr | `/opt/stacks/media-management/prowlarr/config` | `/var/lib/containers/media-management/prowlarr` |
| Radarr | `/opt/stacks/media-management/radarr/config` | `/var/lib/containers/media-management/radarr` |
| Sonarr | `/opt/stacks/media-management/sonarr/config` | `/var/lib/containers/media-management/sonarr` |
| Lidarr | `/opt/stacks/media-management/lidarr/config` | `/var/lib/containers/media-management/lidarr` |
| Whisparr | `/opt/stacks/media-management/whisparr/config` | `/var/lib/containers/media-management/whisparr` |
| Readarr | `/opt/stacks/media-management/readarr/config` | `/var/lib/containers/media-management/readarr` |
| qBittorrent | `/opt/stacks/media-management/qbittorrent/config` | `/var/lib/containers/media-management/qbittorrent` |
| SABnzbd | `/opt/stacks/media-management/sabnzbd/config` | `/var/lib/containers/media-management/sabnzbd` |
| Jellyfin | `/opt/stacks/media-management/jellyfin/config` | `/var/lib/containers/media-management/jellyfin` |
| Jellyseerr | `/opt/stacks/media-management/jellyseer/config` | `/var/lib/containers/media-management/jellyseerr` |

---

## 🔧 Per-Service Migration Commands

Copy and paste these individual commands:

```bash
# Prowlarr
sudo systemctl stop podman-prowlarr
sudo rsync -av /opt/stacks/media-management/prowlarr/config/ /var/lib/containers/media-management/prowlarr/
sudo chown -R 1000:100 /var/lib/containers/media-management/prowlarr
sudo systemctl start podman-prowlarr

# Radarr
sudo systemctl stop podman-radarr
sudo rsync -av /opt/stacks/media-management/radarr/config/ /var/lib/containers/media-management/radarr/
sudo chown -R 1000:100 /var/lib/containers/media-management/radarr
sudo systemctl start podman-radarr

# Sonarr
sudo systemctl stop podman-sonarr
sudo rsync -av /opt/stacks/media-management/sonarr/config/ /var/lib/containers/media-management/sonarr/
sudo chown -R 1000:100 /var/lib/containers/media-management/sonarr
sudo systemctl start podman-sonarr

# Lidarr
sudo systemctl stop podman-lidarr
sudo rsync -av /opt/stacks/media-management/lidarr/config/ /var/lib/containers/media-management/lidarr/
sudo chown -R 1000:100 /var/lib/containers/media-management/lidarr
sudo systemctl start podman-lidarr

# qBittorrent
sudo systemctl stop podman-qbittorrent
sudo rsync -av /opt/stacks/media-management/qbittorrent/config/ /var/lib/containers/media-management/qbittorrent/
sudo chown -R 1000:100 /var/lib/containers/media-management/qbittorrent
sudo systemctl start podman-qbittorrent

# SABnzbd
sudo systemctl stop podman-sabnzbd
sudo rsync -av /opt/stacks/media-management/sabnzbd/config/ /var/lib/containers/media-management/sabnzbd/
sudo chown -R 1000:100 /var/lib/containers/media-management/sabnzbd
sudo systemctl start podman-sabnzbd

# Jellyfin
sudo systemctl stop podman-jellyfin
sudo rsync -av /opt/stacks/media-management/jellyfin/config/ /var/lib/containers/media-management/jellyfin/
sudo chown -R 1000:100 /var/lib/containers/media-management/jellyfin
sudo systemctl start podman-jellyfin
```

---

## ⚠️ Important Notes

### Path Updates Needed

Some services store absolute paths. After migration, you may need to update:

1. **Download Client Paths** in Radarr/Sonarr/Lidarr:
   - Old: May reference Docker internal paths
   - New: Should still work with `/mnt/storage`

2. **Indexer Settings** in Prowlarr:
   - Should automatically reconnect
   - May need to test connections

3. **Media Paths** in Jellyfin:
   - Old: `/mnt/storage`
   - New: Still `/mnt/storage` (no change needed)

### Service URLs

If services can't find each other, update URLs:
- Old: `http://radarr:7878` (Docker network names)
- New: `http://radarr:7878` (Podman network names - same!)

The network names work the same way, so this usually doesn't need changes.

---

## 🧪 Verification Checklist

After migration, verify:

```bash
# Check all services are running
systemctl list-units 'podman-*' | grep running

# Test each service
curl http://localhost:9696  # Prowlarr
curl http://localhost:7878  # Radarr  
curl http://localhost:8989  # Sonarr
curl http://localhost:8686  # Lidarr
curl http://localhost:8080  # qBittorrent
curl http://localhost:8096  # Jellyfin

# Check logs for errors
journalctl -u podman-prowlarr -n 20
journalctl -u podman-radarr -n 20
journalctl -u podman-sonarr -n 20
```

### In Web Interfaces

1. **Prowlarr** - Check indexers still work
2. **Radarr/Sonarr** - Test indexer connections
3. **Radarr/Sonarr** - Test download client connections
4. **qBittorrent** - Check categories and paths
5. **Jellyfin** - Verify media libraries still scan

---

## 🔄 Rollback

If something goes wrong:

```bash
# Stop new services
sudo systemctl stop 'podman-*'

# Start old Docker Compose stack
cd /opt/stacks/media-management
docker compose up -d
```

Your original configs in `/opt/stacks` are untouched!

---

## 🗑️ Cleanup (After Verification)

Once everything works for a few days:

```bash
# Stop Docker Compose (if still running)
cd /opt/stacks/media-management
docker compose down

# Optional: Remove old configs (BE CAREFUL!)
# Make sure Podman version works first!
# sudo rm -rf /opt/stacks

# Or just move them as backup
sudo mv /opt/stacks /opt/stacks.backup
```

---

## 💡 Tips

1. **Migrate one service at a time** - Easier to troubleshoot
2. **Test each service** before moving to the next
3. **Keep `/opt/stacks` as backup** for a while
4. **Document any custom changes** you made
5. **Screenshot important settings** before migration

---

## 🆘 Troubleshooting

### Service won't start after migration

```bash
# Check logs
journalctl -u podman-radarr -n 50

# Check permissions
sudo ls -la /var/lib/containers/media-management/radarr

# Fix if needed
sudo chown -R 1000:100 /var/lib/containers/media-management/radarr
```

### Database corruption

```bash
# Restore from old config
sudo rm -rf /var/lib/containers/media-management/radarr/*
sudo cp -r /opt/stacks/media-management/radarr/config/* \
  /var/lib/containers/media-management/radarr/
sudo chown -R 1000:100 /var/lib/containers/media-management/radarr
sudo systemctl restart podman-radarr
```

### Services can't connect to each other

```bash
# Check networks
podman network ls

# Inspect a service
podman inspect radarr | grep -i network

# Restart network services
sudo systemctl restart podman-network-media
```

---

## ✨ Success!

Once migrated, you'll have:
- ✅ All your old settings and data
- ✅ Declarative NixOS configuration  
- ✅ Better security (rootless containers)
- ✅ System-integrated management
- ✅ Easy rollback capability

Your services will work exactly as before, but now managed by Nix! 🎉
