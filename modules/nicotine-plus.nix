_: {
  flake.modules.homeManager.nicotinePlus =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.nicotine-plus ];
    };
}
