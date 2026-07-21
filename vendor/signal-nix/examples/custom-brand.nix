# Signal Design System - Custom Brand Colors Example
# Using brand governance for organization/personal branding

{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    signal.url = "github:lewisflude/signal-nix";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      signal,
      ...
    }:
    {
      homeConfigurations.user = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          signal.homeManagerModules.default
          {
            home = {
              username = "user";
              homeDirectory = "/home/user";
              stateVersion = "24.11";
            };

            # Enable Signal theme with custom brand colors
            theming.signal = {
              enable = true;
              mode = "dark";

              # Enable applications
              ironbar.enable = true;
              gtk.enable = true;
              editors.helix.enable = true;

              # Brand governance configuration
              brandGovernance = {
                # Functional colors override brand colors (safest approach)
                policy = "functional-override";

                # Decorative brand colors (for logos, headers, etc.)
                # These don't affect functional UI elements
                decorativeBrandColors = {
                  brand-primary = "#5a7dcf"; # Company blue
                  brand-secondary = "#4a9b6f"; # Company green
                  brand-accent = "#d9574a"; # Company red
                };

                # Advanced: Override functional colors (use with caution)
                # Only use if your brand colors meet accessibility requirements
                # brandColors = {
                #   accent-primary = {
                #     l = 0.71;
                #     c = 0.20;
                #     h = 130.0;
                #     hex = "#4db368";
                #   };
                # };
              };
            };
          }
        ];
      };
    };
}
