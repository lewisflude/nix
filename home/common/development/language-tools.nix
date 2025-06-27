{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nixfmt-rfc-style
    nil
    biome
    taplo
    marksman
    pyright
    black
  ];
}
