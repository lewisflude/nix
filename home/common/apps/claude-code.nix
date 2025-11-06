_: {
  programs.claude-code = {
    enable = true;
    # MCP servers are configured via services.mcp in:
    # - home/nixos/mcp.nix (for NixOS)
    # - home/darwin/mcp.nix (for Darwin)
    # This writes to ~/.config/claude/claude_desktop_config.json
    #
    # Alternatively, you can use programs.claude-code.mcpServers here directly,
    # but the current setup uses the shared MCP service for consistency across tools.
  };
}
