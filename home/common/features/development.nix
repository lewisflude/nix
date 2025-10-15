{
  lib,
  host,
  pkgs,
  ...
}: let
  cfg = host.features.development;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs;
      [
        git
        gh
        curl
        wget
        jq
        yq
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
        lua
        luajit
        luajitPackages.luarocks
        lua-language-server
      ];
  };
}
