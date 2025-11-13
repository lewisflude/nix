{ pkgs, config, systemConfig, lib, system, ... }:

let
  platformLib = (import ../../../lib/functions.nix { inherit lib; }).withSystem system;

  # Import shared servers and utilities
  servers = import ./servers.nix { inherit pkgs config systemConfig lib platformLib; };
  wrappers = import ./wrappers.nix { inherit pkgs systemConfig lib platformLib; };

in {
  imports = [
    ./service.nix
  ];

  config = lib.mkIf config.services.mcp.enable {
    home.packages = [
      pkgs.uv
    ] ++ (lib.optionals (servers.nodejs != null) [ servers.nodejs ]);

    services.mcp = {
      inherit (servers) commonServers;
    };
  };
}
