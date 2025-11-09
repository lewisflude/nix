{
  inputs,
  hosts,
}:
let
  nixpkgs = inputs.nixpkgs or (throw "nixpkgs input is required");
  pre-commit-hooks = inputs.pre-commit-hooks or (throw "pre-commit-hooks input is required");

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
          deadnix.enable = true;
          statix.enable = true;
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
