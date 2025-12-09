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
      # Enabled servers with API keys from SOPS
      github.enabled = true;
      kagi.enabled = true;
      openai.enabled = true;
      docs.enabled = true;
      rustdocs.enabled = true;

      # Optional servers without secrets (enable if needed)
      # filesystem.enabled = true;
      # sequentialthinking.enabled = true;
      # fetch.enabled = true;
      nixos.enabled = true;
    };
  };
}
