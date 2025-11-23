_: {
  programs.claude-code = {
    enable = true;
    # Use overlay version (pre-built binaries from Anthropic)
    # The overlay provides pkgs.claude-code which will be used automatically
    # MCP servers configured in home/{nixos,darwin}/mcp.nix
  };
}
