# Signal Desktop Environment Example
#
# This example shows a complete desktop setup with:
# - Hyprland compositor
# - Waybar status bar
# - rofi launcher
# - dunst/mako/swaync notifications (choose one)
# - Editors (VS Code, Vim, Emacs)
# - Shells (fish, bash)
# - All themed with Signal colors
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
      homeConfigurations.yourname = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;

        modules = [
          signal.homeManagerModules.default

          {
            # Enable programs (you control what's installed)
            programs = {
              # Compositor
              hyprland.enable = true;

              # Status bar
              waybar.enable = true;

              # Launcher
              rofi.enable = true;

              # Notifications (choose one)
              dunst.enable = true; # Traditional notification daemon
              # Or use mako for Wayland
              # Or use SwayNC for a notification center with control panel

              # Editors
              vscode.enable = true;
              vim.enable = true;
              emacs.enable = true;
              helix.enable = true;
              neovim.enable = true;

              # Terminals
              kitty.enable = true;
              alacritty.enable = true;

              # Shells
              fish.enable = true;
              bash.enable = true;

              # CLI tools
              bat.enable = true;
              fzf.enable = true;
              eza.enable = true;
            };

            # Enable services
            services = {
              dunst.enable = true;
              # mako.enable = true; # Alternative: Wayland notification daemon
              # swaync.enable = true; # Alternative: Sway Notification Center
            };

            # Signal automatically themes ALL of the above! ✨
            theming.signal = {
              enable = true; # Automatically themes all enabled programs and services
              mode = "dark";
            };

            # You can still disable specific apps if needed:
            # theming.signal.desktop.bars.waybar.enable = false;

            # Basic home-manager config
            home = {
              username = "yourname";
              homeDirectory = "/home/yourname";
              stateVersion = "24.11";
            };

            programs.home-manager.enable = true;
          }
        ];
      };
    };
}
