_: {
  flake.modules.homeManager.nicotinePlus =
    { pkgs, lib, ... }:
    {
      home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.nicotine-plus ];
    };
}
