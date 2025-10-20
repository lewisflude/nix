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
          lua = true;
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
          utilities = true;
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
          production = true;
          audioNix = {
            enable = false; # TODO: Temporarily disabled due to webkitgtk dependency issue
            bitwig = true;
            plugins = true;
          };
        };

      productivity =
        defaultFeatures.productivity
        // {
          enable = true;
          office = true;
          notes = true;
          email = true;
          calendar = true;
        };

      # DEPRECATED: Legacy container services - migrate to native modules
      containers =
        defaultFeatures.containers
        // {
          enable = false; # Disabled - using native modules instead
        };

      # Native media management services (preferred approach)
      mediaManagement =
        defaultFeatures.mediaManagement
        // {
          enable = true;
          dataPath = "/mnt/storage";
          timezone = "Europe/London";

          # All services enabled by default except whisparr
          # To disable specific services, set enable = false
          # whisparr.enable = false; # Adult content - disabled by default
        };

      # Native AI tools services (Ollama, Open WebUI)
      aiTools =
        defaultFeatures.aiTools
        // {
          enable = true;
          ollama = {
            enable = true;
            acceleration = "cuda"; # NVIDIA GPU acceleration
            models = ["llama2"]; # Pre-download models on first boot
          };
          openWebui = {
            enable = true;
            port = 7000;
          };
        };

      # Supplemental container services (no native modules available yet)
      containersSupplemental =
        defaultFeatures.containersSupplemental
        // {
          enable = true;
          homarr.enable = true; # Dashboard
          wizarr.enable = true; # Invitation system
          doplarr.enable = false; # Discord bot (requires secrets)
          comfyui.enable = true; # AI image generation (NVIDIA GPU)

          # Cal.com configuration with sops-nix for secrets
          calcom = {
            enable = true;
            useSops = true; # Use sops-nix for production secrets
            # Secrets are stored in secrets/secrets.yaml:
            # - calcom-nextauth-secret
            # - calcom-encryption-key
            # - calcom-db-password
            # Run: sops secrets/secrets.yaml to add them
          };
        };
    };
}
