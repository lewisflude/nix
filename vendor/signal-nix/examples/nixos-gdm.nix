# Signal Design System - NixOS GDM Example
#
# This example shows how to enable GDM (GNOME Display Manager) theming
# with Signal colors. GDM is the default login screen for GNOME.

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
            # Signal GDM Configuration
            # =================================================================

            theming.signal.nixos = {
              enable = true;
              mode = "dark"; # or "light"

              # Enable GDM display manager theming
              login.gdm = {
                enable = true;

                # Optional: Custom background image for login screen
                # backgroundImage = ./path/to/background.png;
              };
            };

            # =================================================================
            # System Configuration (you must enable GDM separately)
            # =================================================================

            # Enable GDM display manager
            services.xserver = {
              enable = true;
              displayManager.gdm.enable = true;

              # Example: Enable GNOME desktop
              desktopManager.gnome.enable = true;
            };

            # =================================================================
            # Example: Complete GNOME setup with Signal theming
            # =================================================================
            # Note: Commented out to avoid duplicate attribute definition
            # In practice, you would merge this with the configuration above

            /*
              # Alternative comprehensive configuration:
              theming.signal.nixos = {
                enable = true;
                mode = "dark";

                # Boot theming
                boot = {
                  console.enable = true; # TTY colors
                  plymouth.enable = true; # Boot splash
                };

                # Login screen theming
                login.gdm.enable = true; # GDM login screen
              };
            */

            # Home Manager integration (optional, for user-level theming)
            # home-manager.users.yourname = {
            #   imports = [ signal.homeManagerModules.default ];
            #
            #   theming.signal = {
            #     enable = true;
            #     autoEnable = true;
            #     mode = "dark";
            #   };
            #
            #   programs.helix.enable = true;
            #   programs.kitty.enable = true;
            # };

            # System version
            system.stateVersion = "24.11";
          }
        ];
      };
    };
}
