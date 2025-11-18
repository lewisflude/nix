let
  defaultFeatures = import ../_common/features.nix;
in
{

  username = "lewisflude";
  useremail = "lewis@lewisflude.com";
  system = "aarch64-darwin";
  hostname = "mercury";

  features = defaultFeatures // {
    productivity = defaultFeatures.productivity // {
      enable = true;
      notes = true;
      resume = true;
    };
  };
}
