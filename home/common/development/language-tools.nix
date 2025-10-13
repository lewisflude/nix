{pkgs, ...}: {
  home.packages = with pkgs; [
    # Nix tools
    nixfmt-rfc-style
    nil

    # General formatters/linters
    biome
    taplo
    marksman

    # Python tools (duplicates removed - managed by feature flags)
    # pyright - installed by modules/shared/features/development.nix
    black

    # Lua tools (duplicates removed - managed by feature flags)
    # lua-language-server - installed by modules/shared/features/development.nix
    stylua
    selene
    luaPackages.luacheck

    # Debugger
    lldb
  ];
}
