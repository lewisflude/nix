# Mouse hardware support (Logitech, gaming mice)
_: {
  flake.modules.nixos.mouse = {
    # Solaar ships in nixpkgs as programs.solaar (upstreamed from the
    # Svenum/Solaar-Flake input this used to pull in — keeping both declared
    # programs.solaar twice and broke evaluation).
    programs.solaar = {
      enable = true;
      userService = {
        enable = true;
        window = "hide";
        batteryIcons = "regular";
      };
    };
    services.ratbagd.enable = true;
  };
}
