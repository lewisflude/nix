{
  inputs,
  hosts,
}:
let
  # Access required inputs with error if missing
  nixpkgs = inputs.nixpkgs or (throw "nixpkgs input is required");
  pre-commit-hooks = inputs.pre-commit-hooks or (throw "pre-commit-hooks input is required");
  home-manager = inputs.home-manager or null;

  virtualisationLib = import ./virtualisation.nix { inherit (nixpkgs) lib; };
  functionsLib = import ./functions.nix { inherit (nixpkgs) lib; };
  systems = builtins.attrValues (builtins.mapAttrs (_name: host: host.system) hosts);

  # Get Python packages from nixpkgs for a given system
  # Uses Python 3.12 as the default version (standard nixpkgs packages, well-cached)
  getPythonPackages = system: nixpkgs.legacyPackages.${system}.python312.pkgs;
in
{
  mkFormatters = nixpkgs.lib.genAttrs systems (system: nixpkgs.legacyPackages.${system}.nixfmt);
  mkChecks = nixpkgs.lib.genAttrs systems (
    system:
    let
      pythonPackages = getPythonPackages system;
    in
    {
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          # Nix formatting and linting
          nixfmt.enable = true;
          alejandra.enable = false; # Explicitly disable alejandra, use nixfmt only
          deadnix.enable = true;
          statix.enable = true;

          # Conventional commits enforcement
          commitizen.enable = true;

          # General code quality
          trailing-whitespace = {
            enable = true;
            entry = "${pythonPackages.pre-commit-hooks}/bin/trailing-whitespace-fixer";
            types = [ "text" ];
          };
          end-of-file-fixer = {
            enable = true;
            entry = "${pythonPackages.pre-commit-hooks}/bin/end-of-file-fixer";
            types = [ "text" ];
          };
          mixed-line-ending = {
            enable = true;
            entry = "${pythonPackages.pre-commit-hooks}/bin/mixed-line-ending";
            types = [ "text" ];
          };

          # YAML validation
          check-yaml = {
            enable = true;
            entry = "${pythonPackages.pre-commit-hooks}/bin/check-yaml";
            types = [ "yaml" ];
            excludes = [ "secrets/.*\\.yaml$" ];
          };

          # Markdown formatting
          markdownlint = {
            enable = true;
            entry = "${nixpkgs.legacyPackages.${system}.markdownlint-cli}/bin/markdownlint --fix";
            types = [ "markdown" ];
          };
        };
      };

      # nixosTests-mcp = import ../tests/integration/mcp.nix {
      #   inherit pkgs;
      #   lib = nixpkgs.lib;
      #   inputs = inputs;
      # };
    }
  );
  # Build a single Home Manager configuration using perSystem pkgs
  # This follows flake-parts best practices: use withSystem to access perSystem definitions
  mkHomeConfigurationForHost =
    {
      hostConfig,
      perSystemPkgs,
    }:
    (
      if home-manager == null then
        throw "home-manager input is required for mkHomeConfigurationForHost"
      else
        home-manager.lib.homeManagerConfiguration
    )
      {
        # Use pkgs from perSystem instead of importing nixpkgs separately
        # This ensures consistency with perSystem definitions
        pkgs = perSystemPkgs;
        extraSpecialArgs = functionsLib.mkHomeManagerExtraSpecialArgs {
          inherit inputs hostConfig virtualisationLib;
          includeUserFields = false;
        };
        modules = [
          ../home
        ]
        ++ nixpkgs.lib.optionals (inputs ? niri && inputs.niri ? homeModules) [
          inputs.niri.homeModules.niri
        ]
        ++ nixpkgs.lib.optionals (inputs ? sops-nix && inputs.sops-nix ? homeManagerModules) [
          inputs.sops-nix.homeManagerModules.sops
        ]
        ++ nixpkgs.lib.optionals (inputs ? catppuccin && inputs.catppuccin ? homeModules) [
          inputs.catppuccin.homeModules.catppuccin
        ]
        ++ [
          { _module.args = { inherit inputs; }; }
        ];
      };

  # Legacy function for backward compatibility (deprecated: use mkHomeConfigurationForHost with withSystem)
  mkHomeConfigurations = builtins.mapAttrs (
    _name: hostConfig:
    let
      pkgs = import nixpkgs {
        inherit (hostConfig) system;
        config = functionsLib.mkPkgsConfig;
        overlays = functionsLib.mkOverlays {
          inherit inputs;
          inherit (hostConfig) system;
        };
      };
    in
    (
      if home-manager == null then
        throw "home-manager input is required for mkHomeConfigurations"
      else
        home-manager.lib.homeManagerConfiguration
    )
      {
        inherit pkgs;
        extraSpecialArgs = functionsLib.mkHomeManagerExtraSpecialArgs {
          inherit inputs hostConfig virtualisationLib;
          includeUserFields = false;
        };
        modules = [
          ../home
        ]
        ++ nixpkgs.lib.optionals (inputs ? niri && inputs.niri ? homeModules) [
          inputs.niri.homeModules.niri
        ]
        ++ nixpkgs.lib.optionals (inputs ? sops-nix && inputs.sops-nix ? homeManagerModules) [
          inputs.sops-nix.homeManagerModules.sops
        ]
        ++ nixpkgs.lib.optionals (inputs ? catppuccin && inputs.catppuccin ? homeModules) [
          inputs.catppuccin.homeModules.catppuccin
        ]
        ++ [
          { _module.args = { inherit inputs; }; }
        ];
      }
  ) hosts;
}
