{lib ? (import <nixpkgs> {}).lib}: let
  hosts = {
    "Lewiss-MacBook-Pro" = import ../hosts/Lewiss-MacBook-Pro;
    jupiter = import ../hosts/jupiter;
  };
in {
  inherit hosts;
  getSystems = hosts: builtins.attrValues (builtins.mapAttrs (_name: host: host.system) hosts);
  getDarwinHosts = hosts:
    lib.filterAttrs
    (
      _name: host: host.system == "aarch64-darwin" || host.system == "x86_64-darwin"
    )
    hosts;
  getNixosHosts = hosts:
    lib.filterAttrs
    (
      _name: host: host.system == "x86_64-linux" || host.system == "aarch64-linux"
    )
    hosts;
}
