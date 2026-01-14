# MCP Servers Requiring Secrets (disabled by default)
# Enable these in your platform-specific config after configuring secrets
{
  pkgs,
  rustdocsServer,
  ...
}:
{
  # Documentation indexing and search (requires OPENAI_API_KEY)
  # Note: Uses Node.js 20 for better-sqlite3 compatibility
  # Uses version-specific npx cache to avoid native module version mismatches
  docs = {
    command = "${pkgs.nodejs_20}/bin/npx";
    args = [
      "--yes"
      "@arabold/docs-mcp-server@latest"
    ];
    secret = "OPENAI_API_KEY";
    env = {
      NPM_CONFIG_REGISTRY = "https://registry.npmjs.org/";
    };
    enabled = false; # Disabled - requires OPENAI_API_KEY secret
  };

  # OpenAI integration (requires OPENAI_API_KEY)
  openai = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@mzxrai/mcp-openai"
    ];
    secret = "OPENAI_API_KEY";
    env = {
      DOCS_RS = "1";
      RUSTDOCFLAGS = "--cfg=docsrs";
      NPM_CONFIG_REGISTRY = "https://registry.npmjs.org/";
    };
    enabled = false; # Disabled - requires OPENAI_API_KEY secret
  };

  # Rust documentation (no secrets required for basic functionality)
  # Uses MCP tools like cache_crate to load crates on-demand
  # OPENAI_API_KEY is only needed for optional OpenAI features
  rustdocs = rustdocsServer // {
    enabled = false; # Disabled by default - enable in platform config
  };

  # GitHub API integration (requires GITHUB_TOKEN)
  # Note: Package name is github-mcp-server, MCP binary is github-mcp-server-mcp
  github = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "--package=github-mcp-server"
      "github-mcp-server-mcp"
    ];
    secret = "GITHUB_TOKEN";
    env = {
      NPM_CONFIG_REGISTRY = "https://registry.npmjs.org/";
    };
    enabled = false; # Disabled - requires GITHUB_TOKEN secret
  };

  # Kagi search and summarization (requires KAGI_API_KEY and uvx)
  kagi = {
    command = "${pkgs.uv}/bin/uvx";
    args = [ "kagimcp" ];
    secret = "KAGI_API_KEY";
    enabled = false; # Disabled - requires KAGI_API_KEY secret and uv package
  };

  # Brave Search (requires BRAVE_API_KEY)
  brave = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@brave/brave-search-mcp-server"
    ];
    secret = "BRAVE_API_KEY";
    env = {
      NPM_CONFIG_REGISTRY = "https://registry.npmjs.org/";
    };
    enabled = false; # Disabled - requires BRAVE_API_KEY secret
  };
}
