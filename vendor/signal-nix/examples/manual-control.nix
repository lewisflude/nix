# Signal Design System - Manual Control Example
# Advanced: Explicitly control which programs get themed

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

            # Enable many programs
            programs = {
              helix.enable = true;
              neovim.enable = true;
              ghostty.enable = true;
              kitty.enable = true;
              bat.enable = true;
              delta.enable = true;
              fzf.enable = true;
              lazygit.enable = true;
              yazi.enable = true;
              starship.enable = true;
              zsh.enable = true;
            };

            # Advanced: Disable automatic theming for manual per-program control
            theming.signal = {
              enable = true;
              autoEnable = false; # Disable automatic theming
              mode = "dark";

              # Now manually enable theming for ONLY the programs you want
              # Programs NOT listed here will NOT be themed, even if enabled above

              # Theme these editors
              editors = {
                helix.enable = true; # ✅ Theme helix
                # neovim NOT enabled here, so it won't be themed
              };

              # Theme this terminal
              terminals = {
                ghostty.enable = true; # ✅ Theme ghostty
                # kitty NOT enabled here, so it won't be themed
              };

              # Theme these CLI tools
              cli = {
                bat.enable = true; # ✅ Theme bat
                fzf.enable = true; # ✅ Theme fzf
                lazygit.enable = true; # ✅ Theme lazygit
                # delta, yazi NOT enabled here, so they won't be themed
              };

              # Theme shell prompt
              prompts = {
                starship.enable = true; # ✅ Theme starship
              };

              # Shell NOT enabled here, so zsh won't be themed
            };

            # Result:
            #   ✅ Themed: helix, ghostty, bat, fzf, lazygit, starship
            #   ❌ NOT themed: neovim, kitty, delta, yazi, zsh (they'll use default colors)
          }
        ];
      };
    };
}
