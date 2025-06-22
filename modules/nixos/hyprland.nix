{ pkgs, lib, config, hyprland, system, ... }:
{
  # Enable Hyprland with UWSM
  programs.hyprland = {
    enable = true;
    package = hyprland.packages.${system}.hyprland;
    portalPackage = hyprland.packages.${system}.xdg-desktop-portal-hyprland;
  };

  # UWSM (Universal Wayland Session Manager)
  programs.uwsm = {
    enable = true;
    waylandCompositors = {
      hyprland = {
        prettyName = "Hyprland";
        comment = "Hyprland compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/Hyprland";
      };
    };
  };

  # Required for Wayland and screensharing
  services.dbus.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      hyprland.packages.${system}.xdg-desktop-portal-hyprland
    ];
  };

  # Polkit for authentication
  security.polkit.enable = true;
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # General Wayland configuration
  environment.sessionVariables = {
    # General Wayland settings
    XDG_SESSION_TYPE = "wayland";
    WLR_NO_HARDWARE_CURSORS = "1";
    CLUTTER_BACKEND = "wayland";
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

  # Hardware support
  hardware = {
    # Enable graphics
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    
    # Enable Bluetooth
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  # Fonts for desktop environment
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    font-awesome
    nerd-fonts.iosevka
    nerd-fonts.jetbrains-mono
  ];

  # Security settings for desktop environment
  security = {
    pam.services.swaylock = {};
    rtkit.enable = true;  # For real-time audio processing
  };
}