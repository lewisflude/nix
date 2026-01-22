# Container Services Best Practices

This document outlines best practices for self-hosted containerized services in this Nix configuration.

## Container Runtime: Podman vs Docker

**✅ We use Podman** - Here's why:

### Advantages of Podman

1. **Rootless by default**: Better security isolation for services
2. **Daemonless architecture**: Lower attack surface, no single point of failure
3. **Systemd integration**: Native integration with NixOS service management
4. **Docker compatibility**: Full Docker CLI compatibility via `dockerCompat`
5. **Pod support**: Better orchestration than Docker Compose for complex stacks
6. **Resource efficiency**: No daemon overhead, containers run as child processes

### When Docker Might Be Preferable

- **Legacy compatibility**: Some old images require Docker-specific features
- **Desktop development**: Docker Desktop provides GUI and easier developer experience on macOS/Windows
- **Specific orchestration**: K8s development with Docker-specific tooling

For self-hosted services on NixOS, **Podman is the superior choice**.

## Architecture Principles

### 1. Prefer Native NixOS Services

**Always prefer native NixOS modules over containers when available.**

```nix
# ✅ GOOD - Native NixOS service
services.jellyfin.enable = true;

# ❌ AVOID - Containerized when native exists
virtualisation.oci-containers.containers.jellyfin = { ... };
```

**Benefits:**
- Better NixOS integration (automatic firewall rules, user management)
- Declarative configuration with type checking
- Easier upgrades via `nix flake update`
- Better resource efficiency
- Systemd service management

### 2. Use Containers Only When Necessary

Use OCI containers for:
- Services without native NixOS modules (e.g., Cal.com, Homarr)
- Multi-container applications with tight coupling (e.g., Cal.com + PostgreSQL)
- Services requiring specific runtime environments

```nix
# ✅ GOOD - No native NixOS module exists
virtualisation.oci-containers.containers.homarr = { ... };

# ✅ GOOD - Requires specific runtime environment
virtualisation.oci-containers.containers.comfyui-nvidia = {
  extraOptions = [ "--device=nvidia.com/gpu=all" ];
};
```

### 3. Separate System and Container Configuration

**System-level configuration** (Podman runtime) → `modules/shared/features/virtualisation/`
**Container services** → `modules/nixos/services/containers-supplemental/`

```nix
# In host configuration (hosts/jupiter/default.nix)
features = {
  virtualisation = {
    enable = true;
    podman = true;  # Enables Podman runtime
  };
  containersSupplemental = {
    enable = true;  # Enables container services
    homarr.enable = true;
  };
};
```

## Configuration Best Practices

### Resource Limits

**Always set explicit resource limits** to prevent resource exhaustion:

```nix
virtualisation.oci-containers.containers.myservice = {
  image = "...";
  extraOptions = [
    "--memory=512m"
    "--memory-swap=1g"
    "--cpus=1.0"
  ];
};
```

**Resource sizing guidelines:**
- **Small services** (dashboards, proxies): 256-512MB RAM, 0.25-0.5 CPU
- **Medium services** (databases, APIs): 512MB-2GB RAM, 0.5-2 CPU
- **Large services** (AI/ML, media processing): 8-16GB+ RAM, 4-8+ CPU

### Secrets Management

**Use sops-nix for all secrets** - never hardcode credentials:

```nix
# ✅ GOOD - sops-nix integration
host.services.containersSupplemental.calcom = {
  useSops = true;  # Secrets loaded from sops
  # Credentials automatically injected from secrets/secrets.yaml
};

# ❌ WRONG - Hardcoded secrets
environment = {
  PASSWORD = "hunter2";  # NEVER DO THIS
};
```

### Volume Mounts

**Use explicit paths and permissions:**

```nix
volumes = [
  "${cfg.configPath}/data:/app/data"
  "/mnt/storage/media:/media:ro"  # Read-only when possible
];

systemd.tmpfiles.rules = [
  "d ${cfg.configPath}/data 0755 ${toString cfg.uid} ${toString cfg.gid} -"
];
```

### Network Configuration

**Default to bridge networking**, use host only when necessary:

```nix
# ✅ GOOD - Explicit port mapping
ports = [ "8080:8080" ];

# ⚠️ USE SPARINGLY - Host networking (GPU services, performance-critical)
extraOptions = [ "--network=host" ];
```

### Image Pinning

**Pin images to specific versions** to ensure reproducibility:

```nix
# ✅ GOOD - Pinned version
image = "ghcr.io/ajnart/homarr:0.15.3";

# ❌ AVOID - Floating tag
image = "ghcr.io/ajnart/homarr:latest";
```

## Security Best Practices

### 1. Minimal Privileges

**Avoid root containers when possible:**

```nix
environment = {
  WANTED_UID = toString cfg.uid;  # Run as non-root user
  WANTED_GID = toString cfg.gid;
};
```

### 2. Socket Access

**NEVER expose Podman/Docker socket unless absolutely necessary:**

```nix
# ❌ DANGEROUS - Full container control
volumes = [ "/run/podman/podman.sock:/var/run/docker.sock" ];

# ✅ ALTERNATIVE - Use Podman API with restricted permissions if needed
```

The CUP (Container Update Proxy) service is **disabled by default** because it requires full socket access.

### 3. Network Isolation

**Use VPN namespaces for sensitive traffic:**

```nix
# qBittorrent example
vpn = {
  enable = true;
  namespace = "qbt";  # Isolated network namespace
};
```

### 4. Read-only Mounts

**Mount volumes read-only when data doesn't need to be modified:**

```nix
volumes = [
  "/mnt/storage/media:/media:ro"  # Media consumption only
];
```

## Performance Optimization

### Storage Configuration

**SSD for active data, HDD for archival:**

```nix
# Example: qBittorrent staging
incompleteDownloadPath = "/mnt/nvme/qbittorrent/incomplete";  # SSD
categories = {
  movies = "/mnt/storage/movies";  # HDD for final storage
};
```

### Disk Cache Sizing

**Optimize based on available RAM and workload:**

```nix
diskCacheSize = 512;  # MiB - For 64GB RAM systems
```

### Connection Limits

**Tune based on disk capabilities:**

```nix
maxActiveTorrents = 150;  # Prevent HDD saturation
maxActiveUploads = 75;    # Avoid thrashing during streaming
```

## Monitoring and Maintenance

### Health Checks

**Enable service restart policies:**

```nix
systemd.services.podman-myservice = {
  serviceConfig = {
    Restart = "on-failure";
    RestartSec = "10s";
    StartLimitBurst = 10;
    StartLimitIntervalSec = 600;
  };
};
```

### Logging

**Check service logs:**

```bash
journalctl -u podman-myservice -f
```

### Container Updates

**Regular updates via Nix:**

```bash
nix flake update  # Update flake inputs
# User rebuilds system manually
```

## Common Antipatterns to Avoid

### ❌ WRONG: Duplicating Podman Configuration

```nix
# Don't configure Podman in multiple places
config = mkIf cfg.enable {
  virtualisation.podman.enable = true;  # Already configured elsewhere!
};
```

**✅ CORRECT:** Configure Podman once in `host.features.virtualisation`, reference it in assertions.

### ❌ WRONG: Container for Native Services

```nix
# Don't containerize when native module exists
virtualisation.oci-containers.containers.jellyfin = { ... };
```

**✅ CORRECT:** Use `services.jellyfin.enable = true`

### ❌ WRONG: No Resource Limits

```nix
# This can exhaust system resources
virtualisation.oci-containers.containers.myservice = {
  image = "...";
  # Missing: --memory, --cpus
};
```

**✅ CORRECT:** Always set `--memory` and `--cpus` limits.

### ❌ WRONG: Hardcoded Secrets

```nix
environment = {
  API_KEY = "sk_live_12345";  # NEVER!
};
```

**✅ CORRECT:** Use `sops-nix` or pass secrets via files.

## Migration Path: Container → Native Service

When a native NixOS module becomes available:

1. **Test native service** in parallel (different port)
2. **Export data** from container
3. **Import data** to native service
4. **Verify functionality**
5. **Disable container** and update configuration
6. **Remove container** configuration

Example: Ollama migration from container → native service (already completed in this repo).

## Summary

**For this repository:**
- ✅ **Podman** is the correct container runtime
- ✅ **Native NixOS services** for media management stack
- ✅ **OCI containers** only for services without native modules
- ✅ **Explicit resource limits** on all containers
- ✅ **sops-nix** for secrets management
- ✅ **VPN namespaces** for sensitive traffic
- ✅ **Pinned image versions** for reproducibility

This configuration is already following best practices with minimal over-engineering.
