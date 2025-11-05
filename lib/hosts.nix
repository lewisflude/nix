{ lib }:
let
  hostDirectories = lib.filterAttrs (
    name: type: type == "directory" && !(lib.hasPrefix "_" name) # Exclude directories starting with underscore
  ) (builtins.readDir ../hosts);
  hosts = builtins.mapAttrs (name: _: import (../hosts + "/${name}")) hostDirectories;
in
{
  inherit hosts;
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
