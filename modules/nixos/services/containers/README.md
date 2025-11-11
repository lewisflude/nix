# Container Services Module

This module provides declarative Podman-based container management for NixOS.

## Features

- **Productivity Stack**: Ollama, Open WebUI, ComfyUI for AI/LLM workloads
- **GPU Support**: Native NVIDIA GPU passthrough for AI containers
- **Secrets Management**: Integration with sops-nix for API keys and passwords

> **Note**: Media management services (Radarr, Sonarr, etc.) are now provided via native NixOS services in `modules/nixos/services/media-management/`. See that module's README for details.

## Quick Start

### Enable in Host Configuration

In your host configuration (e.g., `hosts/jupiter/default.nix`), add:

```nix
{
  features = {
    containers = {
      enable = true;
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
  productivity = {
    enable = true;
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

## Networking

Productivity containers typically use:

- **host**: Direct host networking for GPU-enabled services (Ollama)
- **bridge**: Default network for web services

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

To disable the stack, set `enable = false`:

```nix
host.features.containers = {
  enable = true;
  productivity.enable = false;  # Disable productivity stack
};
```

## Notes

- First run may take time to pull all container images
- GPU containers require NVIDIA drivers and container toolkit
- Config paths should be persistent and backed up
- For media management services, see `modules/nixos/services/media-management/`
