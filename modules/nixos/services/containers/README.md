# Container Services Module

This module provides declarative Podman-based container management for NixOS, converting Docker Compose configurations to native NixOS container services.

## Features

- **Media Management Stack**: Radarr, Sonarr, Lidarr, Whisparr, Prowlarr, Jellyfin, and related services
- **Productivity Stack**: Ollama, Open WebUI, ComfyUI for AI/LLM workloads
- **GPU Support**: Native NVIDIA GPU passthrough for AI containers
- **Network Isolation**: Separate networks for media, frontend, and internal services
- **Secrets Management**: Integration with sops-nix for API keys and passwords

## Quick Start

### Enable in Host Configuration

In your host configuration (e.g., `hosts/jupiter/default.nix`), add:

```nix
{
  features = {
    containers = {
      enable = true;
      mediaManagement = {
        enable = true;
        dataPath = "/mnt/storage";  # Your media storage path
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

### Rebuild System

```bash
sudo nixos-rebuild switch --flake .#jupiter
```

## Configuration

### Media Management Stack

The media stack includes:

- **Indexers**: Prowlarr, FlareSolverr
- **Download Managers**: Radarr, Sonarr, Lidarr, Whisparr, Readarr
- **Downloaders**: qBittorrent, SABnzbd
- **Media Server**: Jellyfin
- **Request Management**: Jellyseerr
- **Tools**: Unpackerr, Homarr, Wizarr, Janitorr, Recommendarr

See [`docs/reference/janitorr.md`](../../docs/reference/janitorr.md) for a detailed Janitorr feature and setup guide.
The module renders `application.yml` via `sops-nix` and expects the `janitorr-*` secrets described in that guide.

**Ports exposed:**
- Prowlarr: 9696
- Radarr: 7878
- Sonarr: 8989
- Lidarr: 8686
- Whisparr: 6969
- Readarr: 8787
- qBittorrent: 8080
- SABnzbd: 8082
- Jellyfin: 8096
- Jellyseerr: 5055
- Homarr: 7575

### Productivity Stack

The productivity stack includes:

- **Ollama**: LLM backend (host network)
- **Open WebUI**: Web interface (port 7000)
- **ComfyUI**: AI image generation (port 8188)
- **CUP**: Container update proxy (port 1188)

**GPU Requirements:**
- NVIDIA GPU with Container Toolkit enabled
- CDI (Container Device Interface) support

## Advanced Configuration

### Custom Paths

```nix
host.features.containers = {
  enable = true;
  mediaManagement = {
    enable = true;
    dataPath = "/custom/media/path";
    configPath = "/custom/config/path";
  };
};
```

### Secrets Management

1. Add secrets to `secrets/secrets.yaml`:

```yaml
containers:
  sonarr_api_key: ENC[AES256_GCM,...]
  radarr_api_key: ENC[AES256_GCM,...]
  discord_token: ENC[AES256_GCM,...]
```

2. Configure secrets in your host:

```nix
sops.secrets = {
  "containers/sonarr_api_key" = {
    owner = "root";
    mode = "0400";
  };
};
```

## Migration from Docker Compose

This module replaces the Docker Compose configurations in `/opt/stacks`. The conversion maintains:

- Same container images
- Same volume mappings
- Same network architecture
- Same environment variables

**Benefits over Docker Compose:**
- Declarative configuration
- Automatic dependency management
- System-level integration
- Better resource control
- Atomic updates

## Networking

The module creates three Podman networks:

1. **media**: Internal communication between media services
2. **frontend**: External access for web interfaces
3. **host**: Direct host networking for GPU-enabled services

## Troubleshooting

### Check container status

```bash
systemctl status podman-<container-name>
```

### View container logs

```bash
journalctl -u podman-<container-name> -f
```

### List running containers

```bash
podman ps
```

### Check networks

```bash
podman network ls
```

### Restart a service

```bash
systemctl restart podman-<container-name>
```

## Disabling Services

To disable the stacks, set `enable = false`:

```nix
host.features.containers = {
  enable = true;
  mediaManagement.enable = false;  # Disable media stack
  productivity.enable = true;       # Keep productivity stack
};
```

## Notes

- First run may take time to pull all container images
- GPU containers require NVIDIA drivers and container toolkit
- Existing Docker Compose data in `/opt/stacks` is preserved
- Config paths should be persistent and backed up
