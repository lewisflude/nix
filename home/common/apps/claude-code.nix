_: {
  # DISABLED: claude-code-overlay has upstream build issues
  # Workaround: Install Claude Code manually from https://claude.ai/code
  # or use the official installation script until the overlay is fixed

  # programs.claude-code = {
  #   enable = true;
  #   # Use overlay version (pre-built binaries from Anthropic)
  #   # The overlay provides pkgs.claude-code which will be used automatically
  #   # MCP servers configured in home/{nixos,darwin}/mcp.nix
  # };
}
