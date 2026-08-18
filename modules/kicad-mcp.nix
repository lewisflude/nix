# Exposes the KiCAD MCP server as `pkgs.kicad-mcp` via an overlay, so the Claude
# MCP wrapper in modules/claude-code.nix can reference it. Built from the pinned
# `kicad-mcp-server` flake input; see pkgs/kicad-mcp.nix for the derivation and
# why the Python side is deferred to runtime.
{ inputs, ... }:
{
  overlays.kicad-mcp = _final: prev: {
    kicad-mcp = prev.callPackage ../pkgs/kicad-mcp.nix {
      src = inputs.kicad-mcp-server;
    };
  };
}
