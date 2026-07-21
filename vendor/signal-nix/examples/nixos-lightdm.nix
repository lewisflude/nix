# Signal Design System - NixOS LightDM Example
#
# This example shows how to enable LightDM theming with Signal colors.
# LightDM is a lightweight, fast display manager with GTK greeter support.

{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    signal.url = "github:lewisflude/signal-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      signal,
    }:
    {
      nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          signal.nixosModules.default

          {
            # =================================================================
            # Signal Complete System Theming with LightDM
            # =================================================================

            theming.signal.nixos = {
              enable = true;
              mode = "dark"; # or "light"

              # Boot experience
              boot = {
                console.enable = true; # TTY colors
                grub.enable = true; # GRUB boot menu
                plymouth.enable = true; # Boot splash
              };

              # Login screen with LightDM
              login.lightdm = {
                enable = true;
                # Optional: Custom background image for login screen
                # backgroundImage = ./path/to/background.png;

                # Or use solid color background (default)
                # (if not set, uses Signal surface color)
                # backgroundImage = null;
              };
            };

            # =================================================================
            # System Configuration (you must enable LightDM separately)
            # =================================================================

            # Enable LightDM display manager
            services.xserver = {
              enable = true;
              displayManager.lightdm = {
                enable = true;

                # Enable GTK greeter (required for Signal theming)
                greeters.gtk.enable = true;
              };

              # Example: Enable a desktop environment
              # desktopManager.xfce.enable = true;
              # Or use a window manager
              # windowManager.i3.enable = true;
            };

            # =================================================================
            # Boot configuration (required for GRUB theming)
            # =================================================================

            boot.loader = {
              grub = {
                enable = true;
                device = "/dev/sda"; # or "nodev" for UEFI
              };
            };

            # =================================================================
            # NOTE: Multiple display managers
            # =================================================================
            # You can configure multiple display managers, but only enable one:
            # - theming.signal.nixos.login.lightdm.enable = true; (current)
            # - theming.signal.nixos.login.sddm.enable = true;    (alternative for KDE)
            # - theming.signal.nixos.login.gdm.enable = true;     (alternative for GNOME)

            # System version
            system.stateVersion = "24.11";
          }
        ];
      };
    };
}
