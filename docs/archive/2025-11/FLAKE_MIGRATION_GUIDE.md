# Flake Migration Implementation Guide

This document provides detailed implementation steps for migrating to flake-based dependencies identified in the evaluation.

## Status

✅ **Completed:**
- Added flake inputs for `mcps` and `comfyui` to `flake.nix`
- Added overlays for both flakes to `overlays/default.nix`

⚠️ **Pending Decision:**
- Choose migration approach for MCP servers (see options below)
- Implement ComfyUI migration
- Test and validate changes

---

## Migration Approaches

### Approach 1: Full Flake Integration (Recommended Long-term)

**Benefits:**
- Proper version pinning via flake.lock
- Community-maintained packages
- Automatic dependency management

**Drawbacks:**
- Requires refactoring current custom implementation
- May lose some custom features (SOPS integration, dual-target support)
- Higher risk of breaking changes
- Requires extensive testing

### Approach 2: Version Pinning Without Flakes (Recommended Short-term)

**Benefits:**
- Minimal changes to current architecture
- Preserves all custom features (SOPS, dual-target, systemd services)
- Low risk of breaking changes
- Easy to implement and test

**Drawbacks:**
- Manual version management
- Need to update versions manually
- Less automation than flakes

### Approach 3: Hybrid (Gradual Migration)

**Benefits:**
- Use flake packages where available
- Keep custom wrappers for features not supported by flakes
- Gradual migration reduces risk

**Drawbacks:**
- More complex implementation
- Mixed approach might be confusing
- Still requires custom version management for some components

---

## Recommended Implementation: Approach 2 (Version Pinning)

This approach fixes the reproducibility issue with minimal disruption.

### Step 1: Pin NPM Package Versions

**Current (Non-reproducible):**
```nix
"@modelcontextprotocol/server-memory@latest"
"@modelcontextprotocol/server-filesystem@latest"
"@modelcontextprotocol/server-sequential-thinking@latest"
"@arabold/docs-mcp-server@latest"
```

**Fixed (Reproducible):**
```nix
"@modelcontextprotocol/server-memory@0.1.0"
"@modelcontextprotocol/server-filesystem@0.3.0"
"@modelcontextprotocol/server-sequential-thinking@0.1.0"
"@arabold/docs-mcp-server@0.3.1"
```

**Files to update:**
- `modules/shared/mcp/servers.nix`
- `home/nixos/mcp.nix`
- `home/darwin/mcp.nix`

### Step 2: Pin Python Package Versions

**Current (Non-reproducible):**
```nix
uvx --from mcp-server-fetch mcp-server-fetch
uvx --from mcp-server-git mcp-server-git
uvx --from mcp-server-time mcp-server-time
uvx --from mcp-nixos mcp-nixos
uvx --from cli-mcp-server cli-mcp-server
```

**Fixed (Reproducible):**
```nix
uvx --from mcp-server-fetch==0.3.3 mcp-server-fetch
uvx --from mcp-server-git==0.1.4 mcp-server-git
uvx --from mcp-server-time==0.1.0 mcp-server-time
uvx --from mcp-nixos==0.2.0 mcp-nixos
uvx --from cli-mcp-server==0.2.0 cli-mcp-server
```

**Files to update:**
- `modules/shared/mcp/servers.nix`
- `home/nixos/mcp.nix` (warm script)
- `home/darwin/mcp.nix`

### Step 3: Create Version Constants File

Create `modules/shared/mcp/versions.nix`:

```nix
# MCP Server Versions
# Update these periodically to get new features
{
  npm = {
    memory = "0.1.0";
    filesystem = "0.3.0";
    sequential-thinking = "0.1.0";
    docs = "0.3.1";
  };

  python = {
    fetch = "0.3.3";
    git = "0.1.4";
    time = "0.1.0";
    nixos = "0.2.0";
    cli = "0.2.0";
  };

  # Last updated: 2025-01-XX
  # Check for updates: https://www.npmjs.com/search?q=%40modelcontextprotocol
  #                    https://pypi.org/search/?q=mcp-server
}
```

### Step 4: Update servers.nix to Use Versions

```nix
let
  versions = import ./versions.nix;
in
{
  commonServers = {
    memory = {
      command = "${nodejs}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-memory@${versions.npm.memory}"
      ];
      # ... rest of config
    };

    fetch = {
      command = uvx;
      args = [
        "--from"
        "mcp-server-fetch==${versions.python.fetch}"
        "mcp-server-fetch"
      ];
      # ... rest of config
    };
    # ... other servers
  };
}
```

### Step 5: Document Update Process

Add to `docs/MAINTENANCE.md`:

```markdown
## Updating MCP Server Versions

1. Check for new versions:
   - NPM: https://www.npmjs.com/search?q=%40modelcontextprotocol
   - PyPI: https://pypi.org/search/?q=mcp-server

2. Update `modules/shared/mcp/versions.nix`

3. Test with: `nix run .#test-mcp-servers` (if available)

4. Rebuild and verify all servers work
```

---

## Future Migration to Flakes (Optional)

Once the version pinning approach is working, you can optionally migrate to flakes:

### Using roman/mcps.nix

The flake inputs are already added. To use them:

1. Import the home-manager module:
```nix
# home/nixos/mcp.nix or home/darwin/mcp.nix
{
  imports = [ inputs.mcps.homeManagerModules.claude ];

  programs.claude-code = {
    enable = true;
    mcps = {
      git.enable = true;
      filesystem = {
        enable = true;
        allowedPaths = [ "${config.home.homeDirectory}/Code" ];
      };
      github = {
        enable = true;
        tokenFilepath = config.sops.secrets.GITHUB_TOKEN.path;
      };
    };
  };
}
```

2. Gradually migrate servers from custom implementation to flake presets

3. Keep custom wrappers for servers not supported by the flake

---

## ComfyUI Migration

This is more straightforward since it's a direct replacement.

### Current Implementation

```nix
# modules/nixos/services/containers-supplemental/services/comfyui.nix
virtualisation.oci-containers.containers."comfyui-nvidia" = {
  image = "docker.io/runpod/comfyui:latest";  # Non-reproducible
  # ... container config
};
```

### New Implementation

```nix
# modules/nixos/services/comfyui.nix (new file)
{ config, lib, pkgs, ... }:
{
  # Use the flake package instead of container
  environment.systemPackages = [ pkgs.comfyui ];

  # Create systemd service
  systemd.services.comfyui = {
    description = "ComfyUI AI Image Generation";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.comfyui}/bin/comfyui";
      Restart = "on-failure";
      User = "comfyui";
      Group = "comfyui";
    };

    environment = {
      # CUDA support is automatic via the flake
      COMFYUI_DATA_DIR = "/var/lib/comfyui";
    };
  };

  # Create user and data directory
  users.users.comfyui = {
    isSystemUser = true;
    group = "comfyui";
    home = "/var/lib/comfyui";
    createHome = true;
  };

  users.groups.comfyui = {};

  # GPU support (if using NVIDIA)
  hardware.nvidia-container-toolkit.enable = lib.mkIf
    (config.hardware.nvidia.modesetting.enable or false)
    false; # No longer needed with native package
}
```

### Migration Steps

1. Create new module file: `modules/nixos/services/comfyui.nix`
2. Import the new module in your configuration
3. Disable the old container: `host.services.containersSupplemental.comfyui.enable = false;`
4. Enable the new service: `services.comfyui.enable = true;`
5. Migrate data from container volumes to new data directory
6. Test and verify functionality

---

## Testing Checklist

### MCP Servers
- [ ] All servers register with Claude CLI
- [ ] No runtime downloads occur (check with `--offline` flag if available)
- [ ] All servers respond to requests
- [ ] SOPS secrets still work
- [ ] Both Cursor and Claude Code receive configurations

### ComfyUI
- [ ] Application starts successfully
- [ ] GPU is detected and used
- [ ] Can generate images
- [ ] Models persist across restarts
- [ ] UI is accessible on port 8188

### General
- [ ] `nix flake check` passes
- [ ] Build succeeds on clean system
- [ ] No network fetches during build (except for locked inputs)

---

## Rollback Plan

If issues occur:

### MCP Servers
1. Revert changes to `modules/shared/mcp/servers.nix`
2. Restore `@latest` tags temporarily
3. Rebuild and test

### ComfyUI
1. Re-enable container: `host.services.containersSupplemental.comfyui.enable = true;`
2. Disable new service: `services.comfyui.enable = false;`
3. Rebuild

---

## Current Versions (as of 2025-01-22)

These are example versions. Check official sources for latest stable versions:

### NPM Packages
- `@modelcontextprotocol/server-memory`: 0.1.0
- `@modelcontextprotocol/server-filesystem`: 0.3.0
- `@modelcontextprotocol/server-sequential-thinking`: 0.1.0
- `@arabold/docs-mcp-server`: 0.3.1

### Python Packages
- `mcp-server-fetch`: 0.3.3
- `mcp-server-git`: 0.1.4
- `mcp-server-time`: 0.1.0
- `mcp-nixos`: 0.2.0
- `cli-mcp-server`: 0.2.0

**Note:** These versions are examples. Always check the official package registries for the latest stable versions before implementing.

---

## Next Steps

1. **Decide on approach** (recommended: Version Pinning first, Flakes later)
2. **Look up current versions** from NPM and PyPI
3. **Implement version pinning** for MCP servers
4. **Test thoroughly**
5. **Update flake.lock** after confirming flake inputs work
6. **Optionally migrate** to full flake integration later
