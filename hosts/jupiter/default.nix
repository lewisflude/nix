# NixOS host configuration for Jupiter workstation
let
  defaultFeatures = import ../_common/features.nix;
in {
  # System identification
  username = "lewis";
  useremail = "lewis@lewisflude.com";
  system = "x86_64-linux";
  hostname = "jupiter";

  # Feature configuration
  features =
    defaultFeatures
    // {
      development =
        defaultFeatures.development
        // {
          docker = true;
        };

      gaming =
        defaultFeatures.gaming
        // {
          enable = true;
          steam = true;
          performance = true;
        };

      virtualisation =
        defaultFeatures.virtualisation
        // {
          enable = true;
          docker = true;
          podman = true;
        };

      homeServer =
        defaultFeatures.homeServer
        // {
          enable = true;
          fileSharing = true;
        };

      desktop =
        defaultFeatures.desktop
        // {
          niri = true;
        };

      audio =
        defaultFeatures.audio
        // {
          enable = true;
          realtime = true;
        };
    };
}
