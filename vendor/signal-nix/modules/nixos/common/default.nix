{ palette, nix-colorizer }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    types
    ;
  cfg = config.theming.signal.nixos;
  signalLib = import ../../../lib {
    inherit lib palette nix-colorizer;
  };

  # Import all NixOS modules and apply signalLib/semantic to each
  nixosModules = import ../all-modules.nix;

  # Apply module arguments using importApply pattern
  applyModule =
    mod:
    lib.modules.importApply mod {
      inherit signalLib nix-colorizer;
      signalPalette = palette;
      inherit (signalLib) semantic;
    };
in
{
  imports = map applyModule nixosModules;

  options.theming.signal.nixos = {
    enable = mkEnableOption "Signal Design System for NixOS system components";

    autoEnable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Automatically enable Signal theming for all system components
        that are already enabled in your NixOS configuration.

        When enabled, Signal will detect if a system service is enabled
        (e.g., services.xserver.displayManager.gdm.enable = true) and
        automatically apply Signal colors to it.

        Set to false to disable automatic theming and manually control
        which components are themed using the per-component enable options.
      '';
    };

    mode = mkOption {
      type = types.enum [
        "light"
        "dark"
        "auto"
      ];
      default = "dark";
      description = ''
        Color theme mode for system components:
        - light: Use light mode colors
        - dark: Use dark mode colors
        - auto: Follow system preference (defaults to dark)

        Note: This can be different from your Home Manager theming.signal.mode
        if you want different colors at system vs user level.
      '';
    };

    # Boot theming options
    boot = {
      console = {
        enable = mkEnableOption "Signal theme for virtual console (TTY)";
      };

      grub = {
        enable = mkEnableOption "Signal theme for GRUB bootloader";
      };

      plymouth = {
        enable = mkEnableOption "Signal theme for Plymouth boot splash";
      };
    };

    # Display manager theming options
    login = {
      gdm = {
        enable = mkEnableOption "Signal theme for GDM display manager";
      };

      sddm = {
        enable = mkEnableOption "Signal theme for SDDM display manager";
      };

      lightdm = {
        enable = mkEnableOption "Signal theme for LightDM display manager";
      };

      greetd = {
        enable = mkEnableOption "Signal theme for greetd/tuigreet";
      };
    };

    # Resolved GTK theme values (read-only, for use by other modules)
    # Example usage: config.theming.signal.nixos.gtk.themeName
    gtk = {
      themeName = mkOption {
        type = types.str;
        readOnly = true;
        default = "Signal-${signalLib.resolveThemeMode cfg.mode}";
        description = "Resolved GTK theme name (e.g., 'Signal-dark'). Read-only.";
      };

      themePackage = mkOption {
        type = types.package;
        readOnly = true;
        default = pkgs.callPackage ../../../pkgs/gtk-theme {
          inherit signalLib;
          mode = cfg.mode;
        };
        description = "Signal GTK theme package. Read-only.";
      };
    };

    # Desktop environment theming options
    desktop = {
      gtk = {
        enable = mkEnableOption "System-wide Signal GTK theme";
        version = mkOption {
          type = types.enum [
            "gtk3"
            "gtk4"
            "both"
          ];
          default = "both";
          description = "Which GTK versions to theme system-wide";
        };
      };

      qt = {
        enable = mkEnableOption "System-wide Signal Qt theme";
      };

      cursor = {
        enable = mkEnableOption "Signal cursor theme";
      };

      icons = {
        enable = mkEnableOption "Signal icon theme";
      };
    };

    # System tools theming options
    system = {
      dmenu = {
        enable = mkEnableOption "Signal theme for dmenu";
      };

      rofi = {
        enable = mkEnableOption "Signal theme for rofi";
      };

      nano = {
        enable = mkEnableOption "Signal theme for nano editor";
      };

      vim = {
        enable = mkEnableOption "Signal theme for vim editor";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Helpful assertions
    assertions = [
      # Warn if Signal is enabled but nothing is selected for theming
      {
        assertion =
          cfg.autoEnable
          || cfg.boot.console.enable
          || cfg.boot.grub.enable
          || cfg.boot.plymouth.enable
          || cfg.login.gdm.enable
          || cfg.login.sddm.enable
          || cfg.login.lightdm.enable
          || cfg.login.greetd.enable
          || cfg.desktop.gtk.enable
          || cfg.desktop.qt.enable
          || cfg.desktop.cursor.enable
          || cfg.desktop.icons.enable
          || cfg.system.dmenu.enable
          || cfg.system.rofi.enable
          || cfg.system.nano.enable
          || cfg.system.vim.enable;
        message = ''
          Signal NixOS module is enabled but no system components are selected for theming.

          Either:
          1. Enable autoEnable to automatically theme all enabled system components:
             theming.signal.nixos.autoEnable = true;

          2. Or explicitly enable theming for specific components:
             theming.signal.nixos.boot.console.enable = true;
             theming.signal.nixos.login.sddm.enable = true;

          See: https://github.com/lewisflude/signal-nix/blob/main/NIXOS_MODULE_PLAN.md
        '';
      }

      # Warn about invalid mode
      {
        assertion = lib.elem cfg.mode [
          "light"
          "dark"
          "auto"
        ];
        message = ''
          Invalid NixOS theme mode: "${cfg.mode}"

          Valid modes are:
          - "dark"  - Dark background, light text
          - "light" - Light background, dark text
          - "auto"  - Follow system preference (currently defaults to dark)
        '';
      }
    ];
  };
}
