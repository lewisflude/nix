# CodeArtifact & MCP Server Configuration

## Problem

MCP servers were failing on macOS because `~/.npmrc` was configured to use AWS CodeArtifact (a private npm registry) with an expired token. This caused all `npx` commands to fail with authentication errors.

## Solution

We've separated the npm configuration:
- **Global**: Uses public npm registry (for MCP servers and personal projects)
- **Per-project**: Uses CodeArtifact (for work projects in `~/Code`)

## Setup

### What We Did

1. **Backed up** your CodeArtifact configuration:
   ```bash
   ~/.npmrc.codeartifact.backup
   ```

2. **Removed** global `~/.npmrc` so MCP servers can access public npm

3. **Created** a setup script for work projects:
   ```bash
   scripts/setup-codeartifact-project.sh
   ```

### For Work Projects

To enable CodeArtifact in a work project:

```bash
cd ~/Code/your-project
~/.config/nix/scripts/setup-codeartifact-project.sh
```

This will:
- Create a project-specific `.npmrc` with CodeArtifact configuration
- Add `.npmrc` to `.gitignore` (to prevent committing tokens)
- Copy the token from your backup

### Refreshing CodeArtifact Token

CodeArtifact tokens expire after **12 hours**. When they expire:

```bash
# Get a new token
aws codeartifact get-authorization-token \
  --domain lumina-artifacts \
  --domain-owner 654654299728 \
  --region us-east-1 \
  --query authorizationToken \
  --output text > /tmp/token.txt

# Update your project's .npmrc
cd ~/Code/your-project
sed -i.bak "s/:_authToken=.*/:_authToken=$(cat /tmp/token.txt)/" .npmrc

# Clean up
rm /tmp/token.txt
```

Or create a helper function in your shell:

```bash
# Add to ~/.zshrc
refresh-codeartifact() {
  local project_dir="${1:-.}"
  echo "Refreshing CodeArtifact token for ${project_dir}..."
  
  local token=$(aws codeartifact get-authorization-token \
    --domain lumina-artifacts \
    --domain-owner 654654299728 \
    --region us-east-1 \
    --query authorizationToken \
    --output text)
  
  if [ -f "${project_dir}/.npmrc" ]; then
    sed -i.bak "s/:_authToken=.*/:_authToken=${token}/" "${project_dir}/.npmrc"
    echo "✓ Token refreshed in ${project_dir}/.npmrc"
  else
    echo "✗ No .npmrc found in ${project_dir}"
    echo "  Run: ~/.config/nix/scripts/setup-codeartifact-project.sh ${project_dir}"
  fi
}
```

## MCP Server Status

After removing the global `.npmrc`, MCP servers should now work correctly:

```bash
# Test MCP servers
claude mcp list

# Test individual server
npx -y @modelcontextprotocol/server-memory --help
```

### Available MCP Servers

**Enabled by default** (no secrets required):
- `memory` - Knowledge graph-based persistent memory
- `git` - Git repository operations
- `time` - Timezone and datetime utilities
- `sqlite` - SQLite database access
- `everything` - MCP reference/test server

**Requires configuration**:
- `docs`, `openai`, `rustdocs` - Require `OPENAI_API_KEY`
- `github` - Requires `GITHUB_TOKEN`
- `kagi` - Requires `KAGI_API_KEY`

See `CLAUDE.md` for full MCP documentation.

## Troubleshooting

### MCP Servers Still Failing

1. **Check for project-specific .npmrc**:
   ```bash
   # Make sure you're not in a work project directory
   pwd
   cat .npmrc 2>/dev/null || echo "No local .npmrc"
   ```

2. **Clear npm cache**:
   ```bash
   npm cache clean --force
   ```

3. **Test direct access**:
   ```bash
   npx -y @modelcontextprotocol/server-memory --help
   ```

### CodeArtifact Not Working in Project

1. **Check .npmrc exists**:
   ```bash
   cat ~/Code/your-project/.npmrc
   ```

2. **Verify token hasn't expired** (check timestamp in token, expires after 12h)

3. **Re-run setup script**:
   ```bash
   ~/.config/nix/scripts/setup-codeartifact-project.sh ~/Code/your-project
   ```

## Work Projects in ~/Code

Your work projects that may need CodeArtifact:
- `kyoso-backend`
- `kyoso-frontend`
- `kyoso-world`
- `project-service`
- `terraform`
- `user-management-service`

Run the setup script for each project that needs CodeArtifact access.

## Best Practices

1. **Never commit `.npmrc`** with tokens (the setup script adds it to `.gitignore`)
2. **Refresh tokens regularly** (they expire after 12 hours)
3. **Keep global `~/.npmrc` clean** (no private registries)
4. **Use per-project `.npmrc`** for work projects only

## Backup

Your original CodeArtifact configuration is safely backed up at:
```
~/.npmrc.codeartifact.backup
```

To restore it globally (not recommended as it breaks MCP):
```bash
cp ~/.npmrc.codeartifact.backup ~/.npmrc
```
