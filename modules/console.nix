# Console Configuration
# Early boot console font and theming
_: {
  flake.modules.nixos.console =
    { pkgs, ... }:
    {
      console = {
        font = "ter-v22n";
        packages = [ pkgs.terminus_font ];
        earlySetup = true;
      };
    };
}
