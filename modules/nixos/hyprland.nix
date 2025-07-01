{
  pkgs,
  hyprland,
  system,
  ...
}:
{
  # Enable Hyprland with UWSM
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland = {
      enable = true;
    };
    package = hyprland.packages.${system}.hyprland;
    portalPackage = hyprland.packages.${system}.xdg-desktop-portal-hyprland;
  };
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [
          "hyprland"
        ];
      };
    };
  };

  # Required packages for Hyprland desktop environment
  environment.systemPackages = with pkgs; [
    # Core Wayland tools
    wl-clipboard
    wlr-randr
    wayland-utils

    # Screenshot tools
    grim
    slurp
    swappy

    # Authentication and permissions
    polkit_gnome

    # Brightness control
    brightnessctl

    # System utilities
    playerctl
    pavucontrol

    # File manager integration
    xdg-utils
  ];

  # Enable required services
  services = {
    # Required for brightness control
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", GROUP="video", MODE="0664"
    '';

    # Enable location service for night light
    geoclue2.enable = true;
  };
}
