# Nicotine+ — Soulseek client.
# nicotine-plus supports aarch64-darwin as well as Linux, so no platform guard.
_: {
  flake.modules.homeManager.nicotinePlus =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.nicotine-plus ];
    };
}
