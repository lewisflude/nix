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

      restic =
        defaultFeatures.restic
        // {
          enable = true;
          restServer =
            defaultFeatures.restic.restServer
            // {
              enable = true;
              port = 8000;
            };
        };

      audio =
        defaultFeatures.audio
        // {
          enable = true;
          realtime = true;
        };

      containers =
        defaultFeatures.containers
        // {
          # TEST MODE: Enable this first to verify Podman works
          # Once test passes, disable test mode and enable stacks below
          enable = true;

          mediaManagement = {
            enable = true; # Enable for media stack (Radarr, Sonarr, etc.)
            dataPath = "/mnt/storage";
            configPath = "/var/lib/containers/media-management";
          };

          productivity = {
            enable = false; # Enable for AI tools (Ollama, ComfyUI, etc.)
            configPath = "/var/lib/containers/productivity";
          };
        };
    };
}
