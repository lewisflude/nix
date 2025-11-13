{
  lib,
  pkgs,
  ...
}:
{
  home.packages = [
    # Formatters
    pkgs.nixfmt-rfc-style
    pkgs.biome
    pkgs.taplo
    pkgs.yamlfmt
    pkgs.gotools # Includes goimports
    pkgs.clang-tools # Includes clang-format

    # Language servers
    pkgs.marksman

    # Linters
    pkgs.luaPackages.luacheck

    (lib.lowPrio pkgs.lua)
  ]

  ;
}
