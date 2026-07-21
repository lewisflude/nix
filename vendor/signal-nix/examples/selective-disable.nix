# Signal Design System - Selective Disable Example
# Theme most programs automatically, but keep specific ones with their default themes

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

            # Enable the programs you want to use
            programs = {
              # Editors
              helix.enable = true;
              neovim.enable = true;

              # Terminals
              ghostty.enable = true;
              alacritty.enable = true;
              kitty.enable = true;

              # Multiplexers
              tmux.enable = true;
              zellij.enable = true;

              # CLI Tools
              bat.enable = true;
              delta.enable = true;
              eza.enable = true;
              fzf.enable = true;
              lazygit.enable = true;
              yazi.enable = true;

              # Monitors
              btop.enable = true;

              # Prompts
              starship.enable = true;

              # Shells
              zsh.enable = true;
            };

            # GTK
            gtk.enable = true;

            # Signal automatically themes all enabled programs by default
            # But you can selectively disable specific programs
            theming.signal = {
              enable = true; # autoEnable is true by default
              mode = "dark"; # "light", "dark", or "auto"

              # Explicitly disable theming for specific programs
              # These will keep their default themes
              cli.bat.enable = false; # Keep bat's default theme (custom setup)
              terminals.kitty.enable = false; # Keep kitty's default theme (prefer my config)
              editors.neovim.enable = false; # Keep Neovim's theme (have custom colorscheme)

              # All other enabled programs above will be automatically themed with Signal
              # Examples of what WILL be themed:
              #   ✅ helix (editor)
              #   ✅ ghostty (terminal)
              #   ✅ alacritty (terminal)
              #   ✅ tmux (multiplexer)
              #   ✅ zellij (multiplexer)
              #   ✅ delta, eza, fzf, lazygit, yazi (CLI tools)
              #   ✅ btop (monitor)
              #   ✅ starship (prompt)
              #   ✅ zsh (shell)
              #   ✅ GTK (desktop theme)
            };
          }
        ];
      };
    };
}
