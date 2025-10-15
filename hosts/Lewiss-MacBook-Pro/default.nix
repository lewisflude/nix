# Darwin host configuration for Lewis's MacBook Pro
let
  defaultFeatures = import ../_common/features.nix;
in {
  # System identification
  username = "lewisflude";
  useremail = "lewis@lewisflude.com";
  system = "aarch64-darwin";
  hostname = "Lewiss-MacBook-Pro";

  # Feature configuration
  features =
    defaultFeatures
    // {
      productivity = defaultFeatures.productivity // {
        enable = true;
        notes = true;
      };
    };
}
