# Container Services Conversion Summary

## What Was Done

Successfully converted Docker Compose configurations from `/opt/stacks` to declarative NixOS container services using Podman.

### Files Created

```
modules/nixos/services/containers/
├── default.nix              # Main module with container configuration
├── media-management.nix     # Media stack services (Arr apps, Jellyfin, etc.)
├── productivity.nix         # AI/productivity stack (Ollama, ComfyUI, etc.)
├── secrets.nix              # Secrets management configuration
├── README.md                # User documentation
├── MIGRATION.md             # Step-by-step migration guide
└── SUMMARY.md               # This file

modules/nixos/features/containers.nix  # Feature bridge module
hosts/jupiter/containers-example.nix   # Example configuration
```

### Services Converted

#### Media Management Stack (19 services)
- **Indexers**: Prowlarr, FlareSolverr
- **Media Managers**: Radarr, Sonarr, Lidarr, Whisparr, Readarr
- **Downloaders**: qBittorrent, SABnzbd
- **Media Server**: Jellyfin
- **Request System**: Jellyseerr
- **Tools**: Unpackerr, Homarr, Wizarr, Janitorr, Recommendarr, Autopulse, Kapowarr, Doplarr

#### Productivity Stack (4 services)
- **LLM**: Ollama (host network, GPU)
- **UI**: Open WebUI (port 7000, GPU)
- **Image AI**: ComfyUI (port 8188, GPU)
- **Updates**: CUP (Container Update Proxy)

## Key Features

### 1. Declarative Configuration
- All containers defined in Nix
- Version controlled
- Reproducible across systems

### 2. Podman Integration
- Rootless containers
- Docker API compatibility
- Systemd service management
- Native security features

### 3. Network Architecture
- `media` network: Internal service communication
- `frontend` network: External web interface access
- Host networking: GPU-enabled containers

### 4. GPU Support
- NVIDIA Container Toolkit integration
- CDI (Container Device Interface)
- Automatic device passthrough

### 5. Secrets Management
- Sops-nix integration ready
- Encrypted secrets support
- Safe API key handling

### 6. Resource Management
- CPU/memory limits preserved
- Health checks configured
- Restart policies set
- Service dependencies managed

## Configuration Structure

### Host Configuration Path
```
hosts/jupiter/default.nix
└── features.containers
    ├── enable = true
    ├── mediaManagement
    │   ├── enable = true
    │   ├── dataPath = "/mnt/storage"
    │   └── configPath = "/var/lib/containers/media-management"
    └── productivity
        ├── enable = true
        └── configPath = "/var/lib/containers/productivity"
```

### Module Flow
```
host.features.containers (features/containers.nix)
    ↓
host.services.containers (services/containers/default.nix)
    ↓
virtualisation.oci-containers (media-management.nix, productivity.nix)
    ↓
systemd.services.podman-* (systemd units)
```

## Usage Example

### Enable in Jupiter Host

Edit `hosts/jupiter/default.nix`:

```nix
features = {
  # ... existing features ...
  
  containers = {
    enable = true;
    mediaManagement.enable = true;
    productivity.enable = true;
  };
};
```

### Deploy

```bash
sudo nixos-rebuild switch --flake .#jupiter
```

### Verify

```bash
systemctl list-units 'podman-*'
podman ps
```

## Port Mapping Reference

| Service | Port | Description |
|---------|------|-------------|
| Prowlarr | 9696 | Indexer manager |
| Radarr | 7878 | Movie manager |
| Sonarr | 8989 | TV show manager |
| Lidarr | 8686 | Music manager |
| Whisparr | 6969 | Adult content manager |
| Readarr | 8787 | Book manager |
| qBittorrent | 8080 | Torrent client |
| SABnzbd | 8082 | Usenet client |
| Jellyfin | 8096 | Media server |
| Jellyseerr | 5055 | Request management |
| FlareSolverr | 8191 | Cloudflare bypass |
| Homarr | 7575 | Dashboard |
| Janitorr | n/a | Media cleanup automation |
| Wizarr | 5690 | Invitation system |
| Recommendarr | 3579 | Recommendations |
| Kapowarr | 5656 | Comic manager |
| Ollama | host | LLM backend |
| Open WebUI | 7000 | LLM interface |
| ComfyUI | 8188 | Image generation |
| CUP | 1188 | Update proxy |

## Migration Checklist

- [ ] Backup `/opt/stacks` data
- [ ] Stop Docker Compose stacks
- [ ] Enable containers in host config
- [ ] Rebuild NixOS
- [ ] Verify all services running
- [ ] Test service connectivity
- [ ] Update inter-service URLs if needed
- [ ] Configure secrets with sops-nix
- [ ] Test GPU containers (productivity)
- [ ] Monitor logs for errors
- [ ] Optional: Clean up Docker

## Benefits Over Docker Compose

1. **System Integration**: Native systemd management
2. **Declarative**: All config in version control
3. **Atomic**: Rollback-able changes
4. **Secure**: Rootless by default
5. **Dependencies**: Automatic service ordering
6. **Monitoring**: Built-in systemd logging
7. **Updates**: Tied to system updates
8. **GPU**: Native NVIDIA support

## Next Steps

1. Review `MIGRATION.md` for detailed migration steps
2. Check `README.md` for configuration options
3. See `containers-example.nix` for usage example
4. Test in stages (e.g., enable media stack first)
5. Set up secrets management with sops-nix
6. Monitor services after migration

## Differences from Docker Compose

### What's the Same
- Container images (unchanged)
- Port mappings (preserved)
- Volume mounts (maintained)
- Environment variables (equivalent)
- Networks (converted)

### What's Different
- **Manager**: Podman instead of Docker
- **Orchestrator**: systemd instead of docker-compose
- **Config**: Nix instead of YAML
- **Location**: `/var/lib/containers` instead of `/opt/stacks` (configurable)
- **Secrets**: sops-nix instead of `.env` files

### What's Better
- ✅ Declarative and reproducible
- ✅ Version controlled
- ✅ Atomic updates
- ✅ Better security (rootless)
- ✅ Native system integration
- ✅ Rollback capability

## Support

- **Documentation**: See `README.md` and `MIGRATION.md`
- **Logs**: `journalctl -u podman-<service>`
- **Status**: `systemctl status podman-<service>`
- **Container Shell**: `podman exec -it <service> /bin/bash`

## Notes

- Original Docker Compose configs in `/opt/stacks` are preserved
- Can run both systems in parallel for testing
- NixOS containers are managed by systemd
- All services restart automatically on boot
- GPU support requires NVIDIA drivers installed
