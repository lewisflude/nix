# Native Productivity Services

This module provides declarative configuration for AI-powered productivity tools using native NixOS services.

## Services Included

- **Ollama** - Local LLM backend for running language models
- **Open WebUI** - Modern web interface for interacting with LLMs

## Usage

### Basic Configuration

```nix
{
  host.services.productivity = {
    enable = true;
    
    ollama = {
      enable = true;
      acceleration = "cuda"; # or "rocm" or null
      models = ["llama2" "mistral"];
    };
    
    openWebui = {
      enable = true;
      port = 7000;
    };
  };
}
```

### CPU-Only Mode

```nix
{
  host.services.productivity = {
    enable = true;
    
    ollama = {
      enable = true;
      acceleration = null; # CPU-only
      models = ["llama2:7b"]; # Use smaller models
    };
  };
}
```

### NVIDIA GPU Acceleration

```nix
{
  host.services.productivity = {
    enable = true;
    
    ollama = {
      enable = true;
      acceleration = "cuda";
      models = [
        "llama2"
        "codellama"
        "mistral"
      ];
    };
  };
}
```

Ensure NVIDIA drivers are enabled:
```nix
{
  hardware.nvidia.modesetting.enable = true;
  services.xserver.videoDrivers = ["nvidia"];
}
```

### AMD GPU Acceleration

```nix
{
  host.services.productivity = {
    enable = true;
    
    ollama = {
      enable = true;
      acceleration = "rocm";
    };
  };
}
```

## Service Details

### Ollama

**Port**: 11434 (localhost only)  
**State Directory**: `/var/lib/ollama`  
**User**: `productivity` (configurable)

Ollama runs as a background service and provides an API for LLM inference.

**Environment Variables**:
- `OLLAMA_KEEP_ALIVE=24h` - Keep models in memory for 24 hours

**API Endpoint**: `http://127.0.0.1:11434`

### Open WebUI

**Port**: 7000 (configurable)  
**State Directory**: `/var/lib/open-webui`  
**User**: `productivity` (configurable)

Open WebUI provides a ChatGPT-like interface for interacting with Ollama.

**Features**:
- Chat interface
- Model management
- Conversation history
- User authentication
- Multiple users support

**Access**: `http://localhost:7000`

## Model Management

### Pre-download Models

Models specified in the config are automatically downloaded on first boot:

```nix
{
  host.services.productivity.ollama.models = [
    "llama2"          # Latest Llama 2
    "llama2:13b"      # Specific size
    "codellama"       # Code-focused model
    "mistral"         # Mistral 7B
    "neural-chat"     # Conversation model
  ];
}
```

### Manual Model Management

```bash
# List available models
ollama list

# Pull a new model
ollama pull llama2

# Remove a model
ollama rm llama2

# Run a model directly
ollama run llama2
```

## GPU Support

### NVIDIA (CUDA)

Requirements:
- NVIDIA GPU with compute capability 3.5+
- Proprietary NVIDIA drivers enabled
- `cuda` acceleration mode

The module automatically enables `hardware.nvidia-container-toolkit` when using CUDA.

### AMD (ROCm)

Requirements:
- AMD GPU with ROCm support
- ROCm drivers installed
- `rocm` acceleration mode

Check compatibility: https://rocm.docs.amd.com/en/latest/release/gpu_os_support.html

### CPU-Only

Set `acceleration = null` to use CPU inference. Recommended for:
- Systems without compatible GPUs
- Testing and development
- Small models (7B parameters or less)

**Note**: CPU inference is significantly slower than GPU.

## Networking

### Internal Communication

Ollama listens on `127.0.0.1:11434` (localhost only) for security.

Open WebUI connects to Ollama via the configured URL (default: `http://127.0.0.1:11434`).

### External Access

Open WebUI listens on `0.0.0.0:7000` and is accessible from the network. The firewall port is automatically opened.

To restrict access:
```nix
{
  host.services.productivity.openWebui.enable = true;
  
  # Override to localhost only
  systemd.services.open-webui.environment.WEBUI_HOST = "127.0.0.1";
  
  # Disable automatic firewall rule
  networking.firewall.allowedTCPPorts = mkForce [];
}
```

Then use a reverse proxy (nginx, caddy) for authentication and TLS.

## Directory Structure

```
/var/lib/
├── ollama/              # Ollama state and models
│   ├── models/          # Downloaded models
│   └── ...
└── open-webui/          # Open WebUI state
    └── ...
```

## Performance Tuning

### Model Size Selection

| Model | Parameters | VRAM | Use Case |
|-------|-----------|------|----------|
| llama2:7b | 7B | ~6GB | General chat, fast responses |
| llama2:13b | 13B | ~12GB | Better quality, slower |
| codellama:7b | 7B | ~6GB | Code generation |
| mistral | 7B | ~6GB | Efficient general purpose |

### Context Length

Larger context = more memory usage:
```bash
ollama run llama2 --context-length 4096
```

### Concurrent Requests

Ollama handles one request at a time by default. For multiple users, consider:
- Using smaller models
- Increasing `OLLAMA_MAX_LOADED_MODELS`
- Running multiple Ollama instances

## Troubleshooting

### Check Service Status
```bash
systemctl status ollama
systemctl status open-webui
```

### View Logs
```bash
sudo journalctl -u ollama -f
sudo journalctl -u open-webui -f
```

### Test Ollama API
```bash
curl http://localhost:11434/api/tags
```

### GPU Not Detected
```bash
# Check NVIDIA GPU
nvidia-smi

# Check Ollama GPU detection
journalctl -u ollama | grep -i gpu
```

### Model Download Issues
```bash
# Check disk space
df -h /var/lib/ollama

# Manually download model
sudo -u productivity ollama pull llama2
```

### Performance Issues
- Reduce model size (use 7B instead of 13B)
- Lower context length
- Enable GPU acceleration
- Check CPU/GPU temperature and throttling

## Comparison: Containers vs Native

| Aspect | Containers | Native Modules |
|--------|-----------|----------------|
| GPU setup | Complex device passthrough | Automatic |
| Updates | Manual image pulls | `nixos-rebuild` |
| Configuration | ENV vars in compose | Nix options |
| State | Container volumes | `/var/lib/` |
| Networking | Port mapping | Direct ports |
| Integration | Separate from system | System users/groups |

## Migration from Containers

1. Stop container services:
   ```bash
   sudo systemctl stop podman-ollama
   sudo systemctl stop podman-openwebui
   ```

2. (Optional) Migrate data:
   ```bash
   # Ollama models
   sudo cp -r /var/lib/containers/productivity/ollama/* /var/lib/ollama/
   sudo chown -R productivity:productivity /var/lib/ollama
   ```

3. Enable native services:
   ```nix
   host.services.productivity.enable = true;
   ```

4. Rebuild:
   ```bash
   sudo nixos-rebuild switch
   ```

## See Also

- [Ollama Documentation](https://ollama.ai/docs)
- [Open WebUI GitHub](https://github.com/open-webui/open-webui)
- [NixOS Ollama Options](https://search.nixos.org/options?query=services.ollama)
- [Migration Guide](../../../../docs/NATIVE-SERVICES-MIGRATION.md)
