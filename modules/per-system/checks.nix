# Per-system checks
# Dendritic pattern: Provides pre-commit checks for each system
{ inputs, ... }:
let
  inherit (inputs) nixpkgs;
  inherit (inputs) pre-commit-hooks;
  inherit (nixpkgs) lib;

  # Systems for which we generate checks (matches our hosts: jupiter and mercury)
  systems = [
    "x86_64-linux"
    "aarch64-darwin"
  ];

  getPythonPackages = system: nixpkgs.legacyPackages.${system}.python312.pkgs;

  mkChecks = lib.genAttrs systems (
    system:
    let
      pythonPackages = getPythonPackages system;
    in
    {
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = ../..;
        hooks = {
          nixfmt.enable = true;
          alejandra.enable = false;
          deadnix = {
            enable = true;
            # Configuration is in .deadnix.toml at project root
          };
          statix = {
            enable = true;
            entry = "${nixpkgs.legacyPackages.${system}.statix}/bin/statix check --format errfmt";
          };
          commitizen.enable = true;

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
          check-yaml = {
            enable = true;
            entry = "${pythonPackages.pre-commit-hooks}/bin/check-yaml";
            types = [ "yaml" ];
            excludes = [ "secrets/.*\\.yaml$" ];
          };
          markdownlint = {
            enable = true;
            entry = "${nixpkgs.legacyPackages.${system}.markdownlint-cli}/bin/markdownlint --fix";
            types = [ "markdown" ];
          };
        };
      };
    }
  );
in
{
  perSystem =
    { system, ... }:
    {
      # Checks for this system (pre-commit, tests, etc.)
      checks = mkChecks.${system} or { };
    };
}
