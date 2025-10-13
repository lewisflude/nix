# NixOS host configuration for Jupiter workstation
{
  # System identification
  username = "lewis";
  useremail = "lewis@lewisflude.com";
  system = "x86_64-linux";
  hostname = "jupiter";

  # Feature configuration
  features = {
    development = {
      enable = true;
      rust = true;
      python = true;
      go = true;
      node = true;
      docker = true;
    };

    gaming = {
      enable = true;
      steam = true;
      performance = true;
    };

    virtualisation = {
      enable = true;
      docker = true;
      podman = true;
    };

    homeServer = {
      enable = true;
      homeAssistant = false;
      fileSharing = true;
    };

    desktop = {
      enable = true;
      niri = true;
      theming = true;
    };

    security = {
      enable = true;
      yubikey = true;
      gpg = true;
    };

    audio = {
      enable = true;
      realtime = true;
    };
  };
}
