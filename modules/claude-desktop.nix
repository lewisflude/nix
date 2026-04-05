# Claude Desktop app (Linux only, via FHS for MCP server support)
_: {
  flake.modules.homeManager.claudeDesktop =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.isLinux {
      home.packages = [ pkgs.claude-desktop ];
    };
}
