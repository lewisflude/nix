{
  palette,
  nix-colorizer,
  signalLib,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types;
  cfg = config.theming.signal;

  # Import all-modules.nix and apply signalLib/semantic to each
  signalModules = import ../home-manager/all-modules.nix;

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
  imports = map applyModule signalModules;

  options.theming.signal = {
    enable = mkEnableOption "Signal Design System";

    autoEnable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Automatically enable Signal theming for all programs/services
        that are already enabled in your configuration.

        When enabled, Signal will detect if a program is enabled
        (e.g., programs.helix.enable = true) and automatically apply
        Signal colors to it.

        Set to false to disable automatic theming and manually control
        which programs are themed using the per-application enable options.
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
        Color theme mode:
        - light: Use light mode colors
        - dark: Use dark mode colors
        - auto: Follow system preference (defaults to dark)
      '';
    };

    # Color exposure - submodules populate these
    colors = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = ''
        Exposed color definitions from Signal modules.
        Each application module can populate this with its color exports.

        For example, ironbar provides:
        - colors.ironbar.cssFile: Path to CSS file with color definitions
        - colors.ironbar.tokens: Raw color values as Nix attributes
      '';
    };

    # Per-application enables
    ironbar = {
      enable = mkEnableOption "Signal theme for Ironbar";
      profile = mkOption {
        type = types.enum [
          "compact"
          "relaxed"
          "spacious"
        ];
        default = "relaxed";
        description = ''
          Display profile:
          - compact: 1080p displays (smaller spacing, 40px bar)
          - relaxed: 1440p+ displays (comfortable spacing, 48px bar)
          - spacious: 4K displays (generous spacing, 56px bar)
        '';
      };
    };

    gtk = {
      enable = mkEnableOption "Signal theme for GTK";
      version = mkOption {
        type = types.enum [
          "gtk3"
          "gtk4"
          "both"
        ];
        default = "both";
      };

      # Read-only options for use by other modules (e.g., pinentry wrapper)
      themeName = mkOption {
        type = types.str;
        readOnly = true;
        default = "Signal-${signalLib.resolveThemeMode cfg.mode}";
        description = "Resolved GTK theme name (e.g., 'Signal-dark'). Read-only.";
      };

      themePackage = mkOption {
        type = types.package;
        readOnly = true;
        default = pkgs.callPackage ../../pkgs/gtk-theme {
          inherit signalLib;
          mode = cfg.mode;
        };
        description = "Signal GTK theme package. Read-only.";
      };
    };

    qt = {
      enable = mkEnableOption "Signal theme for Qt/KDE";
    };

    # Desktop options
    desktop = {
      compositors = {
        hyprland.enable = mkEnableOption "Signal theme for Hyprland compositor";
        sway.enable = mkEnableOption "Signal theme for Sway compositor";
      };

      wm = {
        i3.enable = mkEnableOption "Signal theme for i3 window manager";
        bspwm.enable = mkEnableOption "Signal theme for bspwm window manager";
        awesome.enable = mkEnableOption "Signal theme for awesome window manager";
      };

      launchers = {
        rofi.enable = mkEnableOption "Signal theme for rofi launcher";
        wofi.enable = mkEnableOption "Signal theme for wofi launcher";
        tofi.enable = mkEnableOption "Signal theme for tofi launcher";
        dmenu.enable = mkEnableOption "Signal theme for dmenu launcher";
      };

      bars = {
        waybar.enable = mkEnableOption "Signal theme for waybar status bar";
        polybar.enable = mkEnableOption "Signal theme for polybar status bar";
      };

      notifications = {
        dunst.enable = mkEnableOption "Signal theme for dunst notification daemon";
        mako.enable = mkEnableOption "Signal theme for mako notification daemon";
        swaync.enable = mkEnableOption "Signal theme for SwayNC notification daemon";
      };

      swaylock.enable = mkEnableOption "Signal theme for swaylock screen locker";
    };

    fuzzel.enable = mkEnableOption "Signal theme for Fuzzel launcher";

    editors = {
      helix.enable = mkEnableOption "Signal theme for Helix editor";
      neovim.enable = mkEnableOption "Signal theme for Neovim editor";
      vim.enable = mkEnableOption "Signal theme for Vim editor";
      vscode.enable = mkEnableOption "Signal theme for VS Code/VSCodium";
      emacs.enable = mkEnableOption "Signal theme for Emacs";
      zed.enable = mkEnableOption "Signal theme for Zed editor";
    };

    terminals = {
      ghostty.enable = mkEnableOption "Signal theme for Ghostty terminal";
      alacritty.enable = mkEnableOption "Signal theme for Alacritty terminal";
      kitty.enable = mkEnableOption "Signal theme for Kitty terminal";
      wezterm.enable = mkEnableOption "Signal theme for WezTerm terminal";
      foot.enable = mkEnableOption "Signal theme for Foot terminal";
    };

    multiplexers = {
      tmux.enable = mkEnableOption "Signal theme for tmux";
      zellij.enable = mkEnableOption "Signal theme for zellij";
    };

    cli = {
      bat.enable = mkEnableOption "Signal theme for bat";
      delta.enable = mkEnableOption "Signal theme for delta git diff viewer";
      eza.enable = mkEnableOption "Signal theme for eza file lister";
      fzf.enable = mkEnableOption "Signal theme for fzf";
      lazygit.enable = mkEnableOption "Signal theme for lazygit";
      lazydocker.enable = mkEnableOption "Signal theme for lazydocker";
      ls-colors.enable = mkEnableOption "Signal theme for LS_COLORS (ls and compatible tools)";
      # vivid options are defined in modules/cli/vivid.nix
      yazi.enable = mkEnableOption "Signal theme for yazi";
      less.enable = mkEnableOption "Signal theme for less pager";
      ripgrep.enable = mkEnableOption "Signal theme for ripgrep";
      glow.enable = mkEnableOption "Signal theme for glow markdown viewer";
      tig.enable = mkEnableOption "Signal theme for tig git interface";
      tealdeer.enable = mkEnableOption "Signal theme for tealdeer (tldr)";
    };

    fileManagers = {
      ranger.enable = mkEnableOption "Signal theme for ranger file manager";
      lf.enable = mkEnableOption "Signal theme for lf file manager";
      nnn.enable = mkEnableOption "Signal theme for nnn file manager";
    };

    monitors = {
      btop.enable = mkEnableOption "Signal theme for btop";
      htop.enable = mkEnableOption "Signal theme for htop";
      bottom.enable = mkEnableOption "Signal theme for bottom";
      mangohud.enable = mkEnableOption "Signal theme for MangoHud gaming overlay";
      procs.enable = mkEnableOption "Signal theme for procs process viewer";
    };

    media = {
      mpv.enable = mkEnableOption "Signal theme for mpv media player";
    };

    browsers = {
      firefox.enable = mkEnableOption "Signal theme for Firefox (userChrome.css)";
      qutebrowser.enable = mkEnableOption "Signal theme for Qutebrowser";
    };

    apps = {
      satty.enable = mkEnableOption "Signal theme for Satty screenshot annotation";
    };

    prompts = {
      starship.enable = mkEnableOption "Signal theme for starship prompt";
      powerlevel10k.enable = mkEnableOption "Signal theme for powerlevel10k prompt";
    };

    shells = {
      zsh.enable = mkEnableOption "Signal theme for zsh syntax highlighting";
      fish.enable = mkEnableOption "Signal theme for fish shell";
      bash.enable = mkEnableOption "Signal theme for bash shell";
      nushell.enable = mkEnableOption "Signal theme for nushell";
    };

    # Brand governance
    brandGovernance = {
      policy = mkOption {
        type = types.enum [
          "functional-override"
          "separate-layer"
          "integrated"
        ];
        default = "functional-override";
        description = ''
          Brand governance policy:
          - functional-override: Functional colors override brand colors (brand is decorative only)
          - separate-layer: Brand colors exist as separate layer alongside functional colors
          - integrated: Brand colors can replace functional colors (must meet accessibility requirements)
        '';
      };

      decorativeBrandColors = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = ''
          Decorative brand colors (logos, headers, etc.)
          Example: { brand-primary = "<hex-color>"; }
        '';
      };

      brandColors = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              l = mkOption {
                type = types.float;
                description = "Lightness (0.0-1.0)";
              };
              c = mkOption {
                type = types.float;
                description = "Chroma (0.0-0.4+)";
              };
              h = mkOption {
                type = types.float;
                description = "Hue (0-360 degrees)";
              };
              hex = mkOption {
                type = types.str;
                description = "Hex color code";
              };
            };
          }
        );
        default = { };
        description = ''
          Brand colors that can replace functional colors (integrated policy only)
          Must meet WCAG AA contrast requirements
        '';
      };
    };

    # Theme variant
    variant = mkOption {
      type = types.nullOr (
        types.enum [
          "default"
          "high-contrast"
          "reduced-motion"
          "color-blind-friendly"
        ]
      );
      default = null;
      description = ''
        Theme variant:
        - default: Standard theme
        - high-contrast: Increased contrast
        - reduced-motion: Reduced saturation
        - color-blind-friendly: Adjusted hues
      '';
    };
  };

  # Example: Each module should use semantic bridge for colors:
  #   themeMode = signalLib.resolveThemeMode cfg.mode;
  #   colors = {
  #     background = semantic.core "background" themeMode;
  #     foreground = semantic.core "foreground" themeMode;
  #   };
  # This ensures theme names like "signal-dark" are resolved correctly (not "signal-auto")

  config = lib.mkIf cfg.enable {
    # Helpful assertions to catch common mistakes
    assertions = [
      # Warn if Signal is enabled but nothing is selected for theming
      {
        assertion =
          cfg.autoEnable
          || cfg.ironbar.enable
          || cfg.gtk.enable
          || cfg.qt.enable
          || cfg.fuzzel.enable
          || cfg.desktop.compositors.hyprland.enable
          || cfg.desktop.compositors.sway.enable
          || cfg.desktop.wm.i3.enable
          || cfg.desktop.launchers.rofi.enable
          || cfg.desktop.bars.waybar.enable
          || cfg.desktop.notifications.dunst.enable
          || cfg.desktop.notifications.mako.enable
          || cfg.desktop.notifications.swaync.enable
          || cfg.desktop.swaylock.enable
          || cfg.editors.helix.enable
          || cfg.editors.neovim.enable
          || cfg.editors.vim.enable
          || cfg.editors.vscode.enable
          || cfg.editors.emacs.enable
          || cfg.editors.zed.enable
          || cfg.terminals.ghostty.enable
          || cfg.terminals.alacritty.enable
          || cfg.terminals.kitty.enable
          || cfg.terminals.wezterm.enable
          || cfg.multiplexers.tmux.enable
          || cfg.multiplexers.zellij.enable
          || cfg.cli.bat.enable
          || cfg.cli.delta.enable
          || cfg.cli.eza.enable
          || cfg.cli.fzf.enable
          || cfg.cli.lazygit.enable
          || cfg.cli.ls-colors.enable
          || cfg.cli.vivid.enable
          || cfg.cli.yazi.enable
          || cfg.cli.less.enable
          || cfg.cli.ripgrep.enable
          || cfg.monitors.btop.enable
          || cfg.monitors.htop.enable
          || cfg.monitors.mangohud.enable
          || cfg.monitors.procs.enable
          || cfg.media.mpv.enable
          || cfg.apps.satty.enable
          || cfg.prompts.starship.enable
          || cfg.shells.zsh.enable
          || cfg.shells.fish.enable
          || cfg.shells.bash.enable;
        message = ''
          Signal is enabled but no applications are selected for theming.

          Either:
          1. Enable autoEnable to automatically theme all enabled programs:
             theming.signal.autoEnable = true;

          2. Or explicitly enable theming for specific applications:
             theming.signal.editors.helix.enable = true;
             theming.signal.terminals.kitty.enable = true;

          See: https://github.com/lewisflude/signal-nix#configuration
        '';
      }

      # Warn about common mode typo
      {
        assertion = lib.elem cfg.mode [
          "light"
          "dark"
          "auto"
        ];
        message = ''
          Invalid theme mode: "${cfg.mode}"

          Valid modes are:
          - "dark"  - Dark background, light text
          - "light" - Light background, dark text
          - "auto"  - Follow system preference (currently defaults to dark)
        '';
      }

      # Warn about integrated brand governance without colors
      {
        assertion =
          cfg.brandGovernance.policy != "integrated"
          || (cfg.brandGovernance.decorativeBrandColors != { } || cfg.brandGovernance.brandColors != { });
        message = ''
          Brand governance policy is set to "integrated" but no brand colors are defined.

          Either:
          1. Add decorative brand colors:
             theming.signal.brandGovernance.decorativeBrandColors = {
               brand-primary = "<hex-color>";
             };

          2. Or use a different policy:
             theming.signal.brandGovernance.policy = "functional-override";
        '';
      }
    ]
    # Platform compatibility assertions for Linux-only apps
    ++ [
      (signalLib.platform.mkAssertion pkgs cfg "hyprland" [
        "desktop"
        "compositors"
        "hyprland"
      ])
      (signalLib.platform.mkAssertion pkgs cfg "sway" [
        "desktop"
        "compositors"
        "sway"
      ])
      (signalLib.platform.mkAssertion pkgs cfg "i3" [
        "desktop"
        "wm"
        "i3"
      ])
      (signalLib.platform.mkAssertion pkgs cfg "bspwm" [
        "desktop"
        "wm"
        "bspwm"
      ])
      (signalLib.platform.mkAssertion pkgs cfg "awesome" [
        "desktop"
        "wm"
        "awesome"
      ])
      (signalLib.platform.mkAssertion pkgs cfg "rofi" [
        "desktop"
        "launchers"
        "rofi"
      ])
      (signalLib.platform.mkAssertion pkgs cfg "wofi" [
        "desktop"
        "launchers"
        "wofi"
      ])
      (signalLib.platform.mkAssertion pkgs cfg "tofi" [
        "desktop"
        "launchers"
        "tofi"
      ])
      (signalLib.platform.mkAssertion pkgs cfg "dmenu" [
        "desktop"
        "launchers"
        "dmenu"
      ])
      (signalLib.platform.mkAssertion pkgs cfg "fuzzel" [ "fuzzel" ])
      (signalLib.platform.mkAssertion pkgs cfg "waybar" [
        "desktop"
        "bars"
        "waybar"
      ])
      (signalLib.platform.mkAssertion pkgs cfg "polybar" [
        "desktop"
        "bars"
        "polybar"
      ])
      (signalLib.platform.mkAssertion pkgs cfg "ironbar" [ "ironbar" ])
      (signalLib.platform.mkAssertion pkgs cfg "dunst" [
        "desktop"
        "notifications"
        "dunst"
      ])
      (signalLib.platform.mkAssertion pkgs cfg "mako" [
        "desktop"
        "notifications"
        "mako"
      ])
      (signalLib.platform.mkAssertion pkgs cfg "swaync" [
        "desktop"
        "notifications"
        "swaync"
      ])
      (signalLib.platform.mkAssertion pkgs cfg "swaylock" [
        "desktop"
        "swaylock"
      ])
      (signalLib.platform.mkAssertion pkgs cfg "foot" [
        "terminals"
        "foot"
      ])
      (signalLib.platform.mkAssertion pkgs cfg "mangohud" [
        "monitors"
        "mangohud"
      ])
      (signalLib.platform.mkAssertion pkgs cfg "satty" [
        "apps"
        "satty"
      ])
      # NOTE: niri assertion removed - niri module requires external niri flake
    ];
  };
}
