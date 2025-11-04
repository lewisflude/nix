{
  lib,
  host,
  pkgs,
  ...
}: let
  cfg = host.features.development;
in {
  home.packages = with pkgs;
    [
      # Nix tools
      nixfmt-rfc-style
      nixd

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
    ]
    ++ lib.optionals cfg.python [
      python313
      python313Packages.pip
      python313Packages.virtualenv
      python313Packages.uv
      ruff
      pyright
    ]
    ++ lib.optionals cfg.go [
      go
      gopls
      gotools
      go-tools
    ]
    ++ lib.optionals cfg.node [
      nodejs_24
    ]
    ++ lib.optionals cfg.lua [
      luajit # Primary Lua interpreter (provides /bin/lua)
      (pkgs.lowPrio lua) # Fallback Lua 5.2 (lower priority to avoid conflict)
      luajitPackages.luarocks
      lua-language-server
    ];
}
