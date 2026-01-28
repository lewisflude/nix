{
  config,
  lib,
  ...
}:
{
  config = {
    nix.optimise = lib.mkIf config.nix.enable {
      automatic = true;
      dates = [ "03:45" ];
    };
  };
}
