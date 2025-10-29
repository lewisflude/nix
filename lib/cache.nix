# Caching utilities for expensive flake operations
# This module provides functions to cache and optimize flake evaluations
{lib}: let
  # Cache expensive attribute computations
  # Usage: cached = cacheAttr "myKey" expensiveComputation;
  cacheAttr = _key: value: let
    # In Nix, we can't actually cache between evaluations
    # But we can memoize within a single evaluation
    # Real caching happens via:
    # 1. Nix's built-in evaluation cache
    # 2. Build output caching (Cachix, binary caches)
    # 3. Pre-built derivations
    inherit value;
  in
    value;

  # Pre-compute common flake outputs to speed up evaluation
  # This creates a cached version of frequently accessed attributes
  precomputeOutputs = outputs: let
    # Extract and cache common paths
    systems = outputs.nixosConfigurations or {};
    darwinSystems = outputs.darwinConfigurations or {};

    # Create pre-computed versions
    cached = {
      inherit systems darwinSystems;

      # Cache system derivations
      systemDerivations =
        lib.mapAttrs (
          _name: cfg:
            cfg.config.system.build.toplevel or null
        )
        systems;

      darwinDerivations =
        lib.mapAttrs (
          _name: cfg:
            cfg.system or null
        )
        darwinSystems;
    };
  in
    cached;

  # Create a manifest of all configurations for quick lookup
  # This helps avoid re-evaluating configs multiple times
  createManifest = {
    nixosConfigurations ? {},
    darwinConfigurations ? {},
    homeConfigurations ? {},
  }: {
    version = "1.0.0";
    timestamp = builtins.currentTime or 0;

    systems = {
      nixos =
        lib.mapAttrs (name: cfg: {
          inherit name;
          system = cfg.config.nixpkgs.system or "unknown";
          hostname = cfg.config.networking.hostName or name;
          features = cfg.config.host.features or {};
        })
        nixosConfigurations;

      darwin =
        lib.mapAttrs (name: cfg: {
          inherit name;
          system = cfg.system.system or "unknown";
          hostname = name;
          features = cfg.config.host.features or {};
        })
        darwinConfigurations;

      home =
        lib.mapAttrs (name: cfg: {
          inherit name;
          system = cfg.pkgs.system or "unknown";
        })
        homeConfigurations;
    };
  };

  # Helper to generate cache keys for configurations
  # This can be used with external caching systems
  generateCacheKey = {
    name,
    system,
    nixpkgsRev ? "unknown",
    configHash ? "",
  }: let
    # Create a stable cache key
    keyComponents = [
      "nix-config"
      name
      system
      nixpkgsRev
      configHash
    ];
  in
    builtins.concatStringsSep "-" keyComponents;

  # Function to check if a cached build exists
  # This is a placeholder - actual implementation would check Cachix or local cache
  cachedBuildExists = _cacheKey: false; # Would check actual cache

  # Pre-compute package lists for faster queries
  # This is useful for tools that need to inspect installed packages
  cachePackageLists = nixosConfig: let
    systemPackages = nixosConfig.config.environment.systemPackages or [];
    userPackages = nixosConfig.config.home-manager.users or {};
  in {
    system = {
      count = builtins.length systemPackages;
      # Don't store full list - too expensive
      # Use: nix-env -qa to get actual list
    };
    users =
      lib.mapAttrs (_user: cfg: {
        count = builtins.length (cfg.home.packages or []);
      })
      userPackages;
  };

  # Helper for lazy evaluation - only compute when needed
  lazyAttr = _name: value:
  # This ensures the attribute is only evaluated if accessed
  # Nix already does this by default, but we make it explicit
    value;

  # Create evaluation cache metadata
  evalCache = {
    description ? "Evaluation cache metadata",
    inputs ? {},
  }: {
    inherit description;
    inputRevisions =
      lib.mapAttrs (
        _name: input:
          input.rev or input.lastModified or "unknown"
      )
      inputs;
    cacheVersion = "1.0.0";
    nixVersion = builtins.nixVersion or "unknown";
  };

  # Function to generate Cachix configuration
  cachixConfig = {
    cacheName,
    publicKey ? null,
    priority ? 40,
  }: {
    "${cacheName}" =
      {
        enable = true;
        inherit priority;
      }
      // lib.optionalAttrs (publicKey != null) {
        inherit publicKey;
      };
  };

  # Helper to create a cached version of all flake outputs
  # This can be used in CI to pre-build common configurations
  prebuildManifest = outputs: let
    configs =
      (lib.mapAttrsToList (name: _: "nixosConfigurations.${name}")
        (outputs.nixosConfigurations or {}))
      ++ (lib.mapAttrsToList (name: _: "darwinConfigurations.${name}")
        (outputs.darwinConfigurations or {}));
  in {
    configurations = configs;
    buildCommand = name: "nix build .#${name}";
  };

  # Statistics helper for tracking evaluation performance
  evalStats = config: {
    # These would be populated by actual measurements
    evaluationTime = null; # Measured externally
    moduleCount = builtins.length (config._module.args._module.checks or []);
    optionCount = null; # Would need to traverse all options
    warningCount = builtins.length (config.warnings or []);
    assertionCount = builtins.length (config.assertions or []);
  };
in {
  inherit
    cacheAttr
    precomputeOutputs
    createManifest
    generateCacheKey
    cachedBuildExists
    cachePackageLists
    lazyAttr
    evalCache
    cachixConfig
    prebuildManifest
    evalStats
    ;

  # Export a summary of caching utilities
  cachingInfo = {
    description = "Flake evaluation caching utilities";
    features = [
      "Manifest generation for quick config lookup"
      "Cache key generation for external caches"
      "Package list caching for performance"
      "Lazy evaluation helpers"
      "Cachix integration helpers"
      "Pre-build manifest generation for CI"
    ];
    usage = ''
      Import this module to use caching utilities:

      cache = import ./lib/cache.nix { inherit lib; };

      # Create a manifest
      manifest = cache.createManifest {
        inherit nixosConfigurations darwinConfigurations;
      };

      # Generate cache keys
      key = cache.generateCacheKey {
        name = "jupiter";
        system = "x86_64-linux";
      };
    '';
  };
}
