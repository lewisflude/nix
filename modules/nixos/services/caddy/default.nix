# Caddy Service Module - Main Entry Point
# Combines base configuration and virtual hosts
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf; # recursiveUpdate;
  cfg = config.host.services.caddy;
  virtualHosts = import ./virtual-hosts/default.nix { inherit lib; };
in
{
  imports = [
    ./config.nix
  ];

  config = mkIf cfg.enable {
    services.caddy.virtualHosts = virtualHosts;
  };
}
