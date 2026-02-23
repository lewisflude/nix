# ia-get - Internet Archive download tool
{ inputs, ... }:
{
  flake.modules.homeManager.iaGet =
    { pkgs, ... }:
    {
      home.packages = [
        inputs.ia-get.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
