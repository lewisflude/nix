# MCP Server Fix Summary

## Problem

Multiple MCP servers were failing with "Connection closed" errors:

```
Error (unhandledRejection): MCP error -32000: Connection closed
```

## Root Cause

The MCP configuration had **all servers enabled by default**, including those requiring:

1. **API keys/secrets** that weren't configured (OPENAI_API_KEY, GITHUB_TOKEN, KAGI_API_KEY, etc.)
2. **External dependencies** not available (uvx for kagi server)

When Cursor tried to start these servers:

- Wrapper scripts checked for secrets at `/run/secrets-for-users/`
- Secrets didn't exist, so scripts exited with code 1
- This caused the "Connection closed" error

## Solution

Changed MCP configuration to **only enable servers that work without configuration**:

### Enabled by Default (No Secrets Required)

✅ **memory** - Knowledge graph-based persistent memory
✅ **git** - Git repository operations
✅ **time** - Timezone and datetime utilities
✅ **sqlite** - SQLite database access
✅ **everything** - MCP reference/test server

### Disabled by Default (Require Configuration)

❌ **docs** - Requires OPENAI_API_KEY
❌ **openai** - Requires OPENAI_API_KEY
❌ **rustdocs** - Requires OPENAI_API_KEY
❌ **github** - Requires GITHUB_TOKEN
❌ **kagi** - Requires KAGI_API_KEY and uvx
❌ **brave** - Requires BRAVE_API_KEY
❌ **filesystem** - Disabled for security
❌ **sequentialthinking** - Optional
❌ **fetch** - Optional
❌ **nixos** - Requires uvx

## Changes Made

### 1. Updated `home/common/modules/mcp.nix`

- Reorganized default servers to clearly separate enabled/disabled
- Added `.enabled = false` to all servers requiring secrets
- Updated documentation and comments
- Added clear instructions for enabling servers with secrets

### 2. Updated Platform-Specific Configs

**`home/nixos/mcp.nix`** and **`home/darwin/mcp.nix`**:

- Documented which servers are enabled by default
- Added examples showing how to enable servers with secrets
- Included step-by-step instructions for secret configuration

### 3. Updated Documentation

**`CLAUDE.md`**:

- Updated MCP server list to reflect new defaults
- Added section on enabling servers with secrets
- Documented the 4-step process for adding new secrets

## How to Enable Servers with Secrets

If you want to enable servers that require API keys:

### Step 1: Add Secret to SOPS

Edit `secrets/secrets.yaml`:

```yaml
OPENAI_API_KEY: ENC[AES256_GCM,data:...,type:str]
GITHUB_TOKEN: ENC[AES256_GCM,data:...,type:str]
```

### Step 2: Configure Secret for Users

In `modules/shared/sops.nix`:

```nix
sops.secrets = {
  "OPENAI_API_KEY" = {
    neededForUsers = true;
    allowUserRead = true;
  };
};
```

### Step 3: Enable Server

In `home/nixos/mcp.nix` or `home/darwin/mcp.nix`:

```nix
services.mcp.servers = {
  docs.enabled = true;      # Uses OPENAI_API_KEY
  openai.enabled = true;    # Uses OPENAI_API_KEY
  github.enabled = true;    # Uses GITHUB_TOKEN
};
```

### Step 4: Rebuild

```bash
# NixOS
nh os switch

# nix-darwin
darwin-rebuild switch
```

After rebuild, secrets will be available at `/run/secrets-for-users/`.

## Testing

To verify the fix works:

```bash
# Check generated MCP config
cat ~/.cursor/mcp.json | jq '.mcpServers | keys'

# Should only show enabled servers:
# ["everything", "git", "memory", "sqlite", "time"]
```

## Benefits

1. ✅ **Works out of the box** - No configuration required for basic functionality
2. ✅ **No more crashes** - Only stable servers are enabled by default
3. ✅ **Clear opt-in** - Servers with requirements are explicitly disabled
4. ✅ **Better documentation** - Clear instructions for enabling additional servers
5. ✅ **Cross-platform** - Works on both NixOS and nix-darwin

## Related Files

- `home/common/modules/mcp.nix` - Main MCP module
- `home/nixos/mcp.nix` - NixOS-specific overrides
- `home/darwin/mcp.nix` - macOS-specific overrides
- `CLAUDE.md` - Updated documentation
- `docs/MCP_ARCHITECTURE.md` - Detailed architecture docs
