# Desktop feature module (cross-platform)
# Controlled by host.features.desktop.*
# Provides desktop environment, theming, and utilities coordination
{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.lists) optional optionals;
  cfg = config.host.features.desktop;
  platformLib = (import ../../../../lib/functions.nix {inherit lib;}).withSystem hostSystem;
  inherit (platformLib) isLinux;
in {
  config = mkIf cfg.enable {
    # NixOS-specific desktop configuration
    # Note: Actual compositor configuration (Niri, Hyprland) is handled
    # in modules/nixos/features/desktop/ for platform-specific setup

    # System-level packages (NixOS only)
    environment.systemPackages = mkIf isLinux (
      with pkgs;
        optionals cfg.utilities [
          # Screenshot tools
          grim # Screenshot tool for Wayland
          slurp # Region selector for Wayland
          wl-clipboard # Clipboard for Wayland
          # Display management
          wlr-randr # Display management for Wayland
          brightnessctl # Brightness control
          # XDG utilities
          xdg-utils # Desktop integration
          # Color management
          argyllcms # Color management
          colord-gtk # Color daemon GUI
          wl-gammactl # Gamma control for Wayland
        ]
    );

    # User groups for desktop access (NixOS only)
    users.users.${config.host.username}.extraGroups = mkIf isLinux (
      [
        "audio"
        "video"
        "input"
        "networkmanager"
      ]
      ++ optional cfg.niri "render" # Niri-specific group if needed
    );

    # Assertions
    assertions = [
      {
        assertion = cfg.niri -> !cfg.hyprland || isLinux;
        message = "Niri and Hyprland cannot both be enabled";
      }
      {
        assertion = cfg.theming -> cfg.enable;
        message = "Theming requires desktop feature to be enabled";
      }
    ];
  };
}
