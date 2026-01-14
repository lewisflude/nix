# Default MCP Server Configurations
# Combines core, optional, secret-requiring, and integration servers
{
  config,
  pkgs,
  rust-docs-mcp,
  ...
}:
let
  rustdocs = import ../rustdocs.nix {
    inherit rust-docs-mcp;
  };
  core = import ./core.nix { inherit config pkgs; };
  optional = import ./optional.nix { inherit pkgs config; };
  secrets = import ./secrets.nix {
    inherit pkgs;
    inherit (rustdocs) rustdocsServer;
  };
  integrations = import ./integrations.nix { inherit pkgs; };
in
core // optional // secrets // integrations
