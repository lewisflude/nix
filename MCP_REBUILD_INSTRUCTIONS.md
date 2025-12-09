# MCP Server Fix - Rebuild Instructions

## What Was Fixed

All MCP servers requiring secrets or external dependencies have been **disabled by default** to prevent "Connection closed" errors.

## Files Modified

✅ `home/common/modules/mcp.nix` - Main MCP module (disabled servers requiring secrets)
✅ `home/nixos/mcp.nix` - NixOS config (updated documentation)
✅ `home/darwin/mcp.nix` - macOS config (updated documentation)
✅ `CLAUDE.md` - Updated documentation
✅ `MCP_FIX_SUMMARY.md` - Detailed explanation
✅ `scripts/test-mcp-config.sh` - Test script to verify configuration

## What Changed

### Before (All Servers Enabled)

```
Enabled servers:
  • docs (requires OPENAI_API_KEY) ❌ CRASHES
  • openai (requires OPENAI_API_KEY) ❌ CRASHES
  • rustdocs (requires OPENAI_API_KEY) ❌ CRASHES
  • github (requires GITHUB_TOKEN) ❌ CRASHES
  • kagi (requires KAGI_API_KEY) ❌ CRASHES
  • memory ✅
  • git ✅
  • time ✅
  • sqlite ✅
  • everything ✅
  • filesystem ✅
  • sequentialthinking ✅
```

### After (Only Stable Servers Enabled)

```
Enabled servers:
  • memory ✅ (works out of the box)
  • git ✅ (works out of the box)
  • time ✅ (works out of the box)
  • sqlite ✅ (works out of the box)
  • everything ✅ (works out of the box)
```

## How to Apply the Fix

### Option 1: Quick Rebuild (Recommended)

```bash
# NixOS
nh os switch

# OR nix-darwin
darwin-rebuild switch
```

### Option 2: Test First

```bash
# Build without applying
nh os build

# If successful, apply
nh os switch
```

### Option 3: Home Manager Only

```bash
# If you only want to update home-manager
home-manager switch
```

## Verify the Fix

After rebuilding, run the test script:

```bash
./scripts/test-mcp-config.sh
```

Expected output:

```
✅ All tests passed!

MCP servers are correctly configured:
  • Only servers without secrets are enabled
  • All server commands are valid
```

Or manually check:

```bash
# View enabled servers
cat ~/.cursor/mcp.json | jq '.mcpServers | keys'

# Should output:
# ["everything", "git", "memory", "sqlite", "time"]
```

## After Rebuild

1. **Restart Cursor** to pick up the new configuration
2. **No more connection errors** from missing secrets
3. **MCP tools work** (memory, git, time, sqlite, everything)

## Enabling Additional Servers

If you want to enable servers that require secrets:

### Example: Enable GitHub MCP

1. **Add secret to SOPS** (if not already present):

   ```bash
   # Edit secrets/secrets.yaml
   sops secrets/secrets.yaml

   # Add:
   GITHUB_TOKEN: ghp_your_token_here
   ```

2. **Enable in platform config**:

   ```nix
   # home/nixos/mcp.nix or home/darwin/mcp.nix
   services.mcp.servers = {
     github.enabled = true;
   };
   ```

3. **Rebuild**:

   ```bash
   nh os switch
   ```

4. **Verify**:

   ```bash
   # Check secret exists
   ls -la /run/secrets-for-users/GITHUB_TOKEN

   # Test MCP config
   ./scripts/test-mcp-config.sh
   ```

## Troubleshooting

### If Servers Still Crash After Rebuild

1. **Check the config was applied**:

   ```bash
   cat ~/.cursor/mcp.json | jq '.mcpServers | keys'
   ```

2. **Restart Cursor completely**:

   ```bash
   killall cursor-agent
   # Then restart Cursor
   ```

3. **Check for old process**:

   ```bash
   ps aux | grep mcp
   # Kill any hanging MCP processes
   ```

### If You Need a Server That's Disabled

See `MCP_FIX_SUMMARY.md` for step-by-step instructions on enabling servers with secrets.

## What's Next

After the rebuild, you should have:

- ✅ No more "Connection closed" errors
- ✅ Working MCP tools (git, memory, time, sqlite, everything)
- ✅ Clear documentation on enabling additional servers
- ✅ A test script to verify configuration

The MCP servers that work out of the box are already very powerful:

- **memory**: Persistent knowledge graph for the AI
- **git**: Full Git repository operations
- **time**: Timezone and datetime utilities
- **sqlite**: Database access for data storage
- **everything**: Reference server with all MCP features

Enable additional servers (docs, openai, github, kagi) only if you need them and have the required API keys.
