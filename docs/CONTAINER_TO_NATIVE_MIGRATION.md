# Container to Native Module Migration

This document tracks the migration from OCI containers to native NixOS modules.

## Completed Migrations

### ? Ollama (AI LLM Backend)

**Status**: Migrated to `services.ollama`

**Before**: Container in `modules/nixos/services/containers/productivity.nix`

```nix
virtualisation.oci-containers.containers.ollama = {
  image = "ollama/ollama:0.1.48";
  # ... container config
};
```

**After**: Native module via `modules/nixos/services/ai-tools/ollama.nix`

```nix
services.ollama = {
  enable = true;
  acceleration = "cuda";  # or "rocm" or null
  models = [ "llama2" ];
};
```

**Configuration**: Use `host.features.aiTools.ollama` in host config
**Benefits**:

- Better integration with NixOS
- Automatic systemd service management
- Native GPU acceleration support
- No container overhead

### ? Open WebUI (LLM Interface)

**Status**: Migrated to `services.open-webui`

**Before**: Container in `modules/nixos/services/containers/productivity.nix`

```nix
virtualisation.oci-containers.containers.openwebui = {
  image = "ghcr.io/open-webui/open-webui:0.3.13-cuda";
  # ... container config
};
```

**After**: Native module via `modules/nixos/services/ai-tools/open-webui.nix`

```nix
services.open-webui = {
  enable = true;
  package = pkgs.open-webui;
  port = 7000;
  host = "0.0.0.0";
  openFirewall = true;
  stateDir = "/var/lib/open-webui";
  environmentFile = null;  # For secrets
};
```

**Configuration**: Use `host.features.aiTools.openWebui` in host config
**Benefits**:

- All native `services.open-webui` options available
- Better firewall integration
- Native secret management via environmentFile
- No container overhead

## Potential Migrations

### ?? PostgreSQL (Cal.com Database)

**Status**: Could be migrated, but complex

**Current**: Container in `modules/nixos/services/containers-supplemental/services/calcom.nix`

```nix
virtualisation.oci-containers.containers."calcom-db" = {
  image = "docker.io/library/postgres:16.3-alpine";
  # ... specific to Cal.com
};
```

**Native Alternative**: `services.postgresql`

```nix
services.postgresql = {
  enable = true;
  package = pkgs.postgresql_16;
  ensureDatabases = [ "calcom" ];
  ensureUsers = [{
    name = "calcom";
    ensureDBOwnership = true;
  }];
};
```

**Complexity**: High - Would require refactoring Cal.com to use Unix socket or TCP connection to native PostgreSQL
**Recommendation**: Leave as-is for now, as it's tightly coupled to Cal.com container

## No Native Modules Available

The following services do **not** have native NixOS modules and should remain as containers:

- **ComfyUI** (`comfyui-nvidia`) - AI image generation
- **Cup** - Container management UI
- **Homarr** - Dashboard
- **Wizarr** - Invitation system
- **Jellystat** - Jellyfin statistics
- **Janitorr** - Media cleanup
- **Profilarr** - Profile management
- **Doplarr** - Discord bot
- **Termix** - Terminal multiplexer
- **Cal.com** - Scheduling platform (main app)

## Migration Checklist

When considering migration from container to native module:

1. ? Check if native NixOS module exists in nixpkgs
2. ? Verify feature parity between container and native module
3. ? Plan data migration (container volumes ? native state dirs)
4. ? Update host configuration
5. ? Test service functionality
6. ? Remove old container configuration
7. ? Clean up orphaned container volumes

## Data Migration Notes

### Ollama

- Container data: `${configPath}/ollama:/data/.ollama`
- Native data: `/var/lib/ollama`
- Migration: Copy model files to new location or re-download

### Open WebUI

- Container data: `${configPath}/openwebui:/app/backend/data`
- Native data: `/var/lib/open-webui` (configurable via `stateDir`)
- Migration: Copy user data, settings, and chats to new location

## See Also

- [AI Tools Documentation](./modules/nixos/services/ai-tools/README.md)
- [Features Guide](./FEATURES.md)
