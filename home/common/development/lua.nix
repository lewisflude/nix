{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Lua runtime and interpreter
    lua

    # Love2D game framework
    love

    # Additional Lua packages
    luarocks # Lua package manager

    lua54Packages.busted
  ];
}
