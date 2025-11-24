_: {
  # Claude Code is installed via pkgs.claude-code in packages.nix
  # The claude-code-nix overlay (github:sadjow/claude-code-nix) provides:
  # - Always up-to-date versions (hourly automated updates)
  # - Node.js 22 LTS (better than nixpkgs' Node.js 20)
  # - Pre-built binaries via Cachix for fast installation
  #
  # If you need Home Manager's programs.claude-code module instead:
  # programs.claude-code = {
  #   enable = true;
  #   # MCP servers configured in home/{nixos,darwin}/mcp.nix
  # };
}
