# NixOS Container Services - Complete Setup Guide

This document provides a complete overview of the NixOS container services conversion from Docker Compose.

## 📋 What Was Created

### Core Modules

1. **`modules/nixos/services/containers/default.nix`**
   - Main module entry point
   - Enables Podman with Docker compatibility
   - Manages common configuration (UID, GID, timezone)
   - Creates necessary directories

2. **`modules/nixos/services/containers/media-management.nix`**
   - 19 containerized services for media management
   - Arr apps (Radarr, Sonarr, Lidarr, Prowlarr, etc.)
   - Download clients (qBittorrent, SABnzbd)
   - Media server (Jellyfin)
   - Supporting tools and dashboards

3. **`modules/nixos/services/containers/productivity.nix`**
   - AI/LLM tools (Ollama, Open WebUI)
   - Image generation (ComfyUI)
   - GPU-enabled containers
   - Container update proxy

4. **`modules/nixos/services/containers/secrets.nix`**
   - Secrets management structure
   - sops-nix integration ready
   - API key and password handling

5. **`modules/nixos/features/containers.nix`**
   - Feature-level configuration bridge
   - Enables Podman automatically
   - Maps host features to container services

### Documentation

- **`modules/nixos/services/containers/README.md`** - User guide and reference
- **`modules/nixos/services/containers/MIGRATION.md`** - Detailed migration steps
- **`modules/nixos/services/containers/SUMMARY.md`** - Technical summary

### Helper Files

- **`hosts/jupiter/containers-example.nix`** - Example configuration
- **`scripts/containers/migrate-to-nix.sh`** - Migration helper script

## 🚀 Quick Start

### Option 1: Using the Migration Script

```bash
# Run the migration helper
./scripts/containers/migrate-to-nix.sh

# Follow the prompts to backup and stop Docker Compose
```

### Option 2: Manual Setup

1. **Enable containers in your host configuration**

Edit `hosts/jupiter/default.nix`:

```nix
{
  features = {
    # ... existing features ...
    
    containers = {
      enable = true;
      
      mediaManagement = {
        enable = true;
        dataPath = "/mnt/storage";
        configPath = "/var/lib/containers/media-management";
      };
      
      productivity = {
        enable = true;
        configPath = "/var/lib/containers/productivity";
      };
    };
  };
}
```

2. **Rebuild your system**

```bash
cd ~/.config/nix
sudo nixos-rebuild switch --flake .#jupiter
```

3. **Verify services are running**

```bash
# List all container services
systemctl list-units 'podman-*' --all

# Check specific service
systemctl status podman-radarr

# View running containers
podman ps
```

## 📊 Service Overview

### Media Management Stack

| Service | Port | Purpose |
|---------|------|---------|
| **Prowlarr** | 9696 | Indexer manager |
| **Radarr** | 7878 | Movies |
| **Sonarr** | 8989 | TV Shows |
| **Lidarr** | 8686 | Music |
| **Whisparr** | 6969 | Adult content |
| **Readarr** | 8787 | Books/eBooks |
| **qBittorrent** | 8080 | Torrent downloads |
| **SABnzbd** | 8082 | Usenet downloads |
| **Jellyfin** | 8096 | Media streaming |
| **Jellyseerr** | 5055 | Media requests |
| **Homarr** | 7575 | Dashboard |
| **FlareSolverr** | 8191 | Cloudflare bypass |
| + 7 more support services |

### Productivity Stack

| Service | Port | Purpose |
|---------|------|---------|
| **Ollama** | host | LLM backend (GPU) |
| **Open WebUI** | 7000 | LLM chat interface (GPU) |
| **ComfyUI** | 8188 | AI image generation (GPU) |
| **CUP** | 1188 | Container updates |

## 🔧 Configuration Options

### Basic Configuration

```nix
host.features.containers = {
  enable = true;  # Enable container services
  
  mediaManagement = {
    enable = true;
    dataPath = "/mnt/storage";  # Media files location
    configPath = "/var/lib/containers/media-management";  # App configs
  };
  
  productivity = {
    enable = true;
    configPath = "/var/lib/containers/productivity";
  };
};
```

### Advanced Options

```nix
host.services.containers = {
  # Customize common settings
  timezone = "America/New_York";  # Override timezone
  uid = 1000;  # User ID for containers
  gid = 100;   # Group ID for containers
};
```

## 🔐 Secrets Management

### Setting Up Secrets

1. **Add secrets to `secrets/secrets.yaml`:**

```yaml
containers:
  sonarr_api_key: "your-api-key-here"
  radarr_api_key: "your-api-key-here"
  discord_token: "your-discord-token"
```

2. **Encrypt with sops:**

```bash
cd secrets
sops -e -i secrets.yaml
```

3. **Configure in host:**

```nix
sops.secrets = {
  "containers/sonarr_api_key" = {
    owner = "root";
    mode = "0400";
  };
};
```

## 📡 Network Architecture

```
┌─────────────────────────────────────────┐
│          Host (Jupiter)                 │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │   Media Network (podman)          │ │
│  │  - Radarr, Sonarr, Prowlarr       │ │
│  │  - qBittorrent, SABnzbd           │ │
│  │  - Internal communication         │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │   Frontend Network (podman)       │ │
│  │  - Jellyfin, Jellyseerr           │ │
│  │  - Homarr, Wizarr                 │ │
│  │  - External access                │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │   Host Network                    │ │
│  │  - Ollama (GPU access)            │ │
│  │  - Direct host networking         │ │
│  └───────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

## 🛠️ Common Operations

### View Service Status

```bash
# All container services
systemctl status 'podman-*'

# Specific service
systemctl status podman-radarr

# Service logs
journalctl -u podman-radarr -f
```

### Restart Services

```bash
# Restart specific service
sudo systemctl restart podman-radarr

# Restart all containers (careful!)
sudo systemctl restart 'podman-*'
```

### Update Containers

```bash
# Update system (includes container images)
sudo nixos-rebuild switch --flake .#jupiter --refresh

# Check for updates via CUP
curl http://localhost:1188/api/updates
```

### Inspect Containers

```bash
# List running containers
podman ps

# Container stats
podman stats

# Enter container shell
podman exec -it radarr /bin/bash

# View container logs
podman logs radarr
```

### Network Management

```bash
# List networks
podman network ls

# Inspect network
podman network inspect media

# Test connectivity
podman exec radarr ping sonarr
```

## 🐛 Troubleshooting

### Service Won't Start

```bash
# Check service status
systemctl status podman-radarr

# View full logs
journalctl -u podman-radarr -n 100

# Check if image pulled
podman images | grep radarr

# Manually pull image
podman pull ghcr.io/hotio/radarr:latest
```

### Permission Errors

```bash
# Check directory ownership
ls -la /var/lib/containers/media-management/

# Fix permissions
sudo chown -R 1000:100 /var/lib/containers/media-management/radarr
```

### Network Issues

```bash
# Recreate networks
sudo systemctl restart podman-network-media
sudo systemctl restart podman-network-frontend

# Check network connectivity
podman exec radarr curl http://prowlarr:9696
```

### GPU Not Working

```bash
# Check NVIDIA support
nvidia-smi

# Verify container toolkit
nvidia-container-cli info

# Test GPU in container
podman run --rm --device nvidia.com/gpu=all nvidia/cuda:12.0-base nvidia-smi
```

## 🔄 Migration from Docker Compose

See detailed guide: `modules/nixos/services/containers/MIGRATION.md`

**Quick migration:**

1. Backup: `./scripts/containers/migrate-to-nix.sh`
2. Stop Docker Compose stacks
3. Enable containers in host config
4. Rebuild NixOS
5. Verify services running

## 📚 Additional Resources

- **Main Documentation**: `modules/nixos/services/containers/README.md`
- **Migration Guide**: `modules/nixos/services/containers/MIGRATION.md`
- **Technical Summary**: `modules/nixos/services/containers/SUMMARY.md`
- **Example Config**: `hosts/jupiter/containers-example.nix`

## ✅ Benefits

### Over Docker Compose

- ✅ **Declarative**: All configuration in version control
- ✅ **Reproducible**: Same config = same result
- ✅ **Atomic**: Rollback-able updates
- ✅ **Integrated**: Native systemd management
- ✅ **Secure**: Rootless containers by default
- ✅ **Dependencies**: Automatic service ordering

### Additional Features

- ✅ GPU support for AI workloads
- ✅ Secrets management with sops-nix
- ✅ Resource limits and health checks
- ✅ Automatic restarts and monitoring
- ✅ Network isolation
- ✅ Easy backup and restore

## 🎯 Next Steps

1. **Test in stages**: Enable media stack first, then productivity
2. **Configure secrets**: Set up sops-nix for API keys
3. **Monitor logs**: Check for any errors or warnings
4. **Update services**: Test container updates
5. **Set up backups**: Include `/var/lib/containers` in backups
6. **Optional cleanup**: Remove old Docker setup once verified

## 💡 Tips

- Start with just one stack enabled to test
- Use `podman ps` to quickly check container status
- Service names match container names (e.g., `podman-radarr`)
- Logs are in journald: `journalctl -u podman-<service>`
- All ports are the same as Docker Compose setup
- Data in `/mnt/storage` remains unchanged

## 🆘 Getting Help

If you encounter issues:

1. Check service logs: `journalctl -u podman-<service> -n 50`
2. Verify configuration: Review the module files
3. Test individual services: Enable one at a time
4. Check documentation: See README.md and MIGRATION.md
5. Inspect containers: `podman inspect <service>`

---

**Status**: Ready to use! All modules are configured and tested.
**Compatibility**: NixOS 23.11+
**Podman Version**: Managed by NixOS
