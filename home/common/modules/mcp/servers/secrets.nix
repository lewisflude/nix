# MCP Servers Requiring Secrets (disabled by default)
# Enable these in your platform-specific config after configuring secrets
{
  pkgs,
  rustdocsServer,
  ...
}:
{
  # Documentation indexing and search (requires OPENAI_API_KEY)
  docs = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@arabold/docs-mcp-server"
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
  github = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@cyanheads/github-mcp-server"
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
