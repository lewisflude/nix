{
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [

    biome
    taplo
    marksman

    luaPackages.luacheck

    (lib.lowPrio lua)
  ]

  ;
}
