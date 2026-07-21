# Signal NixOS Example - SDDM Login Screen
#
# This example shows how to theme the SDDM display manager with Signal colors.
# Perfect for KDE Plasma or any Qt-based desktop environment.

{
  description = "NixOS configuration with Signal SDDM theme";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    signal.url = "github:lewisflude/signal-nix";
  };

  outputs =
    { nixpkgs, signal, ... }:
    {
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          signal.nixosModules.default

          (
            { config, pkgs, ... }:
            {
              # ====================================================================
              # Signal System Theming
              # ====================================================================

              theming.signal.nixos = {
                enable = true;
                mode = "dark"; # or "light"

                # Boot theming
                boot = {
                  console.enable = true; # TTY colors
                  grub.enable = true; # GRUB theme
                };

                # Login screen theming
                login = {
                  sddm.enable = true; # SDDM theme
                };
              };

              # ====================================================================
              # System Services Configuration
              # ====================================================================

              services = {
                # Display Manager with SDDM
                displayManager.sddm = {
                  enable = true;
                  # Signal theme will be applied automatically
                  # Theme: signal-dark (or signal-light)

                  # Optional: Wayland support
                  wayland.enable = true;
                };

                # Desktop Environment (KDE Plasma example)
                desktopManager.plasma6.enable = true;

                # Audio system
                pipewire = {
                  enable = true;
                  alsa.enable = true;
                  alsa.support32Bit = true;
                  pulse.enable = true;
                };
              };

              # ====================================================================
              # Standard NixOS Configuration
              # ====================================================================

              boot.loader.grub = {
                enable = true;
                device = "/dev/sda";
              };

              networking = {
                hostName = "desktop";
                networkmanager.enable = true;
              };

              users.users.alice = {
                isNormalUser = true;
                home = "/home/alice";
                extraGroups = [
                  "wheel"
                  "networkmanager"
                ];
              };

              environment.systemPackages = with pkgs; [
                vim
                wget
                git
                firefox
              ];

              time.timeZone = "America/New_York";
              i18n.defaultLocale = "en_US.UTF-8";

              # Audio
              sound.enable = true;
              security.rtkit.enable = true;

              system.stateVersion = "24.11";
            }
          )
        ];
      };
    };
}
