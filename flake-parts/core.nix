{
  inputs,
  self,
  withSystem,
  ...
}:
let
  nixpkgs = inputs.nixpkgs or (throw "nixpkgs input is required");
  inherit (nixpkgs) lib;

  hostsConfig = import ../lib/hosts.nix { inherit lib; };
  inherit (hostsConfig) hosts;

  functionsLib = import ../lib/functions.nix { inherit lib; };

  systemBuilders = import ../lib/system-builders.nix {
    inherit inputs;
  };

  outputBuilders = import ../lib/output-builders.nix {
    inputs = inputs // {
      inherit self;
    };
    inherit hosts;
  };
in
{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  perSystem =
    {
      config,
      system,
      ...
    }:
    let
      nixpkgs = inputs.nixpkgs or (throw "nixpkgs input is required");
      pkgsWithOverlays = import nixpkgs {
        inherit system;
        overlays = functionsLib.mkOverlays { inherit inputs system; };
        config = functionsLib.mkPkgsConfig;
      };

      pogOverlay =
        if
          inputs ? pog
          && inputs.pog ? overlays
          && inputs.pog.overlays ? ${system}
          && inputs.pog.overlays.${system} ? default
        then
          inputs.pog.overlays.${system}.default
        else
          (_final: _prev: { });
      shellsConfig = import ../shells {
        pkgs = pkgsWithOverlays.extend pogOverlay;
        inherit (pkgsWithOverlays) lib;
        inherit system;
      };
    in
    {
      _module.args.pkgs = pkgsWithOverlays;

      formatter = pkgsWithOverlays.nixfmt-rfc-style;

      checks = outputBuilders.mkChecks.${system} or { };

      devShells = shellsConfig.devShells // {
        default = pkgsWithOverlays.mkShell {
          shellHook = config.checks.pre-commit-check.shellHook or "";
          buildInputs =
            (config.checks.pre-commit-check.enabledPackages or [ ])
            ++ (with pkgsWithOverlays; [
              jq
              yq
              git
              gh
              direnv
              nix-direnv
              nix-update
            ]);
        };
      };

      apps =
        let
          pkgsWithPog = pkgsWithOverlays.extend pogOverlay;

          mkPogApp =
            script-name:
            let
              needsConfigRoot = lib.elem script-name [
                "new-module"
                "update-all"
                "visualize-modules"
              ];
              scriptArgs =
                if needsConfigRoot then
                  {
                    config-root = toString ../..;
                  }
                else
                  {
                  };
              descriptions = {
                "new-module" = "Scaffold new NixOS/home-manager modules";
                "setup-cachix" = "Configure Cachix binary cache";
                "update-all" = "Update all flake dependencies";
                "cleanup-duplicates" = "Remove old/unused package versions from Nix store";
                "analyze-services" = "Analyze Nix store service usage";
                "visualize-modules" = "Generate module dependency graphs";
              };
            in
            {
              type = "app";
              program = "${pkgsWithPog.callPackage ../pkgs/pog-scripts/${script-name}.nix scriptArgs}/bin/${script-name}";
              meta.description = descriptions.${script-name} or "POG script: ${script-name}";
            };
        in
        {
          new-module = mkPogApp "new-module";
          setup-cachix = mkPogApp "setup-cachix";
          update-all = mkPogApp "update-all";
          cleanup-duplicates = mkPogApp "cleanup-duplicates";
          analyze-services = mkPogApp "analyze-services";
          visualize-modules = mkPogApp "visualize-modules";
        };

      topology.modules =
        if system == "x86_64-linux" || system == "aarch64-linux" then
          [
            {
              inherit (self) nixosConfigurations;
            }
          ]
        else
          [ ];
    };

  _module.args = {
    inherit
      hosts
      hostsConfig
      systemBuilders
      outputBuilders
      ;
  };

  flake =
    let
      darwinHosts = hostsConfig.getDarwinHosts hosts;
      darwinConfigurations = builtins.mapAttrs (
        hostName: hostConfig:
        withSystem hostConfig.system (
          _:
          systemBuilders.mkDarwinSystem hostName hostConfig {
            inherit (inputs) homebrew-j178;
          }
        )
      ) darwinHosts;

      nixosHosts = hostsConfig.getNixosHosts hosts;
      nixosConfigurations = builtins.mapAttrs (
        hostName: hostConfig:
        withSystem hostConfig.system (
          _:
          systemBuilders.mkNixosSystem hostName hostConfig {
            inherit self;
          }
        )
      ) nixosHosts;

      homeConfigurations = builtins.mapAttrs (
        _hostName: hostConfig:
        withSystem hostConfig.system (
          { config, ... }:
          outputBuilders.mkHomeConfigurationForHost {
            inherit hostConfig;
            perSystemPkgs = config.pkgs;
          }
        )
      ) hosts;
    in
    {
      inherit
        darwinConfigurations
        nixosConfigurations
        homeConfigurations
        ;
      lib = functionsLib;

      overlays.default =
        final: prev:
        let
          inherit (prev.stdenv.hostPlatform) system;
          overlaySet = import ../overlays {
            inherit inputs system;
          };
          overlayList = builtins.attrValues overlaySet;
          inherit (prev.lib) composeExtensions foldl';
        in
        (foldl' composeExtensions (_: _: { }) overlayList) final prev;
    };
}
