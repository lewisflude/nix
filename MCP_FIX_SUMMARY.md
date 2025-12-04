# MCP Module Fix Summary

## Issue
The MCP modules for NixOS and nix-darwin had inconsistent parameter naming, causing configuration evaluation to fail when accessing system configuration for secrets.

## Root Cause
- **NixOS MCP module** (`home/nixos/mcp.nix`) was using `osConfig` as the parameter name
- **System builders** (`lib/system-builders.nix`) pass `systemConfig` to home-manager extraSpecialArgs
- **Darwin MCP module** (`home/darwin/mcp.nix`) was already using `systemConfig` (correct)

This inconsistency prevented the NixOS MCP module from accessing SOPS secrets via `systemConfig.sops.secrets`.

## Changes Made

### 1. Fixed NixOS MCP Module (`home/nixos/mcp.nix`)

**Changed parameter from `osConfig` to `systemConfig`:**
```diff
 {
   pkgs,
   config,
   lib,
   constants,
-  osConfig,
+  systemConfig,
   ...
 }:
```

**Updated wrappers import:**
```diff
 wrappers = import ../../modules/shared/mcp/wrappers.nix {
-    inherit pkgs lib;
-    systemConfig = osConfig;
+    inherit pkgs lib systemConfig;
 };
```

**Updated all references from `osConfig` to `systemConfig`:**
- `osConfig.sops.secrets ? OPENAI_API_KEY` → `systemConfig.sops.secrets ? OPENAI_API_KEY`
- Applied to: docs-mcp-server, openai, and rustdocs servers

### 2. Standardized Darwin MCP Module (`home/darwin/mcp.nix`)

**Reordered parameters for consistency (cosmetic):**
```diff
 {
   pkgs,
   config,
-  systemConfig,
   lib,
   system,
   constants,
+  systemConfig,
   ...
 }:
```

### 3. Updated Documentation (`docs/MCP_ARCHITECTURE.md`)

Added clarification that NixOS uses `systemConfig` (same as Darwin):
```diff
 #### NixOS (`home/nixos/mcp.nix`)
 
 **Structure**: Identical to Darwin, but with:
+- Uses `systemConfig` (same as Darwin for consistency)
 - Systemd services instead of LaunchAgents
 - Systemd timers for periodic health checks
 - HTTP service for docs-mcp-server
```

## Validation

All configurations now evaluate successfully:

### Darwin (mercury)
```bash
$ nix eval '.#darwinConfigurations.mercury.config.home-manager.users.lewisflude.services.mcp.enable'
true

$ nix eval '.#darwinConfigurations.mercury.config.home-manager.users.lewisflude.services.mcp.servers' --json
{
  "docs-mcp-server": {...},
  "memory": {...},
  "openai": {...},
  "rustdocs": {...}
}

$ nix eval '.#darwinConfigurations.mercury.config.home-manager.users.lewisflude.services.mcp.targets' --json
{
  "claude": {
    "directory": "/Users/lewisflude/Library/Application Support/Claude",
    "fileName": "claude_desktop_config.json"
  },
  "cursor": {
    "directory": "/Users/lewisflude/.cursor",
    "fileName": "mcp.json"
  }
}
```

### NixOS (jupiter)
```bash
$ nix eval '.#nixosConfigurations.jupiter.config.home-manager.users.lewis.services.mcp.enable'
true

$ nix eval '.#nixosConfigurations.jupiter.config.home-manager.users.lewis.services.mcp.servers' --json
{
  "docs-mcp-server": {...},
  "memory": {...},
  "openai": {...},
  "rustdocs": {...}
}

$ nix eval '.#nixosConfigurations.jupiter.config.home-manager.users.lewis.services.mcp.targets' --json
{
  "claude-code": {
    "directory": "/home/lewis/.config/claude",
    "fileName": "claude_desktop_config.json"
  },
  "cursor": {
    "directory": "/home/lewis/.cursor",
    "fileName": "mcp.json"
  }
}
```

## MCP Servers Configuration

All active MCP servers are now properly configured on both platforms:

1. **memory** - Knowledge graph-based persistent memory (port 6221)
   - No secrets required
   - Node.js via npx

2. **docs-mcp-server** - Documentation indexing (port 6280)
   - Requires: OPENAI_API_KEY (via SOPS)
   - Node.js via npx

3. **openai** - General OpenAI integration (port 6250)
   - Requires: OPENAI_API_KEY (via SOPS)
   - Node.js via npx

4. **rustdocs** - Rust documentation for Bevy (port 6270)
   - Requires: OPENAI_API_KEY (via SOPS)
   - Built via Nix

### Disabled Servers
- **kagi** - Awaiting uv package fix
- **nixos** - Awaiting uv package fix

## Benefits

1. **Consistency**: Both platforms now use the same parameter name (`systemConfig`)
2. **Maintainability**: Easier to understand and maintain cross-platform code
3. **Correctness**: SOPS secret access now works correctly on both platforms
4. **Documentation**: Updated docs reflect the correct architecture

## Testing

Run the following to test your configuration:

```bash
# Test Darwin build
nix build '.#darwinConfigurations.mercury.system'

# Test NixOS build
nix build '.#nixosConfigurations.jupiter.config.system.build.toplevel'

# Test flake checks
nix flake check
```

## Next Steps

1. Review and test the changes
2. Run `darwin-rebuild switch` (Darwin) or `nh os switch` (NixOS)
3. Verify MCP servers are working: `~/bin/mcp-health-check`
4. Check configuration files:
   - Darwin: `~/.cursor/mcp.json` and `~/Library/Application Support/Claude/claude_desktop_config.json`
   - NixOS: `~/.cursor/mcp.json` and `~/.config/claude/claude_desktop_config.json`
