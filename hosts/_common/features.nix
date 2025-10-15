# Shared feature defaults for all hosts
# Hosts can import this set and override only host-specific toggles
{
  development = {
    enable = true;
    rust = true;
    python = true;
    go = true;
    node = true;
    lua = false;
    docker = false;
  };

  gaming = {
    enable = false;
    steam = false;
    lutris = false;
    emulators = false;
    performance = false;
  };

  virtualisation = {
    enable = false;
    docker = false;
    podman = false;
    qemu = false;
    virtualbox = false;
  };

  homeServer = {
    enable = false;
    homeAssistant = false;
    mediaServer = false;
    fileSharing = false;
    backups = false;
  };

  desktop = {
    enable = true;
    niri = false;
    hyprland = false;
    theming = true;
    utilities = false;
  };

  productivity = {
    enable = false;
    office = false;
    notes = false;
    email = false;
    calendar = false;
  };

  audio = {
    enable = false;
    production = false;
    realtime = false;
    streaming = false;
  };

  security = {
    enable = true;
    yubikey = true;
    gpg = true;
    vpn = false;
    firewall = false;
  };
}
