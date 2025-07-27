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
    # C++ development tools for Unreal Engine
    clang-tools # Provides clangd and clang-format
    lldb # Debugger for C++
  ];
}
