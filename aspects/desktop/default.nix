# Desktop Aspect
#
# Combines all desktop-related configuration in a single directory.
# Reads options from config.host.features.desktop (defined in modules/shared/host-options/features/desktop.nix)
#
# Platform support:
# - NixOS: Full desktop environment (Niri, greetd, fonts, graphics, XWayland)
# - Darwin: Not applicable (macOS uses native desktop environment)
#
# Sub-modules:
# - desktop-environment.nix: UWSM, seatd, session management
# - fonts.nix: Font configuration and packages
# - graphics.nix: NVIDIA/GPU configuration
# - hardware-support.nix: Thunderbolt, backlight, geoclue
# - niri.nix: Niri compositor configuration
# - theme.nix: Signal theming
# - xwayland.nix: XWayland support
# - greeter.nix: ReGreet/DMS greeter configuration
# - console.nix: Console font and early boot
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.host.features.desktop;
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  imports = [
    ./desktop-environment.nix
    ./fonts.nix
    ./graphics.nix
    ./hardware-support.nix
    ./niri.nix
    ./theme.nix
    ./xwayland.nix
    ./greeter.nix
    ./console.nix
  ];

  config = lib.mkMerge [
    # ================================================================
    # NixOS Configuration - User groups
    # ================================================================
    (lib.mkIf (cfg.enable && isLinux) {
      users.users.${config.host.username}.extraGroups = [
        "audio"
        "video"
        "input"
        "networkmanager"
        "seat" # Required for seatd.sock access (Wayland seat management)
      ];
    })

    # ================================================================
    # Darwin Configuration
    # ================================================================
    (lib.mkIf (cfg.enable && isDarwin) {
      # macOS uses native desktop environment
      # This is a no-op placeholder
    })

    # ================================================================
    # Assertions (both platforms)
    # ================================================================
    {
      assertions = [
        {
          assertion = !(cfg.enable && isDarwin);
          message = "Desktop feature is NixOS-only (macOS uses native desktop environment)";
        }
      ];
    }
  ];
}
