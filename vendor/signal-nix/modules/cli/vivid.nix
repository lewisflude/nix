# Signal Vivid Module
#
# Vivid generates LS_COLORS for ls, tree, fd, eza, and other tools.
# It provides a comprehensive file type database and RGB-based theming.
# This module generates a Signal theme dynamically from the color palette.
{
  signalLib,
  signalPalette,
  semantic,
  nix-colorizer,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
# CONFIGURATION METHOD: native-config (Tier 1)
# HOME-MANAGER MODULE: programs.vivid
# UPSTREAM SCHEMA: https://github.com/sharkdp/vivid
# SCHEMA VERSION: vivid 0.10.1
# LAST VALIDATED: 2026-01-20
# NOTES: Uses YAML theme format with RGB hex colors
let
  inherit (lib) mkIf mkOption types;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Convert Signal hex colors to vivid format (remove # prefix)
  toVividHex = color: lib.removePrefix "#" color;

  # Helper to get semantic color in vivid format
  c = name: toVividHex (semantic.resolve name themeMode).hex;
  cVCS = name: toVividHex (semantic.vcs name themeMode).hex;
  cStatus = name: toVividHex (semantic.status name themeMode).hex;
  cText = name: toVividHex (semantic.text name themeMode).hex;
  cMultiplayer = name: toVividHex (semantic.multiplayer name themeMode).hex;

  # Generate Signal theme for vivid using semantic bridge
  signalTheme = {
    colors = {
      # Core Signal accent colors
      primary = cVCS "added";
      secondary = cVCS "modified";
      tertiary = cStatus "info";
      success = cVCS "added";
      warning = cStatus "warning";
      error = cStatus "error";
      info = cStatus "info";

      # Categorical colors for different file types
      categorical1 = cMultiplayer "player-1";
      categorical2 = cMultiplayer "player-2";
      categorical3 = cMultiplayer "player-3";
      categorical4 = cMultiplayer "player-4";
      categorical5 = cMultiplayer "player-5";
      categorical6 = cMultiplayer "player-6";

      # Tonal colors for text
      text = cText "primary";
      subtext = cText "secondary";

      # Standard ANSI colors for compatibility
      blue = "0087ff";
      cyan = "00d7ff";
      green = "5fd700";
      magenta = "d787d7";
      red = "ff5f5f";
      yellow = "ffd787";
      white = "ffffff";
      black = "000000";
    };

    core = {
      # Core file types
      normal_text = { };
      regular_file = { };
      reset_to_normal = { };

      directory = {
        foreground = "primary";
        font-style = "bold";
      };

      symlink = {
        foreground = "cyan";
        font-style = "bold";
      };

      multi_hard_link = { };

      fifo = {
        foreground = "yellow";
        background = "black";
      };

      socket = {
        foreground = "magenta";
        font-style = "bold";
      };

      door = {
        foreground = "magenta";
        font-style = "bold";
      };

      block_device = {
        foreground = "yellow";
        background = "black";
        font-style = "bold";
      };

      character_device = {
        foreground = "yellow";
        background = "black";
        font-style = "bold";
      };

      broken_symlink = {
        foreground = "red";
        background = "black";
        font-style = "bold";
      };

      missing_symlink_target = { };

      setuid = {
        foreground = "white";
        background = "red";
      };

      setgid = {
        foreground = "black";
        background = "yellow";
      };

      file_with_capability = { };

      sticky_other_writable = {
        foreground = "black";
        background = "green";
      };

      other_writable = {
        foreground = "blue";
        background = "green";
      };

      sticky = {
        foreground = "white";
        background = "blue";
      };

      executable_file = {
        foreground = "success";
        font-style = "bold";
      };
    };

    text = {
      # Document files
      foreground = "info";
      special = {
        foreground = "categorical1";
        font-style = "bold";
      };
    };

    markup = {
      foreground = "categorical2";
    };

    programming = {
      foreground = "secondary";
      source = {
        foreground = "categorical3";
      };
      tooling = {
        foreground = "categorical4";
      };
    };

    media = {
      foreground = "categorical5";
      image = {
        foreground = "categorical5";
      };
      video = {
        foreground = "categorical6";
      };
      audio = {
        foreground = "categorical4";
      };
    };

    office = {
      foreground = "info";
    };

    archives = {
      foreground = "warning";
    };

    executable = {
      foreground = "success";
    };

    unimportant = {
      foreground = "subtext";
    };
  };

  # Check if vivid should be enabled
  shouldTheme = cfg.cli.vivid.enable or false || cfg.autoEnable;
in
{
  options.theming.signal.cli.vivid = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable Signal theming for vivid.
        When enabled, generates LS_COLORS using vivid with a Signal theme.
      '';
    };

    colorMode = mkOption {
      type = types.enum [
        "24-bit"
        "8-bit"
      ];
      default = "24-bit";
      description = ''
        Color mode for vivid output.
        - 24-bit: True color support (modern terminals)
        - 8-bit: 256 color mode (older terminals)
      '';
    };

    cache = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to cache the vivid output at build time.
        When enabled, vivid generates LS_COLORS once during Nix build
        and stores it in a file, which is read on shell startup.
        This significantly improves shell startup time (~20-50ms savings).

        When disabled, vivid runs on every shell startup (slower but
        allows runtime theme switching if you modify vivid themes manually).
      '';
    };

    enableBashIntegration = mkOption {
      type = types.bool;
      default = config.programs.bash.enable or false;
      description = "Whether to enable Bash integration for vivid.";
    };

    enableFishIntegration = mkOption {
      type = types.bool;
      default = config.programs.fish.enable or false;
      description = "Whether to enable Fish integration for vivid.";
    };

    enableZshIntegration = mkOption {
      type = types.bool;
      default = config.programs.zsh.enable or false;
      description = "Whether to enable Zsh integration for vivid.";
    };
  };

  config = mkIf (cfg.enable && shouldTheme) (
    let
      # Generate cached vivid output at build time.
      # YAML 1.2 is a superset of JSON and vivid's parser reads JSON directly,
      # so we write the theme as-is instead of shelling out to a JSON->YAML
      # converter. This avoids remarshal/json2yaml, whose Python runtime aborts
      # with a libffi trampoline assertion on newer macOS.
      cachedLsColors =
        pkgs.runCommand "vivid-ls-colors-signal"
          {
            nativeBuildInputs = [
              pkgs.vivid
            ];
          }
          ''
            set -euo pipefail

            # JSON is valid YAML; write the theme directly.
            echo '${builtins.toJSON signalTheme}' > signal.yml

            # Create XDG config structure for vivid
            # Vivid looks for themes in $XDG_CONFIG_HOME/vivid/themes/
            mkdir -p config/vivid/themes
            mv signal.yml config/vivid/themes/signal.yml

            # Verify the file was created correctly
            if [ ! -f "config/vivid/themes/signal.yml" ]; then
              echo "ERROR: Theme file was not created correctly" >&2
              exit 1
            fi

            # Debug: show generated theme
            echo "=== Generated theme file ===" >&2
            cat config/vivid/themes/signal.yml >&2
            echo "===========================" >&2

            # Set XDG_CONFIG_HOME to point to our config directory
            export XDG_CONFIG_HOME="$PWD/config"
            export HOME="$PWD"

            # Verify vivid can find the theme
            if [ ! -f "$XDG_CONFIG_HOME/vivid/themes/signal.yml" ]; then
              echo "ERROR: Theme file not found at expected location: $XDG_CONFIG_HOME/vivid/themes/signal.yml" >&2
              exit 1
            fi

            ${pkgs.vivid}/bin/vivid -m ${cfg.cli.vivid.colorMode} generate signal > $out || {
              echo "ERROR: Failed to generate vivid colors" >&2
              echo "Theme file location: $XDG_CONFIG_HOME/vivid/themes/signal.yml" >&2
              echo "XDG_CONFIG_HOME: $XDG_CONFIG_HOME" >&2
              echo "Current directory: $(pwd)" >&2
              echo "Listing config directory:" >&2
              ls -la config/ >&2 || true
              echo "Listing vivid directory:" >&2
              ls -la config/vivid/ >&2 || true
              echo "Listing themes directory:" >&2
              ls -la config/vivid/themes/ >&2 || true
              exit 1
            }
          '';

      # Path relative to $HOME for home.file
      cachedFileHome = ".config/vivid/ls-colors-signal";

      # Runtime path for reading the file
      cachedFileRuntime = "\${XDG_CONFIG_HOME:-$HOME/.config}/vivid/ls-colors-signal";
    in
    lib.mkMerge [
      # Always enable programs.vivid to install the package and define themes
      {
        programs.vivid = {
          enable = true;
          package = pkgs.vivid;
          activeTheme = "signal";
          colorMode = cfg.cli.vivid.colorMode;

          # Only enable shell integrations if caching is disabled
          enableBashIntegration = !cfg.cli.vivid.cache && cfg.cli.vivid.enableBashIntegration;
          enableFishIntegration = !cfg.cli.vivid.cache && cfg.cli.vivid.enableFishIntegration;
          enableZshIntegration = !cfg.cli.vivid.cache && cfg.cli.vivid.enableZshIntegration;

          # Define the Signal theme for manual use
          themes.signal = signalTheme;
        };
      }

      # When caching is enabled, create the cached file and manually integrate
      (mkIf cfg.cli.vivid.cache {
        # Create the cached LS_COLORS file
        home.file."${cachedFileHome}".source = cachedLsColors;

        # Manually add LS_COLORS to Bash
        programs.bash = mkIf cfg.cli.vivid.enableBashIntegration {
          initExtra = ''
            # Signal vivid LS_COLORS (cached for performance)
            export LS_COLORS="$(cat ${cachedFileRuntime})"
          '';
        };

        # Manually add LS_COLORS to Zsh
        programs.zsh = mkIf cfg.cli.vivid.enableZshIntegration {
          initContent = lib.mkAfter ''
            # Signal vivid LS_COLORS (cached for performance)
            export LS_COLORS="$(cat ${cachedFileRuntime})"
          '';
        };

        # Manually add LS_COLORS to Fish
        programs.fish = mkIf cfg.cli.vivid.enableFishIntegration {
          interactiveShellInit = ''
            # Signal vivid LS_COLORS (cached for performance)
            set -gx LS_COLORS (cat ${cachedFileRuntime})
          '';
        };
      })
    ]
  );
}
