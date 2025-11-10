{
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # Formatters
    nixfmt-rfc-style
    biome
    taplo
    yamlfmt
    gotools # Includes goimports
    clang-tools # Includes clang-format

    # Language servers
    marksman

    # Linters
    luaPackages.luacheck

    (lib.lowPrio lua)
  ]

  ;
}
