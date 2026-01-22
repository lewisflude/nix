# Default MCP Server Configurations
# Combines core, optional, secret-requiring, and integration servers
{
  config,
  pkgs,
  ...
}:
let
  rustdocs = import ../rustdocs.nix {
    inherit pkgs;
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
