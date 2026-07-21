# Signal Design System - NixOS Plymouth Example
#
# This example shows how to enable Plymouth boot splash theming
# with Signal colors. Plymouth provides a beautiful animated boot screen
# that displays during system startup.

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
            # Signal Plymouth Configuration
            # =================================================================

            theming.signal.nixos = {
              enable = true;
              mode = "dark"; # or "light"

              # Enable Plymouth boot splash
              boot.plymouth = {
                enable = true;

                # Optional: Custom logo image
                # logo = ./path/to/your/logo.png;
              };
            };

            # =================================================================
            # System Configuration (you must enable Plymouth separately)
            # =================================================================

            # Enable Plymouth in your boot configuration
            boot.plymouth.enable = true;

            # Boot configuration
            boot.loader = {
              systemd-boot.enable = true;
              efi.canTouchEfiVariables = true;
            };

            # =================================================================
            # Example: Complete boot experience with Signal theming
            # =================================================================
            # Note: Commented out to avoid duplicate attribute definition
            # In practice, you would merge this with the configuration above

            /*
              # Alternative: You can combine Plymouth with other boot theming:
              theming.signal.nixos.boot = {
                console.enable = true; # TTY colors
                grub.enable = false; # Using systemd-boot instead
                plymouth.enable = true; # Boot splash
              };
            */

            # Additional Plymouth configuration (optional)
            # These are already set by Signal's module but can be overridden
            # boot.kernelParams = [ "quiet" "splash" ];

            # System version
            system.stateVersion = "24.11";
          }
        ];
      };
    };
}
