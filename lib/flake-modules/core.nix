{
  inputs,
  self,
  ...
}: let
  inherit (inputs.nixpkgs) lib;
  hostsConfig = import ../hosts.nix {inherit lib;};
  inherit (hostsConfig) hosts;
  currentSystem =
    inputs.nixpkgs.system or (builtins.currentSystem or null);
  systems =
    lib.unique
    (builtins.attrValues
      (builtins.mapAttrs (_: host: host.system) filteredHosts));

  filteredHosts =
    if currentSystem != null
    then
      lib.filterAttrs
      (_: host: host.system == currentSystem)
      hosts
    else hosts;
  systemBuilders = import ../system-builders.nix {inherit inputs;};
  outputBuilders = import ../output-builders.nix {
    inputs = inputs // {inherit self;};
    hosts = filteredHosts;
  };

  mkDarwinSystem = hostName: hostConfig:
    systemBuilders.mkDarwinSystem hostName hostConfig {
      inherit (inputs) homebrew-j178;
    };

  mkNixosSystem = hostName: hostConfig:
    systemBuilders.mkNixosSystem hostName hostConfig {inherit self;};
in {
  inherit systems;

  perSystem = {
    system,
    pkgs,
    ...
  }: {
    formatter = outputBuilders.mkFormatters.${system} or pkgs.alejandra;
    checks = outputBuilders.mkChecks.${system} or {};
    devShells = outputBuilders.mkDevShells.${system} or {};
  };

  flake = {
    darwinConfigurations =
      builtins.mapAttrs mkDarwinSystem (hostsConfig.getDarwinHosts hosts);

    nixosConfigurations =
      builtins.mapAttrs mkNixosSystem (hostsConfig.getNixosHosts hosts);

    homeConfigurations = outputBuilders.mkHomeConfigurations;

    lib = import ../default.nix {inherit inputs;};
  };
}
