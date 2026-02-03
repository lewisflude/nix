# Development tools - Formatters, linters, and language standards
{ config, ... }:
{
  flake.modules.homeManager.developmentTools =
    { lib, pkgs, ... }:
    {
      home.packages = [
        # Formatters
        pkgs.nixfmt
        pkgs.biome
        pkgs.taplo
        pkgs.yamlfmt
        pkgs.gotools # Includes goimports
        pkgs.clang-tools # Includes clang-format

        # Linters
        pkgs.luaPackages.luacheck

        (lib.lowPrio pkgs.lua)
      ];
    };
}
