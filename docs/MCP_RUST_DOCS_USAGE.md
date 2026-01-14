# Rust Documentation MCP Server Usage

## Overview

The `rust-docs-mcp` server provides comprehensive access to Rust crate documentation, source code analysis, dependency trees, and module structure visualization for AI coding assistants.

## Configuration

### Architecture

The server is configured using **best practice**: a declarative flake input that provides a reproducible, managed package.

```nix
# flake.nix
inputs.rust-docs-mcp = {
  url = "github:snowmead/rust-docs-mcp";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

The package is passed through to home-manager via `extraSpecialArgs` and used in the MCP configuration.

### Enabling the Server

The server is **disabled by default**. Enable it in your platform-specific MCP config:

```nix
# home/darwin/mcp.nix (macOS)
# OR home/nixos/mcp.nix (Linux)
{
  services.mcp = {
    enable = true;
    servers = {
      rustdocs.enabled = true;  # Enable rust-docs MCP server
    };
  };
}
```

### No Secrets Required

Unlike the previous configuration, **no `OPENAI_API_KEY` is required** for basic functionality. The server works completely offline after caching crates.

> **Note**: `OPENAI_API_KEY` is only needed for optional OpenAI-enhanced features (not covered in the basic usage).

## How It Works

### Dynamic Crate Loading

Unlike the old configuration that tried to pre-load Bevy, the correct approach is:

1. **Start the MCP server** (no args needed)
2. **Use MCP tools** to cache crates dynamically
3. **Query documentation** as needed

### Cache Location

By default, crates are cached in `~/.rust-docs-mcp/cache/`. Each crate version stores:

- Complete source code in `source/` directory
- Rustdoc JSON in `docs.json` 
- Cargo dependency metadata in `dependencies.json`
- Cache metadata in `metadata.json`

You can customize this location:

```bash
export RUST_DOCS_MCP_CACHE_DIR=/custom/path/to/cache
```

## Available MCP Tools

Once the server is running, AI assistants have access to these tools:

### Cache Management

- **`cache_crate`** - Download and cache a crate
  - From crates.io: `{crate_name: "serde", source_type: "cratesio", version: "1.0.215"}`
  - From GitHub: `{crate_name: "my-crate", source_type: "github", github_url: "https://github.com/user/repo", tag: "v1.0.0"}`
  - From local path: `{crate_name: "my-crate", source_type: "local", path: "~/projects/my-crate"}`
- **`remove_crate`** - Remove cached crate versions
- **`list_cached_crates`** - View all cached crates with versions and sizes
- **`list_crate_versions`** - List cached versions for a specific crate

### Documentation Queries

- **`list_crate_items`** - Browse all items with optional filtering
- **`search_items`** - Full search with complete documentation
- **`search_items_preview`** - Lightweight search (IDs, names, types only)
- **`search_items_fuzzy`** - Fuzzy search with typo tolerance
- **`get_item_details`** - Detailed signatures, fields, methods
- **`get_item_docs`** - Extract just the documentation string
- **`get_item_source`** - View source code with context lines

### Analysis Tools

- **`get_dependencies`** - Analyze direct and transitive dependencies
- **`structure`** - Generate hierarchical module tree (uses `cargo-modules`)

## Example Usage Workflow

### 1. Cache a Crate

```
AI Assistant uses: cache_crate
{
  crate_name: "tokio",
  source_type: "cratesio",
  version: "1.35.1"
}
```

### 2. Explore Structure

```
AI Assistant uses: structure
{
  crate_name: "tokio",
  version: "1.35.1"
}
```

### 3. Search for Items

```
AI Assistant uses: search_items_preview
{
  crate_name: "tokio",
  version: "1.35.1",
  pattern: "Runtime",
  kind: "struct"
}
```

### 4. Get Detailed Documentation

```
AI Assistant uses: get_item_details
{
  crate_name: "tokio",
  version: "1.35.1",
  item_id: "tokio::runtime::Runtime"
}
```

## Benefits of This Approach

### ✅ Declarative and Reproducible
- Version pinned via flake input
- No manual `cargo install` steps
- Managed by home-manager

### ✅ Consistent with Repository Patterns
- Uses same pattern as other flake inputs (`atuin`, `pog`, `lazygit`)
- Lives in `pkgs/` directory space conceptually
- Follows Nix best practices

### ✅ Efficient and Flexible
- No pre-loading of crates (old approach wasted resources)
- Cache crates on-demand as needed
- Supports crates.io, GitHub, and local paths

### ✅ Works Offline
- Full functionality after initial caching
- No network required for cached crates
- No secrets required for basic usage

## Comparison: Old vs New

### Old Approach (Incorrect)

```nix
# ❌ WRONG - Used wrong repository (Govcraft instead of snowmead)
${pkgs.nix}/bin/nix build github:Govcraft/rust-docs-mcp-server

# ❌ WRONG - Pre-loaded Bevy in args (wasteful, inflexible)
args = [ "bevy@0.16.1" "-F" "default" ];

# ❌ WRONG - Required OPENAI_API_KEY for basic usage (unnecessary)
secret = "OPENAI_API_KEY";

# ❌ WRONG - Complex wrapper with manual building (not declarative)
```

### New Approach (Correct)

```nix
# ✅ CORRECT - Uses proper flake input
inputs.rust-docs-mcp = {
  url = "github:snowmead/rust-docs-mcp";
  inputs.nixpkgs.follows = "nixpkgs";
};

# ✅ CORRECT - No pre-loading, use MCP tools instead
args = [ ];

# ✅ CORRECT - No secrets required for basic usage
# secret field omitted

# ✅ CORRECT - Declarative package from flake
command = "${rust-docs-mcp-pkg}/bin/rust-docs-mcp";
```

## Troubleshooting

### Server Won't Start

1. **Check if server is enabled**:
   ```nix
   # In home/darwin/mcp.nix
   services.mcp.servers.rustdocs.enabled = true;
   ```

2. **Rebuild home-manager**:
   ```bash
   home-manager switch --flake .
   ```

3. **Check MCP config files**:
   ```bash
   cat ~/.cursor/mcp.json | jq '.mcpServers.rustdocs'
   cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | jq '.mcpServers.rustdocs'
   ```

### Caching Issues

1. **Check cache directory permissions**:
   ```bash
   ls -la ~/.rust-docs-mcp/cache/
   ```

2. **Clear cache if corrupted**:
   ```bash
   rm -rf ~/.rust-docs-mcp/cache/
   ```

3. **Use custom cache location**:
   ```bash
   export RUST_DOCS_MCP_CACHE_DIR=/custom/path
   ```

### GitHub Rate Limits

For private repositories or higher rate limits, set `GITHUB_TOKEN`:

```bash
export GITHUB_TOKEN=your_github_personal_access_token
```

Benefits:
- Access private repositories
- 5,000 requests/hour (vs 60 unauthenticated)

## References

- **Upstream Repository**: https://github.com/snowmead/rust-docs-mcp
- **MCP Documentation**: See `docs/MCP_ARCHITECTURE.md`
- **Configuration**: `home/common/modules/mcp/rustdocs.nix`
