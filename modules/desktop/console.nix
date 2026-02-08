# Console Configuration
# Early boot console font and theming
{ config, ... }:
{
  flake.modules.nixos.console =
    { pkgs, lib, ... }:
    {
      console = {
        font = "ter-v22n";
        packages = [ pkgs.terminus_font ];
        earlySetup = true;
      };
    };
}
