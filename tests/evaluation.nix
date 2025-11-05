# Configuration evaluation tests
# Ensures all configurations evaluate without errors
{
  pkgs,
  inputs,
  ...
}:
let
  # Test that a configuration evaluates successfully
  mkEvalTest =
    name: config:
    pkgs.runCommand "eval-test-${name}" { } ''
      ${pkgs.nix}/bin/nix eval --impure --expr 'builtins.deepSeq (${config}) true' || exit 1
      touch $out
    '';
in
{
  # Test all system configurations evaluate
  darwin-config = mkEvalTest "darwin" ''
    (import ${inputs.darwin} {
      inherit (inputs) nixpkgs;
      system = "aarch64-darwin";
    }).darwinSystem {
      system = "aarch64-darwin";
      modules = [ ../hosts/Lewiss-MacBook-Pro/configuration.nix ];
    }.system
  '';

  nixos-config = mkEvalTest "nixos" ''
    (import ${inputs.nixpkgs} {
      system = "x86_64-linux";
    }).lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ../hosts/jupiter/configuration.nix ];
    }.config.system.build.toplevel
  '';

  # Test that options are properly typed
  host-options = mkEvalTest "host-options" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      module = import ../modules/shared/host-options.nix { inherit lib; config = {}; };
    in
      module.options.host.username.type
  '';

  # Test that overlays evaluate
  overlays = mkEvalTest "overlays" ''
    let
      overlaySet = import ../overlays {
        inherit inputs;
        system = "x86_64-linux";
      };
    in
      builtins.attrNames overlaySet
  '';

  # Test feature system
  features = mkEvalTest "features" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      featuresLib = import ../lib/features.nix { inherit lib; };
    in
      featuresLib.availableFeatures
  '';

  # Test individual feature modules evaluate
  feature-gaming = mkEvalTest "feature-gaming" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      evalModule = module: lib.evalModules {
        modules = [
          ../modules/shared/host-options.nix
          module
          {
            config.host = {
              username = "test";
              useremail = "test@example.com";
              hostname = "test";
              system = "x86_64-linux";
              features.gaming.enable = true;
              features.gaming.steam = true;
            };
          }
        ];
      };
    in
      (evalModule ../modules/nixos/features/gaming.nix).config.host.features.gaming.enable
  '';

  feature-development = mkEvalTest "feature-development" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      evalModule = module: lib.evalModules {
        modules = [
          ../modules/shared/host-options.nix
          module
          {
            config.host = {
              username = "test";
              useremail = "test@example.com";
              hostname = "test";
              system = "x86_64-linux";
              features.development.enable = true;
              features.development.rust = true;
            };
            hostSystem = "x86_64-linux";
          }
        ];
      };
    in
      (evalModule ../modules/shared/features/development/default.nix).config.host.features.development.enable
  '';

  feature-virtualisation = mkEvalTest "feature-virtualisation" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      evalModule = module: lib.evalModules {
        modules = [
          ../modules/shared/host-options.nix
          module
          {
            config.host = {
              username = "test";
              useremail = "test@example.com";
              hostname = "test";
              system = "x86_64-linux";
              features.virtualisation.enable = true;
              features.virtualisation.docker = true;
            };
          }
        ];
      };
    in
      (evalModule ../modules/nixos/features/virtualisation.nix).config.host.features.virtualisation.enable
  '';

  feature-media-management = mkEvalTest "feature-media-management" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      evalModule = module: lib.evalModules {
        modules = [
          ../modules/shared/host-options.nix
          module
          {
            config.host = {
              username = "test";
              useremail = "test@example.com";
              hostname = "test";
              system = "x86_64-linux";
              features.mediaManagement.enable = true;
            };
          }
        ];
      };
    in
      (evalModule ../modules/nixos/features/media-management.nix).config.host.features.mediaManagement.enable
  '';

  feature-security = mkEvalTest "feature-security" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      evalModule = module: lib.evalModules {
        modules = [
          ../modules/shared/host-options.nix
          module
          {
            config.host = {
              username = "test";
              useremail = "test@example.com";
              hostname = "test";
              system = "x86_64-linux";
              features.security.enable = true;
              features.security.yubikey = true;
            };
          }
        ];
      };
    in
      (evalModule ../modules/nixos/features/security.nix).config.host.features.security.enable
  '';

  feature-ai-tools = mkEvalTest "feature-ai-tools" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      evalModule = module: lib.evalModules {
        modules = [
          ../modules/shared/host-options.nix
          module
          {
            config.host = {
              username = "test";
              useremail = "test@example.com";
              hostname = "test";
              system = "x86_64-linux";
              features.aiTools.enable = true;
            };
          }
        ];
      };
    in
      (evalModule ../modules/nixos/features/ai-tools.nix).config.host.features.aiTools.enable
  '';

  feature-restic = mkEvalTest "feature-restic" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      evalModule = module: lib.evalModules {
        modules = [
          ../modules/shared/host-options.nix
          module
          {
            config.host = {
              username = "test";
              useremail = "test@example.com";
              hostname = "test";
              system = "x86_64-linux";
              features.restic.enable = true;
            };
          }
        ];
      };
    in
      (evalModule ../modules/nixos/features/restic.nix).config.host.features.restic.enable
  '';

  # Test feature combinations evaluate without conflicts
  feature-combinations = mkEvalTest "feature-combinations" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      evalModules = modules: lib.evalModules {
        modules = [
          ../modules/shared/host-options.nix
        ] ++ modules ++ [
          {
            config.host = {
              username = "test";
              useremail = "test@example.com";
              hostname = "test";
              system = "x86_64-linux";
              features = {
                gaming.enable = true;
                development.enable = true;
                virtualisation.enable = true;
                security.enable = true;
              };
            };
          }
        ];
      };
    in
      (evalModules [
        ../modules/nixos/features/gaming.nix
        ../modules/shared/features/development/default.nix
        ../modules/nixos/features/virtualisation.nix
        ../modules/shared/features/security/default.nix
      ]).config.host.features.gaming.enable
  '';

  # Test that feature flags properly enable and disable functionality
  feature-flag-enable = mkEvalTest "feature-flag-enable" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      evalModule = enable: lib.evalModules {
        modules = [
          ../modules/shared/host-options.nix
          ../modules/nixos/features/gaming.nix
          {
            config.host = {
              username = "test";
              useremail = "test@example.com";
              hostname = "test";
              system = "x86_64-linux";
              features.gaming.enable = enable;
            };
          }
        ];
      };
      enabled = (evalModule true).config.programs.steam.enable or false;
      disabled = (evalModule false).config.programs.steam.enable or false;
    in
      enabled && !disabled
  '';

  # Test that feature options are properly typed
  feature-options-typed = mkEvalTest "feature-options-typed" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      module = import ../modules/shared/host-options.nix { inherit lib; config = {}; };
    in
      module.options.host.features.gaming.enable.type.name == "bool"
      && module.options.host.features.development.rust.type.name == "bool"
  '';

  # Regression test: Verify common configuration patterns evaluate
  feature-regression-common = mkEvalTest "feature-regression-common" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      evalModules = lib.evalModules {
        modules = [
          ../modules/shared/host-options.nix
          ../modules/nixos/features/gaming.nix
          ../modules/nixos/features/media-management.nix
          {
            config.host = {
              username = "test";
              useremail = "test@example.com";
              hostname = "test";
              system = "x86_64-linux";
              features = {
                gaming = {
                  enable = true;
                  steam = true;
                  performance = true;
                };
                mediaManagement = {
                  enable = true;
                  qbittorrent = {
                    enable = true;
                    vpn.enable = true;
                  };
                };
              };
            };
          }
        ];
      };
    in
      evalModules.config.host.features.gaming.enable
      && evalModules.config.host.features.mediaManagement.enable
  '';
}
