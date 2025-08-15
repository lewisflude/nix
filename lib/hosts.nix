# Centralized host configuration registry
# This module provides a single place to manage all host configurations
{
  lib ? (import <nixpkgs> { }).lib,
}:

let
  # Host definitions with their basic properties
  hosts = {
    "Lewiss-MacBook-Pro" = import ../hosts/Lewiss-MacBook-Pro;
    jupiter = import ../hosts/jupiter;
  };
in
{
  inherit hosts;

  # Helper functions for host management
  getSystems = hosts: builtins.attrValues (builtins.mapAttrs (_name: host: host.system) hosts);

  getDarwinHosts =
    hosts:
    lib.filterAttrs (
      _name: host: host.system == "aarch64-darwin" || host.system == "x86_64-darwin"
    ) hosts;

  getNixosHosts =
    hosts:
    lib.filterAttrs (
      _name: host: host.system == "x86_64-linux" || host.system == "aarch64-linux"
    ) hosts;
}
