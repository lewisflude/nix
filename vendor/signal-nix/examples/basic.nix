# Signal Design System - Basic Example
# Minimal configuration with essential applications

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

            # First, enable the programs you want to use
            programs = {
              helix.enable = true;
              # neovim.enable = true;  # Optional
              ghostty.enable = true;
              bat.enable = true;
              # delta.enable = true;  # Optional
              # eza.enable = true;  # Optional
              fzf.enable = true;
              yazi.enable = true;
              starship.enable = true;
            };

            # Signal automatically applies its theme to all enabled programs
            theming.signal = {
              enable = true; # Automatically themes all enabled programs above
              mode = "dark"; # "light", "dark", or "auto"
            };
          }
        ];
      };
    };
}
