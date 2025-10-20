# Migration to Native NixOS Services

This guide covers the migration from containerized services to native NixOS modules for your media management and productivity stack.

## Overview

We've migrated from Podman containers to native NixOS services where official modules exist. This provides:

- ✅ **Declarative configuration** - Everything in your NixOS config
- ✅ **Better integration** - Automatic user/group management, firewall rules
- ✅ **Easier upgrades** - Follow nixpkgs channels, no manual image pulls
- ✅ **State management** - Consistent paths via NixOS modules
- ✅ **systemd integration** - Better logging, dependencies, and monitoring

## What Changed

### Native Services (Recommended)

These services now use official NixOS modules:

#### Media Management Stack
- **Prowlarr** - `services.prowlarr`
- **Radarr** - `services.radarr`
- **Sonarr** - `services.sonarr`
- **Lidarr** - `services.lidarr`
- **Readarr** - `services.readarr`
- **Whisparr** - `services.whisparr`
- **qBittorrent** - `services.qbittorrent`
- **SABnzbd** - `services.sabnzbd`
- **Jellyfin** - `services.jellyfin`
- **Jellyseerr** - `services.jellyseerr`
- **FlareSolverr** - `services.flaresolverr`
- **Unpackerr** - Custom systemd service (no official module yet)

#### Productivity Stack
- **Ollama** - `services.ollama`
- **Open WebUI** - `services.open-webui`

### Containerized Services (Supplemental)

These remain as containers (no native modules available):
- **Homarr** - Dashboard
- **Wizarr** - Invitation system
- **Doplarr** - Discord bot
- **ComfyUI** - AI image generation (GPU complexity)
- **Music Assistant** - Already has `services.music-assistant`

## Configuration Structure

### New Directory Layout

```
modules/nixos/services/
├── media-management/          # Native media services
│   ├── default.nix
│   ├── prowlarr.nix
│   ├── radarr.nix
│   ├── sonarr.nix
│   ├── lidarr.nix
│   ├── readarr.nix
│   ├── whisparr.nix
│   ├── qbittorrent.nix
│   ├── sabnzbd.nix
│   ├── jellyfin.nix
│   ├── jellyseerr.nix
│   ├── flaresolverr.nix
│   └── unpackerr.nix
├── productivity/              # Native AI tools
│   ├── default.nix
│   ├── ollama.nix
│   └── open-webui.nix
├── containers-supplemental/   # Remaining containers
│   └── default.nix
└── containers/                # DEPRECATED - for reference only
    └── ...
```

### Host Configuration

In `hosts/jupiter/default.nix`:

```nix
# NEW: Native media management
mediaManagement = {
  enable = true;
  dataPath = "/mnt/storage";
  timezone = "Europe/London";
  # All services enabled by default
};

# NEW: Native productivity
productivity = {
  enable = true;
  ollama = {
    enable = true;
    acceleration = "cuda"; # or "rocm" or null
    models = ["llama2"];
  };
  openWebui = {
    enable = true;
    port = 7000;
  };
};

# NEW: Supplemental containers
containersSupplemental = {
  enable = true;
  homarr.enable = true;
  wizarr.enable = true;
  doplarr.enable = false;
  comfyui.enable = false;
};

# OLD: Deprecated (disable this)
containers = {
  enable = false; # Set to false
};
```

## Migration Steps

### 1. Backup Your Data

Before migrating, backup your existing container data:

```bash
# Backup container configs
sudo tar -czf ~/container-backup-$(date +%Y%m%d).tar.gz \
  /var/lib/containers/media-management \
  /var/lib/containers/productivity
```

### 2. Stop Old Container Services

```bash
# List all podman containers
sudo systemctl list-units "podman-*"

# Stop media management containers
sudo systemctl stop podman-prowlarr
sudo systemctl stop podman-radarr
sudo systemctl stop podman-sonarr
# ... (stop all)
```

### 3. Update Your Configuration

Edit `hosts/jupiter/default.nix`:
- Set `containers.enable = false`
- Set `mediaManagement.enable = true`
- Set `productivity.enable = true`
- Set `containersSupplemental.enable = true`

### 4. Rebuild NixOS

```bash
sudo nixos-rebuild switch
```

### 5. Migrate Data (if needed)

Native services use different state directories:

| Service | Container Path | Native Path |
|---------|---------------|-------------|
| Prowlarr | `/var/lib/containers/media-management/prowlarr` | `/var/lib/prowlarr` |
| Radarr | `/var/lib/containers/media-management/radarr` | `/var/lib/radarr` |
| Sonarr | `/var/lib/containers/media-management/sonarr` | `/var/lib/sonarr` |
| Jellyfin | `/var/lib/containers/media-management/jellyfin` | `/var/lib/jellyfin` |
| Ollama | `/var/lib/containers/productivity/ollama` | `/var/lib/ollama` |

To migrate data:

```bash
# Example: Migrate Radarr
sudo systemctl stop radarr
sudo cp -r /var/lib/containers/media-management/radarr/* /var/lib/radarr/
sudo chown -R radarr:media /var/lib/radarr
sudo systemctl start radarr
```

**Note:** Most services will work fine starting fresh, as they'll re-sync with Prowlarr and your download clients.

### 6. Verify Services

```bash
# Check service status
sudo systemctl status prowlarr
sudo systemctl status radarr
sudo systemctl status sonarr
sudo systemctl status jellyfin
sudo systemctl status ollama
sudo systemctl status open-webui

# Check logs
sudo journalctl -u radarr -f
```

### 7. Update Service URLs

If using Homarr or other dashboards, update service URLs:
- Services are now on localhost (not bridged networks)
- Ports remain the same

## Service Details

### Media Management

All services run as the `media` user/group by default.

**Default Ports:**
- Prowlarr: 9696
- Radarr: 7878
- Sonarr: 8989
- Lidarr: 8686
- Readarr: 8787
- Whisparr: 6969
- qBittorrent: 8080
- SABnzbd: 8082
- Jellyfin: 8096 (HTTP), 8920 (HTTPS)
- Jellyseerr: 5055
- FlareSolverr: 8191

### Productivity

Services run as `productivity` user/group.

**Default Ports:**
- Ollama: 11434 (localhost only)
- Open WebUI: 7000

### GPU Acceleration

**Jellyfin**: Automatically grants `media` user access to `/dev/dri` for hardware transcoding.

**Ollama**: Set `acceleration = "cuda"` or `"rocm"` in config.

**ComfyUI**: Remains containerized due to complex GPU setup.

## Disabling Individual Services

To disable specific services:

```nix
mediaManagement = {
  enable = true;
  # Disable specific services
  whisparr.enable = false;
  lidarr.enable = false;
};
```

## Troubleshooting

### Service won't start

Check logs:
```bash
sudo journalctl -u <service-name> -n 50
```

### Permission issues

Native services use system users. Check ownership:
```bash
ls -la /var/lib/<service-name>
sudo chown -R <service>:<group> /var/lib/<service-name>
```

### Port conflicts

Native services use standard ports. Check for conflicts:
```bash
sudo ss -tlnp | grep :<port>
```

### Data migration issues

If a service won't start after data migration, try:
1. Stop the service
2. Move the old data aside: `sudo mv /var/lib/<service> /var/lib/<service>.old`
3. Start service (fresh state)
4. Reconfigure via web UI

## Rollback

If you need to rollback:

1. Set `containers.enable = true` and `mediaManagement.enable = false`
2. Rebuild: `sudo nixos-rebuild switch`
3. Restore data from backup if needed

## Benefits of Native Services

### Declarative Configuration
```nix
services.radarr = {
  enable = true;
  user = "media";
  group = "media";
  openFirewall = true;
};
```

### Automatic Updates
- Follow your NixOS channel
- `nixos-rebuild switch` updates all services
- No manual container image management

### Better Integration
- systemd service management
- Automatic firewall rules
- Proper user/group management
- Clean dependency ordering

### Easier Debugging
```bash
# Service logs
sudo journalctl -u radarr -f

# Service status
systemctl status radarr

# Restart single service
sudo systemctl restart radarr
```

## Next Steps

1. Test each service in your browser
2. Reconfigure interconnections (Prowlarr → Radarr/Sonarr)
3. Update Homarr dashboard with new service info
4. Consider enabling monitoring (Prometheus/Grafana)

## Reference

- [NixOS Manual - Services](https://nixos.org/manual/nixos/stable/#ch-configuration)
- [Media Management Module](../modules/nixos/services/media-management/)
- [Productivity Module](../modules/nixos/services/productivity/)
