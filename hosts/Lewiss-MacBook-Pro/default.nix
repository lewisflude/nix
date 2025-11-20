let
  defaultFeatures = import ../_common/features.nix;
in
{

  username = "lewisflude";
  useremail = "lewis@lewisflude.com";
  system = "aarch64-darwin";
  hostname = "Lewiss-MacBook-Pro";

  features = defaultFeatures // {
    restic = defaultFeatures.restic // {
      enable = true;
    };
    productivity = defaultFeatures.productivity // {
      enable = true;
      notes = true;
      resume = true;
    };
  };
}
