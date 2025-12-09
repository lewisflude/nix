# MCP Server Troubleshooting Guide

## Issue Resolved: npm Authentication Failures

### Root Cause

MCP servers were failing on macOS because `~/.npmrc` was configured to use AWS CodeArtifact (private npm registry) with an expired authentication token. This caused all `npx` commands used by MCP servers to fail with HTTP 401 errors.

### Solution Applied

1. **Backed up CodeArtifact config**: `~/.npmrc.codeartifact.backup`
2. **Removed global `.npmrc`**: Allows MCP servers to use public npm registry
3. **Created per-project setup**: Script for work projects in `~/Code`

### Current Status

✅ **Working MCP Servers** (no secrets required):
- `everything` - MCP reference/test server
- `filesystem` - File operations
- `git` - Git repository operations  
- `sequentialthinking` - Problem-solving
- `time` - Timezone/datetime utilities

⚠️ **Pending Rebuild** (secrets configured but not deployed):
- `github` - Requires GITHUB_TOKEN from SOPS
- `kagi` - Requires KAGI_API_KEY from SOPS
- `openai` - Requires OPENAI_API_KEY from SOPS
- `docs` - Requires OPENAI_API_KEY from SOPS
- `rustdocs` - Requires OPENAI_API_KEY from SOPS

❌ **Still Investigating**:
- `memory` - Wrapper script issue
- `sqlite` - Wrapper script issue

## Next Steps Required

### 1. Rebuild System to Deploy Secrets

The secrets are configured in SOPS but need to be deployed to `/run/secrets/`:

```bash
# Review changes
git diff

# Rebuild Darwin system (this will deploy secrets)
darwin-rebuild switch --flake ~/.config/nix#mercury

# Or if using nh:
nh os switch
```

After rebuild, these secrets should be available in `/run/secrets/`:
- `/run/secrets/GITHUB_TOKEN`
- `/run/secrets/KAGI_API_KEY`
- `/run/secrets/OPENAI_API_KEY`

### 2. Verify MCP Servers After Rebuild

```bash
# Check deployed secrets
sudo ls -la /run/secrets/

# Test MCP server health
claude mcp list

# Test specific servers
npx -y @cyanheads/github-mcp-server --help
```

### 3. Debug Wrapper Scripts (If Needed)

The `memory` and `sqlite` MCP servers use wrapper scripts that are currently failing. After the rebuild, if they still fail:

```bash
# Test memory wrapper directly
/nix/store/*-memory-mcp-wrapper/bin/memory-mcp-wrapper --help

# Check wrapper script contents
cat /nix/store/*-memory-mcp-wrapper/bin/memory-mcp-wrapper

# Test without wrapper
npx -y @modelcontextprotocol/server-memory --help
```

## CodeArtifact for Work Projects

See `docs/CODEARTIFACT_SETUP.md` for complete details.

### Quick Setup for Work Projects

```bash
cd ~/Code/your-project
~/.config/nix/scripts/setup-codeartifact-project.sh
```

### Your Work Projects

Projects in `~/Code` that may need CodeArtifact:
- `kyoso-backend`
- `kyoso-frontend`
- `kyoso-world`
- `project-service`
- `terraform`
- `user-management-service`

## Configuration Files Updated

1. **`home/darwin/mcp.nix`** - Enabled GitHub, Kagi, and OpenAI MCP servers
2. **`scripts/setup-codeartifact-project.sh`** - New script for work projects
3. **`docs/CODEARTIFACT_SETUP.md`** - Complete CodeArtifact documentation
4. **`docs/MCP_TROUBLESHOOTING.md`** - This file

## Verification Commands

### Check npm Configuration

```bash
# Should be empty or not exist
cat ~/.npmrc 2>/dev/null || echo "No global .npmrc (correct)"

# Backup should exist
ls -la ~/.npmrc.codeartifact.backup
```

### Check SOPS Secrets

```bash
# Check configured secrets
grep -A 1 "secrets =" ~/.config/nix/modules/shared/sops.nix

# Check deployed secrets
sudo ls -la /run/secrets/
```

### Check MCP Configuration

```bash
# Cursor MCP config
cat ~/.cursor/mcp.json | jq '.mcpServers | keys'

# Claude Desktop config
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | jq '.mcpServers | keys'
```

## Expected Behavior After Rebuild

### MCP Server Status

All enabled servers should connect successfully:

```bash
claude mcp list

# Expected output:
# ✓ everything - Connected
# ✓ filesystem - Connected  
# ✓ git - Connected
# ✓ github - Connected (after rebuild)
# ✓ kagi - Connected (after rebuild)
# ✓ memory - Connected (or debugging needed)
# ✓ openai - Connected (after rebuild)
# ✓ docs - Connected (after rebuild)
# ✓ rustdocs - Connected (after rebuild)
# ✓ sequentialthinking - Connected
# ✓ sqlite - Connected (or debugging needed)
# ✓ time - Connected
```

### npm Behavior

```bash
# Public npm packages should work globally
npx -y cowsay "MCP servers work!"

# Work projects use project-specific .npmrc
cd ~/Code/kyoso-backend
npm install  # Uses CodeArtifact if .npmrc configured
```

## Troubleshooting

### "Failed to connect" after rebuild

1. **Restart Claude Desktop and Cursor** - They cache MCP configs
2. **Check secret permissions**:
   ```bash
   sudo ls -la /run/secrets/GITHUB_TOKEN
   # Should be readable by your user
   ```
3. **Check wrapper scripts**:
   ```bash
   # Find wrapper script
   which memory-mcp-wrapper
   
   # Test directly
   memory-mcp-wrapper --version
   ```

### CodeArtifact token expired

```bash
# Refresh token (expires every 12 hours)
aws codeartifact get-authorization-token \
  --domain lumina-artifacts \
  --domain-owner 654654299728 \
  --region us-east-1 \
  --query authorizationToken \
  --output text > /tmp/token.txt

# Update project .npmrc
cd ~/Code/your-project
sed -i.bak "s/:_authToken=.*/:_authToken=$(cat /tmp/token.txt)/" .npmrc

rm /tmp/token.txt
```

### MCP servers work in terminal but not in Claude/Cursor

1. **Environment variables** - MCP servers run with different env
2. **Restart applications** - They don't hot-reload configs
3. **Check logs**:
   ```bash
   # Claude Desktop logs
   tail -f ~/Library/Logs/Claude/claude-desktop.log
   
   # Cursor logs
   tail -f ~/.cursor/logs/main.log
   ```

## References

- **MCP Configuration**: `home/common/modules/mcp.nix`
- **SOPS Setup**: `modules/shared/sops.nix`
- **CodeArtifact Script**: `scripts/setup-codeartifact-project.sh`
- **MCP Documentation**: `docs/MCP_ARCHITECTURE.md`
- **SOPS Guide**: `docs/SOPS_GUIDE.md`
