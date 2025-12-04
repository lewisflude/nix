# MCP Architecture Documentation

**Enterprise-Grade Model Context Protocol Configuration**

This document describes the comprehensive, production-ready MCP (Model Context Protocol) architecture implemented across this Nix configuration.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Configuration Files](#configuration-files)
- [Server Management](#server-management)
- [Health Monitoring](#health-monitoring)
- [Adding New Servers](#adding-new-servers)
- [Troubleshooting](#troubleshooting)
- [Platform Differences](#platform-differences)

---

## Overview

### What is MCP?

Model Context Protocol (MCP) is a standardized protocol for AI assistants to access external tools, data sources, and services. This configuration provides:

- **Centralized Management**: All MCP servers defined in one place
- **Cross-Platform Support**: Works on both NixOS (Linux) and nix-darwin (macOS)
- **Security**: SOPS integration for secret management
- **Reliability**: Health checks, monitoring, and automatic recovery
- **Maintainability**: Clean architecture with minimal code duplication

### Design Principles

1. **Single Source of Truth**: Shared wrappers module used by both platforms
2. **Feature Flags**: Enable/disable servers without code changes
3. **Graceful Degradation**: Disabled servers provide clear error messages
4. **Observable**: Health checks, logs, and status monitoring
5. **Developer Experience**: Clear documentation, helpful error messages

---

## Architecture

### High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    MCP Architecture                          │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────┐         ┌──────────────────┐          │
│  │  Target Apps    │         │  Health Checks   │          │
│  │  - Cursor       │         │  - Wrapper --hc  │          │
│  │  - Claude Code  │         │  - Systemd Timer │          │
│  └────────┬────────┘         │  - LaunchAgent   │          │
│           │                  └──────────────────┘          │
│           v                                                 │
│  ┌─────────────────────────────────────────┐               │
│  │   services.mcp (Config Generator)       │               │
│  │   - Generates JSON configs              │               │
│  │   - Deploys to target directories       │               │
│  └────────┬────────────────────────────────┘               │
│           │                                                 │
│           v                                                 │
│  ┌─────────────────────────────────────────┐               │
│  │   Platform-Specific MCP Modules         │               │
│  │   - home/darwin/mcp.nix                 │               │
│  │   - home/nixos/mcp.nix                  │               │
│  └────────┬────────────────────────────────┘               │
│           │                                                 │
│           v                                                 │
│  ┌─────────────────────────────────────────┐               │
│  │   Shared Wrappers Module                │               │
│  │   modules/shared/mcp/wrappers.nix       │               │
│  │   - Builder Pattern                     │               │
│  │   - Secret Injection                    │               │
│  │   - Health Checks                       │               │
│  └────────┬────────────────────────────────┘               │
│           │                                                 │
│           v                                                 │
│  ┌─────────────────────────────────────────┐               │
│  │   MCP Servers (Runtime)                 │               │
│  │   - Memory (npx)                        │               │
│  │   - Docs (npx + SOPS)                   │               │
│  │   - OpenAI (npx + SOPS)                 │               │
│  │   - Rustdocs (Nix + SOPS)               │               │
│  └─────────────────────────────────────────┘               │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Module Hierarchy

1. **`modules/shared/mcp/wrappers.nix`**: Core wrapper builders
   - Platform-agnostic
   - Exports builder functions (`mkSecretWrapper`, `mkNpxWrapper`, etc.)
   - Exports pre-built wrappers (`memoryWrapper`, `docsMcpWrapper`, etc.)

2. **`home/darwin/mcp.nix`**: Darwin-specific configuration
   - Server definitions with feature flags
   - LaunchAgent for health checks
   - Configuration deployment to `~/Library/Application Support/Claude/`

3. **`home/nixos/mcp.nix`**: NixOS-specific configuration
   - Server definitions with feature flags (identical structure to Darwin)
   - Systemd services and timers
   - Configuration deployment to `~/.config/claude/`

4. **`home/common/modules/mcp.nix`**: Common configuration generator
   - `services.mcp` module definition
   - JSON generation
   - Target application configuration
   - Port conflict validation

---

## Configuration Files

### Wrapper Module (`modules/shared/mcp/wrappers.nix`)

**Purpose**: Provides secure wrapper scripts for MCP servers

**Key Components**:

#### Builder Functions

1. **`mkSecretWrapper`** - For servers requiring SOPS secrets
   ```nix
   mkSecretWrapper {
     name = "my-server-wrapper";
     secretName = "MY_API_KEY";
     command = ''exec ${pkgs.nodejs}/bin/npx my-server "$@"'';
     extraEnv = { OPTIONAL_VAR = "value"; };
     healthCheck = ''test -n "$MY_API_KEY"'';
   }
   ```

2. **`mkSimpleWrapper`** - For public servers (no secrets)
   ```nix
   mkSimpleWrapper {
     name = "my-server-wrapper";
     command = ''exec ${pkgs.nodejs}/bin/npx my-server "$@"'';
     env = { VAR = "value"; };
   }
   ```

3. **`mkDisabledWrapper`** - For unavailable servers
   ```nix
   mkDisabledWrapper {
     name = "my-server-wrapper";
     reason = "Requires uv package which is unavailable";
     suggestion = "Wait for upstream fix or contribute alternative";
   }
   ```

4. **`mkNpxWrapper`** - Specialized for Node.js/npx servers
   ```nix
   mkNpxWrapper {
     name = "my-server-wrapper";
     package = "@scope/my-server@1.0.0";
     secretName = "MY_API_KEY";  # optional
   }
   ```

#### Pre-Built Wrappers

- **`memoryWrapper`**: Knowledge graph-based persistent memory
- **`docsMcpWrapper`**: Documentation indexing (requires OPENAI_API_KEY)
- **`openaiWrapper`**: OpenAI integration (requires OPENAI_API_KEY)
- **`rustdocsWrapper`**: Rust documentation (requires OPENAI_API_KEY)
- **`kagiWrapper`**: Disabled (requires uv)
- **`nixosWrapper`**: Disabled (requires uv)

### Platform Configurations

#### Darwin (`home/darwin/mcp.nix`)

**Structure**:
```nix
{
  # Port key mapping
  portKeys = {
    memory = "memory";
    "docs-mcp-server" = "docs";
    # ...
  };

  # Server definitions
  servers = {
    memory = {
      enabled = true;
      available = true;
      wrapper = wrappers.memoryWrapper;
      portKey = portKeys.memory;
      config = { command = "..."; args = []; port = 6221; };
    };
    # ...
  };

  # Health check script
  healthCheckScript = pkgs.writeShellScript "mcp-health-check" ''...'';

  # LaunchAgent for periodic health checks
  launchd.agents.mcp-health-check = { ... };
}
```

#### NixOS (`home/nixos/mcp.nix`)

**Structure**: Identical to Darwin, but with:
- Uses `systemConfig` (same as Darwin for consistency)
- Systemd services instead of LaunchAgents
- Systemd timers for periodic health checks
- HTTP service for docs-mcp-server

---

## Server Management

### Active Servers

#### Memory Server
- **Purpose**: Knowledge graph-based persistent memory
- **Runtime**: Node.js via npx
- **Dependencies**: `nodejs`
- **Secrets**: None
- **Port**: 6221

#### Documentation Server (docs-mcp-server)
- **Purpose**: Documentation indexing and search
- **Runtime**: Node.js via npx
- **Dependencies**: `nodejs`, `OPENAI_API_KEY` (SOPS)
- **Secrets**: `OPENAI_API_KEY`
- **Port**: 6280
- **HTTP Mode** (NixOS only): Accessible at `http://localhost:6280`

#### OpenAI Server
- **Purpose**: General OpenAI integration with Rust docs support
- **Runtime**: Node.js via npx
- **Dependencies**: `nodejs`, `OPENAI_API_KEY` (SOPS)
- **Secrets**: `OPENAI_API_KEY`
- **Port**: 6250

#### Rust Documentation Server
- **Purpose**: Bevy crate documentation
- **Runtime**: Nix-built binary
- **Dependencies**: `nix`, `OPENAI_API_KEY` (SOPS), Rust build tools
- **Secrets**: `OPENAI_API_KEY`
- **Port**: 6270
- **Platform Support**: Linux and Darwin (platform-aware build dependencies)

### Disabled Servers

#### Kagi Server
- **Status**: Disabled
- **Reason**: Requires `uv` package (currently failing to build in nixpkgs)
- **Port**: 6240
- **Re-enable**: When uv build is fixed upstream

#### NixOS Server
- **Status**: Disabled
- **Reason**: Requires `uv` package (currently failing to build in nixpkgs)
- **Port**: 6265
- **Re-enable**: When uv build is fixed upstream

---

## Health Monitoring

### Health Check System

Every MCP server wrapper includes a `--health-check` flag for validation:

```bash
# Run health check for a specific server
~/bin/memory-mcp-wrapper --health-check

# Run all health checks
~/bin/mcp-health-check
```

### Health Check Script

**Location**: `~/bin/mcp-health-check`

**Features**:
- Tests all active servers
- Reports pass/fail for each
- Returns exit code 1 if any server is unhealthy
- Logs to:
  - Darwin: `~/Library/Logs/mcp-health-check.log`
  - NixOS: `journalctl --user -u mcp-health-check.service`

### Automated Monitoring

#### Darwin (LaunchAgent)

**Service**: `~/Library/LaunchAgents/org.nixos.mcp-health-check.plist`

**Schedule**:
- Every 6 hours after login
- Logs to `~/Library/Logs/mcp-health-check.log`

**Commands**:
```bash
# Check status
launchctl list | grep mcp-health-check

# View logs
tail -f ~/Library/Logs/mcp-health-check.log

# Manually trigger
launchctl start org.nixos.mcp-health-check
```

#### NixOS (Systemd)

**Service**: `mcp-health-check.service`
**Timer**: `mcp-health-check.timer`

**Schedule**:
- 5 minutes after boot
- Every 6 hours thereafter

**Commands**:
```bash
# Check timer status
systemctl --user status mcp-health-check.timer

# Check service status
systemctl --user status mcp-health-check.service

# View logs
journalctl --user -u mcp-health-check.service -f

# Manually trigger
systemctl --user start mcp-health-check.service
```

---

## Adding New Servers

### Step 1: Create Wrapper

Add to `modules/shared/mcp/wrappers.nix`:

```nix
myServerWrapper = mkNpxWrapper {
  name = "my-server-wrapper";
  package = "@scope/my-server@1.0.0";
  secretName = "MY_API_KEY";  # optional
  healthCheck = ''
    # Add health check logic
    if [ -z "''${MY_API_KEY:-}" ]; then
      ${logError "MY_API_KEY not set"}
      exit 1
    fi
    exit 0
  '';
};
```

### Step 2: Add Port Constant

Add to `lib/constants.nix`:

```nix
ports = {
  mcp = {
    # ... existing ports ...
    myServer = 6290;  # Choose unused port in 6200-6299 range
  };
};
```

### Step 3: Add Server Definition

Add to both `home/darwin/mcp.nix` and `home/nixos/mcp.nix`:

```nix
# In portKeys
portKeys = {
  # ... existing keys ...
  "my-server" = "myServer";
};

# In servers
servers = {
  # ... existing servers ...
  "my-server" = {
    enabled = true;
    available = systemConfig.sops.secrets ? MY_API_KEY;  # or osConfig on NixOS
    wrapper = wrappers.myServerWrapper;
    portKey = portKeys."my-server";
    config = {
      command = "${wrappers.myServerWrapper}/bin/my-server-wrapper";
      args = [ ];
      port = constants.ports.mcp.myServer;
    };
  };
};
```

### Step 4: Add Secret (if needed)

If your server requires secrets, add to SOPS configuration:

```nix
# In your host's SOPS config
sops.secrets.MY_API_KEY = {
  sopsFile = ../secrets/secrets.yaml;
  mode = "0400";
};
```

### Step 5: Rebuild

```bash
# Darwin
darwin-rebuild switch --flake .#hostname

# NixOS
sudo nixos-rebuild switch --flake .#hostname
```

---

## Troubleshooting

### MCP Servers Not Appearing

**Symptoms**: `claude mcp list` shows no servers

**Solutions**:

1. **Check Configuration Files**:
   ```bash
   # Darwin
   cat ~/Library/Application\ Support/Claude/claude_desktop_config.json

   # NixOS
   cat ~/.config/claude/claude_desktop_config.json
   ```

2. **Verify Permissions**:
   ```bash
   # Should be readable
   ls -l ~/Library/Application\ Support/Claude/claude_desktop_config.json
   ```

3. **Check Activation Logs**:
   ```bash
   # Look for MCP-related errors during home-manager activation
   home-manager switch --flake .#hostname
   ```

### Server Health Check Fails

**Symptoms**: `~/bin/mcp-health-check` reports unhealthy servers

**Solutions**:

1. **Run Individual Health Check**:
   ```bash
   # Test specific wrapper
   ~/bin/docs-mcp-wrapper --health-check
   ```

2. **Check Secret Availability**:
   ```bash
   # Darwin
   sudo cat /run/secrets/OPENAI_API_KEY

   # NixOS
   sudo cat /run/secrets/OPENAI_API_KEY
   ```

3. **Verify Dependencies**:
   ```bash
   # Check if nodejs is available
   which npx
   node --version
   ```

### Secrets Not Loading

**Symptoms**: Wrapper fails with "Cannot read secret" error

**Solutions**:

1. **Verify SOPS Setup**:
   ```bash
   # Check secret exists
   sops -d secrets/secrets.yaml | grep OPENAI_API_KEY
   ```

2. **Check File Permissions**:
   ```bash
   # Secret should be readable by user
   ls -l /run/secrets/OPENAI_API_KEY
   ```

3. **Ensure SOPS Configuration**:
   ```nix
   # In systemConfig or osConfig
   sops.secrets.OPENAI_API_KEY = {
     sopsFile = ../secrets/secrets.yaml;
     mode = "0400";
   };
   ```

### Build Failures

**Symptoms**: `nix build` fails with MCP-related errors

**Solutions**:

1. **Check for Platform Issues**:
   ```bash
   # Ensure no Linux-only packages on Darwin
   nix build .#darwinConfigurations.mercury.system --show-trace
   ```

2. **Verify Port Uniqueness**:
   ```bash
   # Check lib/constants.nix for duplicate ports
   grep -E "= [0-9]+;" lib/constants.nix | sort
   ```

3. **Test Individual Components**:
   ```bash
   # Test wrapper module
   nix-instantiate --eval --strict -E '
     let pkgs = import <nixpkgs> {};
         lib = pkgs.lib;
         systemConfig = { sops.secrets.OPENAI_API_KEY.path = "/fake"; };
         wrappers = import ./modules/shared/mcp/wrappers.nix { inherit pkgs lib systemConfig; };
     in wrappers.memoryWrapper
   '
   ```

---

## Platform Differences

### Darwin-Specific

**Configuration Directory**: `~/Library/Application Support/Claude/`

**Service Management**: LaunchAgents
- Located in `~/Library/LaunchAgents/`
- Managed via `launchctl`

**Health Checks**:
- LaunchAgent runs every 6 hours
- Logs to `~/Library/Logs/mcp-health-check.log`

### NixOS-Specific

**Configuration Directory**: `~/.config/claude/`

**Service Management**: Systemd
- User services in `~/.config/systemd/user/`
- Managed via `systemctl --user`

**Health Checks**:
- Systemd timer runs every 6 hours
- Logs to systemd journal

**HTTP Services**:
- docs-mcp-server runs in HTTP mode
- Accessible at `http://localhost:6280`

### Cross-Platform Considerations

**Rust Documentation Server**:
- Platform-aware build dependencies
- Linux: includes `alsa-lib`, `systemd`
- Darwin: excludes Linux-specific libraries
- `mv` command differs: `-T` flag on Linux, not on Darwin

**Wrapper Scripts**:
- All use `writeShellApplication` for proper PATH
- ShellCheck validation ensures compatibility
- Explicit package references (no implicit PATH dependencies)

---

## Summary

This MCP architecture provides:

- ✅ **Centralized Management**: All servers defined in one module
- ✅ **Cross-Platform**: Works on Darwin and NixOS with platform-specific optimizations
- ✅ **Secure**: SOPS integration for secrets, no secrets in Nix store
- ✅ **Reliable**: Health checks, monitoring, graceful degradation
- ✅ **Maintainable**: Clean code, minimal duplication, clear documentation
- ✅ **Observable**: Logs, status reports, health monitoring
- ✅ **Extensible**: Easy to add new servers following established patterns

For questions or issues, refer to:
- **General MCP**: https://github.com/modelcontextprotocol
- **This Config**: `docs/CLAUDE.md` and `CONTRIBUTING.md`
- **SOPS**: `docs/SOPS_GUIDE.md`
