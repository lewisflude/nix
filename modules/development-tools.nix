# Development tools - Formatters, linters, and language standards
{ inputs, ... }:
{
  # Rust toolchains from fenix (fresher than nixpkgs)
  overlays.fenix = inputs.fenix.overlays.default;

  flake.modules.homeManager.developmentTools =
    { lib, pkgs, ... }:
    {
      home.packages = [
        # Development environments
        pkgs.devenv

        # Formatters
        pkgs.nixfmt
        pkgs.biome
        pkgs.taplo
        pkgs.yamlfmt

        # Linters
        pkgs.luaPackages.luacheck
        (lib.lowPrio pkgs.lua)

        # Database clients
        # pgcli's test suite aborts on Darwin/Python 3.14 with a libffi
        # trampoline assertion (closures.c:258); the package itself is fine,
        # so skip the checks.
        (pkgs.pgcli.overridePythonAttrs (_: {
          doCheck = false;
        }))

        # AI-assisted editors
        pkgs.cursor-cli
      ];
    };
}
