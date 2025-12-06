# MCP Server Cleanup Guide

This guide helps you clean up orphaned MCP server registrations that point to old, garbage-collected Nix store paths.

## Problem

When you see `claude mcp list` output like:

```
fetch: /nix/store/old-hash-uv/bin/uvx - ✗ Failed to connect
general-filesystem: /nix/store/old-hash-nodejs/bin/npx - ✗ Failed to connect
```

These are **orphaned registrations** not managed by your Nix configuration.

## Why This Happens

- Manual server additions using `claude mcp add`
- Old configurations from previous Nix generations
- Nix garbage collection removing referenced store paths
- Testing servers that were never removed

## Cleanup Steps

### 1. List All Registered Servers

```bash
claude mcp list
```

### 2. Identify Orphaned Servers

Orphaned servers are those:

- ✗ Showing "Failed to connect"
- Using old `/nix/store/...` paths
- **NOT** listed in your Nix config files

Check which servers are Nix-managed:

```bash
# View Nix-managed servers (NixOS)
cat ~/.config/claude/claude_desktop_config.json | jq '.mcpServers | keys'

# View Nix-managed servers (Cursor)
cat ~/.cursor/mcp.json | jq '.mcpServers | keys'
```

### 3. Remove Orphaned Servers

For each orphaned server:

```bash
claude mcp remove <server-name>
```

**Example:**

```bash
claude mcp remove fetch
claude mcp remove general-filesystem
claude mcp remove sequential-thinking
claude mcp remove time
```

### 4. Verify Cleanup

```bash
claude mcp list
```

Only Nix-managed servers should remain.

## Currently Managed Servers (NixOS)

Your Nix configuration manages these servers:

- **memory** - Knowledge graph-based persistent memory (no secrets)
- **docs-mcp-server** - Documentation indexing (requires OPENAI_API_KEY)
- **openai** - OpenAI integration (requires OPENAI_API_KEY)
- **rustdocs** - Rust documentation (requires OPENAI_API_KEY)
- **kagi** - Search and summarization (requires KAGI_API_KEY)
- **nixos** - NixOS package search (no secrets)

## Adding New Servers

**Don't manually add servers with `claude mcp add`!** Instead:

1. Add to `modules/shared/mcp/wrappers.nix`
2. Add port to `lib/constants.nix`
3. Enable in `home/nixos/mcp.nix`
4. Rebuild: `nh os switch` or `sudo nixos-rebuild switch`

See `docs/MCP_ARCHITECTURE.md` for detailed instructions.

## Preventing Future Orphans

**Best Practices:**

1. **Always use Nix config** for MCP servers
2. **Never use** `claude mcp add` directly
3. **Test servers** before adding to Nix config
4. **Remove test servers** after testing:

   ```bash
   claude mcp remove test-server-name
   ```

## Troubleshooting

### Server still fails after cleanup

1. **Check secret availability:**

   ```bash
   sudo ls -l /run/secrets/OPENAI_API_KEY
   ```

2. **Run health check:**

   ```bash
   ~/bin/mcp-health-check
   ```

3. **Check wrapper:**

   ```bash
   /nix/store/.../docs-mcp-wrapper/bin/docs-mcp-wrapper --health-check
   ```

### Can't remove server

If `claude mcp remove` doesn't work, the server might be in Claude's config file:

```bash
# Edit directly (backup first!)
cp ~/.config/claude/claude_desktop_config.json{,.backup}
# Manually remove the server entry from the JSON
```

## Related Documentation

- **Architecture**: `docs/MCP_ARCHITECTURE.md`
- **Adding Servers**: `docs/MCP_ARCHITECTURE.md#adding-new-servers`
- **SOPS Secrets**: `docs/SOPS_GUIDE.md`
