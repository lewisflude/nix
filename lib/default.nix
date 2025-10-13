# Main library entry point
# Provides all outputs for the flake
{
  inputs,
  self,
}: let
  inherit (inputs.nixpkgs) lib;
  
  # Import host configurations
  hostsConfig = import ./hosts.nix {inherit lib;};
  inherit (hostsConfig) hosts;
  
  # System builders
  systemBuilders = import ./system-builders.nix {inherit inputs;};
  
  # Output builders
  outputBuilders = import ./output-builders.nix {
    inputs = inputs // {inherit self;};
    inherit hosts;
  };
  
  # Helper to build Darwin systems
  mkDarwinSystem = hostName: hostConfig:
    systemBuilders.mkDarwinSystem hostName hostConfig {
      inherit (inputs) homebrew-j178;
    };
  
  # Helper to build NixOS systems
  mkNixosSystem = hostName: hostConfig:
    systemBuilders.mkNixosSystem hostName hostConfig {inherit self;};
in {
  # Export system configurations
  darwinConfigurations = 
    builtins.mapAttrs mkDarwinSystem (hostsConfig.getDarwinHosts hosts);
  
  nixosConfigurations =
    builtins.mapAttrs mkNixosSystem (hostsConfig.getNixosHosts hosts);
  
  homeConfigurations = outputBuilders.mkHomeConfigurations;
  
  # Development outputs
  formatter = outputBuilders.mkFormatters;
  checks = outputBuilders.mkChecks;
  devShells = outputBuilders.mkDevShells;
  
  # Expose utilities for external use
  lib = {
    inherit (import ./functions.nix {inherit lib; system = "x86_64-linux";})
      platformPackages
      platformModules
      homeDir
      configDir
      dataDir
      cacheDir;
    
    inherit (import ./validation.nix {inherit lib; pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;})
      validateHostConfig
      mkCheck;
  };
}
