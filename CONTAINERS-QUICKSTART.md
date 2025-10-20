# Container Services - Quick Start Guide

✅ **Status**: Your NixOS container configuration is ready to use!

## 🚀 How to Enable

### Step 1: Update Your Host Configuration

Edit `hosts/jupiter/default.nix` and add this to your `features` section:

```nix
features = {
  # ... your existing features ...
  
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
```

### Step 2: Rebuild Your System

```bash
cd ~/.config/nix
sudo nixos-rebuild switch --flake .#jupiter
```

This will:
- Install and configure Podman
- Create all container services
- Start them automatically
- Set up systemd units for management

### Step 3: Verify Everything is Running

```bash
# Check container services status
systemctl list-units 'podman-*' | grep running

# View running containers
podman ps

# Check a specific service
systemctl status podman-radarr

# View logs
journalctl -u podman-radarr -f
```

## 📋 What Gets Enabled

### Media Management (19 containers)
- **Radarr** → http://jupiter:7878 (Movies)
- **Sonarr** → http://jupiter:8989 (TV Shows)
- **Lidarr** → http://jupiter:8686 (Music)
- **Prowlarr** → http://jupiter:9696 (Indexer Manager)
- **Whisparr** → http://jupiter:6969 (Adult Content)
- **Readarr** → http://jupiter:8787 (Books)
- **qBittorrent** → http://jupiter:8080 (Torrents)
- **SABnzbd** → http://jupiter:8082 (Usenet)
- **Jellyfin** → http://jupiter:8096 (Media Server)
- **Jellyseerr** → http://jupiter:5055 (Requests)
- **Homarr** → http://jupiter:7575 (Dashboard)
- Plus: FlareSolverr, Unpackerr, Janitorr, Recommendarr, Autopulse, Kapowarr, Doplarr, Wizarr

### Productivity (4 containers)
- **Ollama** → host network (LLM Backend with GPU)
- **Open WebUI** → http://jupiter:7000 (LLM Chat Interface)
- **ComfyUI** → http://jupiter:8188 (AI Image Generation)
- **CUP** → http://jupiter:1188 (Container Updates)

## 🔧 Common Commands

```bash
# View all container services
systemctl list-units 'podman-*'

# Restart a specific service
sudo systemctl restart podman-radarr

# Stop a service
sudo systemctl stop podman-radarr

# Check logs in real-time
journalctl -u podman-radarr -f

# View last 50 log lines
journalctl -u podman-radarr -n 50

# List containers with Podman
podman ps -a

# See container stats
podman stats

# Enter a container
podman exec -it radarr /bin/bash
```

## 🎛️ Configuration Paths

All container configurations are stored in:
- **Media**: `/var/lib/containers/media-management/<service>/`
- **Productivity**: `/var/lib/containers/productivity/<service>/`
- **Media Data**: `/mnt/storage/` (your existing path)

## 🔐 Next Steps (Optional)

### 1. Set Up Secrets Management

If you want to use sops-nix for API keys:

```nix
# In hosts/jupiter/default.nix or a secrets file
sops.secrets = {
  "containers/sonarr_api_key" = {
    owner = "root";
    mode = "0400";
  };
  "containers/radarr_api_key" = {
    owner = "root";
    mode = "0400";
  };
};
```

### 2. Customize Settings

```nix
# Override defaults
host.services.containers = {
  timezone = "America/New_York";  # Different timezone
  uid = 1001;  # Different user ID
  gid = 101;   # Different group ID
};
```

### 3. Disable Specific Stacks

```nix
containers = {
  enable = true;
  mediaManagement.enable = true;
  productivity.enable = false;  # Disable if you don't need AI tools
};
```

## ⚠️ Before You Start

### Migration from Docker Compose

If you're currently running Docker Compose in `/opt/stacks`:

1. **Backup your data** (optional but recommended):
   ```bash
   ./scripts/containers/migrate-to-nix.sh
   ```

2. **Stop Docker Compose**:
   ```bash
   cd /opt/stacks/media-management && docker compose down
   cd /opt/stacks/productivity && docker compose down
   ```

3. **Then enable in NixOS** as shown above

### Fresh Install

If this is a fresh setup:
- Just enable the features and rebuild
- First run will pull all container images (takes 5-10 minutes)
- Configure services through their web interfaces

## 📊 Resource Usage

Expected resource usage with all services:
- **RAM**: ~4-6 GB total
- **CPU**: Minimal when idle, moderate during downloads
- **Disk**: ~20 GB for container images
- **Storage**: Your media files in `/mnt/storage`

## 🐛 Troubleshooting

### Service won't start
```bash
systemctl status podman-radarr
journalctl -u podman-radarr -n 50
```

### Permission errors
```bash
sudo chown -R 1000:100 /var/lib/containers/media-management/radarr
```

### Network issues
```bash
podman network ls
systemctl restart podman-network-media
```

### GPU not working (productivity stack)
```bash
nvidia-smi
nvidia-container-cli info
```

## 📚 Full Documentation

- **Complete Guide**: `docs/CONTAINERS-SETUP.md`
- **Migration Guide**: `modules/nixos/services/containers/MIGRATION.md`
- **Module Reference**: `modules/nixos/services/containers/README.md`

## ✨ Summary

Your Docker Compose configurations have been converted to:
- ✅ Declarative NixOS modules
- ✅ Podman (rootless, more secure)
- ✅ Systemd-managed services
- ✅ Same ports and functionality
- ✅ GPU support for AI tools
- ✅ Easy rollback capability

Just add the configuration to your host file and rebuild! 🎉
