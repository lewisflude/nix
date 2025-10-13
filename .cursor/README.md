# Cursor Configuration for Nix Config Project

This directory contains project-specific Cursor/AI assistant configurations.

## MCP Servers (`mcp.json`)

This project uses the following MCP (Model Context Protocol) servers specifically for working on the Nix configuration:

### Configured Servers

1. **`nix-config-filesystem`** - Filesystem access scoped to this project
   - Provides file read/write operations only within `/Users/lewisflude/.config/nix`
   - More focused than the global filesystem server

2. **`nix-config-git`** - Git operations for this repository
   - Git history, diffs, commits, branches for the nix config repo
   - Separate from the global git server (which targets dex-web)

3. **`github`** - GitHub API integration
   - Access to issues, PRs, GitHub Actions
   - Requires `GITHUB_TOKEN` environment variable

4. **`fetch`** - Web content fetching
   - Useful for fetching Nix/NixOS documentation
   - Can retrieve nixpkgs package information

5. **`time`** - Time and date utilities
   - Helpful for understanding file modification times, build timestamps

## Usage

### In Cursor IDE

When you open this project in Cursor, it should automatically detect and use the MCP servers defined in `mcp.json`. These will be available in addition to (or potentially instead of) your global MCP configuration at `~/.cursor/mcp.json`.

### With cursor-agent CLI

**Important:** Before `cursor-agent` can use project-specific MCP servers, you must approve them in the IDE first.

**How to approve MCP servers in Cursor IDE:**

1. **Open this project folder in Cursor** (`File > Open Folder` → select `~/.config/nix`)
2. **Start a chat or use Composer** - The MCP servers are only activated when you use AI features
3. **Look for approval prompts** in one of these places:
   - A notification/banner at the top of the editor
   - In the chat window asking to approve MCP tools
   - Click the MCP icon (if visible) in the status bar or chat interface
4. **Click "Approve" or "Allow"** for each MCP server
5. Alternatively, you can manually approve by:
   - Opening Cursor Settings (Cmd+, on Mac)
   - Search for "MCP" 
   - Look for server approval options

**Note:** If no prompt appears, the servers might already be auto-approved, or you may need to:
- Try using a tool that requires MCP (e.g., ask AI to "list files in this directory")
- Check Cursor Settings → Features → Model Context Protocol
- Restart Cursor with this project open

### Known Issue: CLI Not Recognizing Approved Servers

Even after approving servers in Cursor Desktop, `cursor-agent mcp list` may still show "No MCP servers configured". This happens because:

1. **Cursor Desktop** reads `.cursor/mcp.json` directly and works fine
2. **cursor-agent CLI** requires an `mcp-approvals.json` file in `~/.cursor/projects/Users-{username}-config-nix/`
3. The Desktop IDE may not create this file until you **actively use** an MCP tool (not just have it available)

**To fix:**
- In Cursor Desktop with this project open, **actively use an MCP tool**:
  - Ask AI: "Use the filesystem tool to list all .nix files in this directory"
  - Ask AI: "Use the git tool to show me recent commits"
- This should trigger creation of `mcp-approvals.json`
- Then `cursor-agent mcp list` will work

**Workaround:** The MCP servers work perfectly in Cursor Desktop IDE regardless of whether the CLI recognizes them.

### Testing the Configuration

To verify the MCP configuration is valid JSON:

```bash
python3 -m json.tool .cursor/mcp.json
```

## Rules

The `.cursor/rules/` directory contains Cursor-specific coding rules and standards:

- `nix-standards.mdc` - Nix code formatting and structure standards
- `home-manager.mdc` - Home Manager configuration guidelines
- `cursor-config.mdc` - Cursor/editor configuration patterns

These rules are automatically applied when working in this project with Cursor.
