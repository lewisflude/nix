# Darwin MCP Configuration
#
# Enables MCP servers for macOS hosts.
# The actual server definitions are in home/common/modules/mcp.nix
{
  # Enable MCP with default servers (no secrets required)
  services.mcp = {
    enable = true;

    # Default enabled servers (no secrets):
    # - memory, git, time, sqlite, everything

    # To enable servers that require secrets:
    # 1. Configure secret in secrets/secrets.yaml (SOPS)
    # 2. Add secret to modules/shared/sops.nix with neededForUsers = true
    # 3. Enable server below:
    servers = {
      # Example: Enable GitHub MCP (requires GITHUB_TOKEN)
      # github.enabled = true;

      # Example: Enable OpenAI MCP (requires OPENAI_API_KEY)
      # openai.enabled = true;
      # docs.enabled = true;
      # rustdocs.enabled = true;

      # Example: Enable Kagi search (requires KAGI_API_KEY)
      # kagi.enabled = true;

      # Example: Enable filesystem server (disabled by default for security)
      # filesystem.enabled = true;
    };
  };
}
