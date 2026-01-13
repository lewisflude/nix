# Default MCP Server Configurations
# Combines core, optional, and secret-requiring servers
{
  config,
  pkgs,
  ...
}:
let
  rustdocs = import ../rustdocs.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  core = import ./core.nix { inherit config pkgs; };
  optional = import ./optional.nix { inherit pkgs config; };
  secrets = import ./secrets.nix {
    inherit pkgs;
    inherit (rustdocs) rustdocsServer;
  };
in
core // optional // secrets
