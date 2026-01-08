{
  inputs,
  hosts,
}:
let
  inherit (inputs) nixpkgs;
  inherit (inputs) pre-commit-hooks;

  systems = builtins.attrValues (builtins.mapAttrs (_name: host: host.system) hosts);

  getPythonPackages = system: nixpkgs.legacyPackages.${system}.python312.pkgs;
in
{
  mkFormatters = nixpkgs.lib.genAttrs systems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
  mkChecks = nixpkgs.lib.genAttrs systems (
    system:
    let
      pythonPackages = getPythonPackages system;
    in
    {
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          nixfmt.enable = true;
          alejandra.enable = false;
          deadnix = {
            enable = true;
            # Configuration is in .deadnix.toml at project root
            # This enables no_lambda_arg to work with statix's preference for { ... } patterns
          };
          statix = {
            enable = true;
            entry = "${nixpkgs.legacyPackages.${system}.statix}/bin/statix check --format errfmt";
            # Ignores are configured in statix.toml
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
}
