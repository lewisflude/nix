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
  # Force reinstall to avoid npx cache issues with native modules
  docs = {
    command = "${pkgs.nodejs_20}/bin/npx";
    args = [
      "--yes"
      "@arabold/docs-mcp-server@latest"
    ];
    secret = "OPENAI_API_KEY";
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
    };
    enabled = false; # Disabled - requires OPENAI_API_KEY secret
  };

  # Rust documentation - Bevy (requires OPENAI_API_KEY)
  rustdocs = rustdocsServer // {
    enabled = false;
  }; # Disabled - requires OPENAI_API_KEY secret

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
    enabled = false; # Disabled - requires BRAVE_API_KEY secret
  };
}
