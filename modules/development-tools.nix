# Development tools - Formatters, linters, and language standards
_: {
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
      ];
    };
}
