{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  # Get Dank Linux ecosystem packages from flake inputs
  # Note: dgop is already provided by DMS (enableSystemMonitoring = true)
  danksearch = inputs.danksearch.packages.${pkgs.system}.default or null;
in
{
  # Install Dank Linux CLI tools
  # dgop: Provided by DMS system monitoring, no need to install separately
  home.packages = lib.optionals (danksearch != null) [ danksearch ];

  # Configure danksearch home-manager module (if available)
  programs.dsearch = lib.mkIf (danksearch != null) {
    enable = true;
  };

  programs.dank-material-shell = {
    enable = true;

    # ==========================================================================
    # NIRI INTEGRATION
    # ==========================================================================
    # Use includes method (recommended over enableKeybinds)
    # See: https://danklinux.com/docs/dankmaterialshell/nixos-flake
    niri = {
      enableSpawn = true; # Auto-start DMS with niri

      # Use includes for flexible keybind management
      # Generates config files in ~/.config/niri/dms/:
      #   - binds.kdl (keybindings)
      #   - colors.kdl (DMS colors)
      #   - layout.kdl (gaps, window radius)
      #   - alttab.kdl (alt-tab configuration)
      includes = {
        enable = true; # Generate DMS config files
        override = true; # DMS settings take precedence
      };
    };

    # ==========================================================================
    # CORE FEATURE TOGGLES
    # ==========================================================================
    enableSystemMonitoring = true; # System monitoring widgets (dgop backend)
    enableVPN = true; # VPN management widget (requires NetworkManager)
    enableDynamicTheming = true; # Wallpaper-based Material You theming (matugen)
    enableAudioWavelength = true; # Audio visualization bars on dashboard (cava)
    enableCalendarEvents = true; # Calendar events via khal backend
    enableClipboardPaste = true; # Clipboard paste with wtype

    # ==========================================================================
    # NOTE: Additional DMS features configured via runtime settings
    # ==========================================================================
    # The following features are configured via DMS Settings UI or CLI:
    # - Browser Picker: dms settings browser-picker
    # - Lock Screen: dms settings lock-screen
    # - Night Light: dms settings night-light
    # - Power Management: dms settings power
    # - Clipboard settings: dms settings clipboard
    # - Plugins: dms plugins install <name>
    #
    # These features may not have declarative Nix options yet.
    # Use `dms doctor` to check configuration status.
    # ==========================================================================

    # Optional: Custom settings (written to ~/.config/DankMaterialShell/settings.json)
    # settings = { };

    # Optional: Clipboard settings (written to ~/.config/DankMaterialShell/clsettings.json)
    # clipboardSettings = { };

    # Optional: Plugin configuration
    # plugins = { };
  };
}
