{
  config,
  inputs,
  functionsLib,
  ...
}:
let
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;
in
{
  perSystem =
    { system, ... }:
    let
      # Get pkgs and pkgsWithPog from module args
      # These are set by per-system/pkgs.nix and per-system/pog-overlay.nix respectively
      # Use fallback to direct import if needed
      pkgs =
        config._module.args.pkgs or (import nixpkgs {
          inherit system;
          overlays = functionsLib.mkOverlays { inherit inputs system; };
          config = functionsLib.mkPkgsConfig;
        });
      # Get pog overlay if available
      getPogOverlay =
        if
          inputs ? pog
          && inputs.pog ? overlays
          && inputs.pog.overlays ? ${system}
          && inputs.pog.overlays.${system} ? default
        then
          inputs.pog.overlays.${system}.default
        else
          (_final: _prev: { });
      # Create pkgsWithPog by extending pkgs with pog overlay
      pkgsWithPog = config._module.args.pkgsWithPog or (pkgs.extend getPogOverlay);

      # Helper to create POG app definitions
      mkPogApp =
        script-name:
        let
          needsConfigRoot = lib.elem script-name [
            "new-module"
            "update-all"
            "visualize-modules"
            "calculate-qbittorrent-config"
          ];
          scriptArgs =
            if needsConfigRoot then
              {
                config-root = ../..;
              }
            else
              { };
          descriptions = {
            "new-module" = "Scaffold new NixOS/home-manager modules";
            "setup-cachix" = "Configure Cachix binary cache";
            "update-all" = "Update all flake dependencies";
            "visualize-modules" = "Generate module dependency graphs";
            "calculate-qbittorrent-config" = "Calculate optimal qBittorrent settings from speed tests";
          };
          pogScript = pkgsWithPog.callPackage ../../pkgs/pog-scripts/${script-name}.nix scriptArgs;
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
      };
    };
}
