# Desktop theming - GTK, Qt, fonts, and signal-nix integration
{ config, ... }:
{
  flake.modules.homeManager.theming =
    { lib, pkgs, ... }:
    let
      isLinux = pkgs.stdenv.isLinux;
      isDarwin = pkgs.stdenv.isDarwin;
    in
    {
      # =========================================================================
      # Signal Design System (Cross-platform)
      # =========================================================================
      theming.signal = {
        enable = true;
        autoEnable = true; # Auto-theme apps that are already enabled
        mode = "dark"; # "dark", "light", or "auto"

        # Editors (cross-platform)
        editors = {
          helix.enable = true;
          zed.enable = true;
        };

        # Terminals (cross-platform, except foot which is auto-guarded)
        terminals = {
          ghostty.enable = true;
          alacritty.enable = true;
          kitty.enable = true;
          wezterm.enable = true;
          foot.enable = isLinux; # Linux-only (Wayland), guarded
        };

        # CLI tools (cross-platform)
        cli = {
          bat.enable = true;
          delta.enable = true;
          fzf.enable = true;
          lazygit.enable = true;
          yazi.enable = true;
          eza.enable = true;
          less.enable = true;
          ripgrep.enable = true;
        };

        # Monitors (cross-platform except mangohud)
        monitors = {
          btop.enable = true;
          bottom.enable = true;
          procs.enable = true;
          mangohud.enable = isLinux; # Gaming overlay (Linux-only)
        };

        # Multiplexers (cross-platform)
        multiplexers = {
          tmux.enable = true;
          zellij.enable = true;
        };

        # Prompts (cross-platform)
        prompts.starship.enable = true;

        # Shells (cross-platform)
        shells = {
          zsh.enable = true;
          fish.enable = true;
        };

        # Media (cross-platform)
        media.mpv.enable = true;

        # Browsers (cross-platform)
        browsers = {
          firefox.enable = true;
          qutebrowser.enable = true;
        };

        # File managers (cross-platform)
        fileManagers = {
          ranger.enable = true;
          lf.enable = true;
        };

        # =====================================================================
        # Linux-only options (auto-guarded by signal-nix platform checks)
        # =====================================================================

        # GTK/Qt theming (Linux)
        gtk.enable = isLinux;
        qt.enable = isLinux;

        # Ironbar color palette
        ironbar.enable = isLinux;

        # Desktop components
        fuzzel.enable = isLinux;

        # Desktop compositors/WMs
        desktop = lib.mkIf isLinux {
          compositors = {
            hyprland.enable = false;
            sway.enable = false;
          };
          bars = {
            waybar.enable = true;
          };
          notifications = {
            dunst.enable = false;
            mako.enable = true;
          };
          swaylock.enable = true;
        };

        # Screenshot annotation (Linux-only)
        apps.satty.enable = isLinux;
      };

      # =========================================================================
      # Packages
      # =========================================================================
      home.packages =
        # Fonts (cross-platform)
        [
          pkgs.iosevka-bin
          pkgs.nerd-fonts.iosevka
        ]
        # Linux-specific packages
        ++ lib.optionals isLinux [
          pkgs.nwg-look
          pkgs.xdg-utils
        ];

      # =========================================================================
      # GTK Overrides (on top of signal-nix) - Linux only
      # =========================================================================
      gtk = lib.mkIf isLinux {
        enable = true;
        iconTheme = lib.mkForce {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
        };
        cursorTheme = lib.mkForce {
          name = "DMZ-White";
          package = pkgs.vanilla-dmz;
        };
        font = lib.mkForce {
          name = "Iosevka";
          package = pkgs.iosevka-bin;
          size = 12;
        };
      };

      # Qt theming - Linux only
      qt.enable = isLinux;

      # Font configuration
      fonts.fontconfig.enable = true;
    };
}
