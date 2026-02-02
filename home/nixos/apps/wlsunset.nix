{ ... }:
{
  # Disabled: DMS Night Light handles gamma control for blue light reduction
  # DMS provides unified theming and coordinates-based scheduling
  # See: home/nixos/dank-material-shell.nix settings.nightLight
  services.wlsunset = {
    enable = false;
    # Previous settings preserved for reference:
    # latitude = "51.5";
    # longitude = "-0.1";
    # temperature = { day = 6500; night = 3500; };
  };
}
