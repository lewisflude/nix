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
    # Nix
    nil # Nix LSP
    nixfmt-rfc-style # Nix formatter

    # JavaScript/TypeScript
    biome # JS/TS formatter/linter

    # Markdown
    marksman # Markdown LSP

    # Python
    pyright # Python LSP

    # Lua (Love2D development)
    lua-language-server # Lua LSP
    stylua # Lua formatter
    selene # Lua linter
    luaPackages.luacheck # Lua static analyzer
  ];
}
