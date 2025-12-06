# Darwin MCP Configuration
#
# Enables MCP servers for macOS hosts.
# The actual server definitions are in modules/shared/mcp.nix
{
  # Enable MCP with default servers
  services.mcp = {
    enable = true;

    # All servers use defaults from modules/shared/mcp.nix
    # Override here if needed:
    servers = {
      # memory = {};   # Enabled by default
      # docs = {};     # Enabled by default
      # openai = {};   # Enabled by default
      # rustdocs = {};  # Enabled by default

      # These are disabled by default (uv package broken)
      # kagi.enabled = false;
      # nixos.enabled = false;
    };
  };
}
