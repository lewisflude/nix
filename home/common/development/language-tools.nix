{pkgs, ...}: {
  home.packages = with pkgs; [
    nixfmt-rfc-style
    nil
    biome
    taplo
    marksman
    pyright
    black
    lldb
    nil
    nixfmt-rfc-style
    biome
    marksman
    pyright
    lua-language-server
    stylua
    selene
    luaPackages.luacheck
  ];
}
