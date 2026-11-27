# ia-get - Internet Archive download tool
{ inputs, ... }:
{
  flake.modules.homeManager.iaGet =
    { pkgs, ... }:
    {
      home.packages = [
        # Test suite binds localhost mock servers; the Darwin sandbox denies
        # that unless local networking is explicitly allowed.
        (inputs.ia-get.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs {
          __darwinAllowLocalNetworking = true;
        })
      ];
    };
}
