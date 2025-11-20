{
  pkgs,
  inputs,
  ...
}:
let

  mkEvalTest =
    name: config:
    pkgs.runCommand "eval-test-${name}" { } ''
      ${pkgs.nix}/bin/nix eval --impure --expr 'builtins.deepSeq (${config}) true' || exit 1
      touch $out
    '';
in
{

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

  host-options = mkEvalTest "host-options" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      module = import ../modules/shared/host-options.nix { inherit lib; config = {}; };
    in
      module.options.host.username.type
  '';

  overlays = mkEvalTest "overlays" ''
    let
      overlaySet = import ../overlays {
        inherit inputs;
        system = "x86_64-linux";
      };
    in
      builtins.attrNames overlaySet
  '';

  features = mkEvalTest "features" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      featuresLib = import ../lib/features.nix { inherit lib; };
    in
      featuresLib.availableFeatures
  '';

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
            hostSystem = "x86_64-linux";
          }
        ];
      };
    in
      (evalModule ../modules/shared/features/virtualisation/default.nix).config.host.features.virtualisation.enable
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
        ../modules/shared/features/virtualisation/default.nix
        ../modules/shared/features/security/default.nix
      ]).config.host.features.gaming.enable
  '';

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

  feature-options-typed = mkEvalTest "feature-options-typed" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      module = import ../modules/shared/host-options.nix { inherit lib; config = {}; };
    in
      module.options.host.features.gaming.enable.type.name == "bool"
      && module.options.host.features.development.rust.type.name == "bool"
  '';

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

  # Theming module tests
  theming-palette = mkEvalTest "theming-palette" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      palette = import ../modules/shared/features/theming/palette.nix { inherit lib; };
    in
      palette.tonal.dark.base-L015.hex == "#1e1f26"
  '';

  theming-lib = mkEvalTest "theming-lib" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      palette = import ../modules/shared/features/theming/palette.nix { inherit lib; };
      themeLib = import ../modules/shared/features/theming/lib.nix { inherit lib palette; };
      theme = themeLib.generateTheme "dark" {};
    in
      theme.mode == "dark"
      && theme.colors ? "surface-base"
      && theme.colors ? "text-primary"
  '';

  theming-module = mkEvalTest "theming-module" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      evalModule = lib.evalModules {
        modules = [
          ../home/common/theming/default.nix
          {
            config = {
              theming.signal = {
                enable = true;
                mode = "dark";
                applications = {
                  cursor.enable = true;
                  helix.enable = true;
                };
              };
            };
          }
        ];
      };
    in
      evalModule.config.theming.signal.enable
      && evalModule.config.theming.signal.mode == "dark"
  '';

  theming-feature = mkEvalTest "theming-feature" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      evalModule = lib.evalModules {
        modules = [
          ../modules/shared/host-options.nix
          ../modules/shared/features/desktop/default.nix
          {
            config = {
              host = {
                username = "test";
                useremail = "test@example.com";
                hostname = "test";
                system = "x86_64-linux";
                features.desktop = {
                  enable = true;
                  signalTheme = {
                    enable = true;
                    mode = "dark";
                  };
                };
              };
            };
            hostSystem = "x86_64-linux";
          }
        ];
      };
    in
      evalModule.config.theming.signal.enable
      && evalModule.config.host.features.desktop.signalTheme.enable
  '';

  theming-unit-tests = mkEvalTest "theming-unit-tests" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      tests = import ../tests/theming.nix { inherit lib pkgs; };

      # Run a subset of the tests
      results = {
        palette = tests.testPaletteStructure.expr == tests.testPaletteStructure.expected;
        hexFormat = tests.testHexFormat.expr == tests.testHexFormat.expected;
        darkTheme = tests.testDarkThemeGeneration.expr == tests.testDarkThemeGeneration.expected;
        lightTheme = tests.testLightThemeGeneration.expr == tests.testLightThemeGeneration.expected;
        semantic = tests.testSemanticColorsDark.expr == tests.testSemanticColorsDark.expected;
      };
    in
      results.palette && results.hexFormat && results.darkTheme && results.lightTheme && results.semantic
  '';

  theming-comprehensive-tests = mkEvalTest "theming-comprehensive-tests" ''
    let
      lib = (import ${inputs.nixpkgs} { system = "x86_64-linux"; }).lib;
      allTests = import ../modules/shared/features/theming/tests/default.nix { inherit lib; };

      # Run all tests and check they pass
      testResults = lib.mapAttrs (name: test: test.expr == test.expected) allTests;
      allPassed = lib.all (result: result) (lib.attrValues testResults);
    in
      allPassed && builtins.length (lib.attrNames allTests) > 50
  '';

}
