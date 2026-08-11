# Per-system CLI apps
# Dendritic pattern: Provides CLI apps for each system
{
  inputs,
  lib,
  ...
}:
{
  perSystem =
    { pkgs, pkgsWithPog, ... }:
    let
      # Helper to create POG app definitions
      mkPogApp =
        script-name:
        let
          descriptions = {
            "new-module" = "Scaffold new NixOS/home-manager modules";
            "setup-cachix" = "Configure Cachix binary cache";
            "update-all" = "Update all flake dependencies";
            "visualize-modules" = "Generate module dependency graphs";
            "calculate-qbittorrent-config" = "Calculate optimal qBittorrent settings from speed tests";
            "system-health" = "Run comprehensive system diagnostics";
          };
          pogScript = pkgsWithPog.callPackage ../../pkgs/pog-scripts/${script-name}.nix { };
        in
        {
          type = "app";
          program = "${pogScript}/bin/${script-name}";
          meta.description = descriptions.${script-name} or "POG script: ${script-name}";
        };
      # Import devour-flake (lazy evaluation - only when the app is used)
      devour-flake = import inputs.devour-flake {
        inherit pkgs;
        inherit (pkgs) nix findutils writeShellApplication;
      };
    in
    {
      # CLI applications for this system
      apps = {
        new-module = mkPogApp "new-module";
        setup-cachix = mkPogApp "setup-cachix";
        update-all = mkPogApp "update-all";
        visualize-modules = mkPogApp "visualize-modules";
        # devour-flake: Build all flake outputs efficiently
        devour-flake = {
          type = "app";
          meta.description = "Build all flake outputs efficiently";
          program = "${devour-flake}/bin/devour-flake";
        };
      }
      // lib.optionalAttrs pkgs.stdenv.isLinux {
        # Linux-only apps (require iproute2, util-linux, network namespaces)
        calculate-qbittorrent-config = mkPogApp "calculate-qbittorrent-config";
        system-health = mkPogApp "system-health";
      };
    };
}
