# Dank Material Shell configuration
# Dendritic pattern: Uses pkgs.danksearch from overlay instead of inputs
{
  lib,
  config,
  pkgs,
  ...
}:
let
  # Get Dank Linux ecosystem packages from overlay
  # Note: dgop is already provided by DMS (enableSystemMonitoring = true)
  danksearch = pkgs.danksearch or null;
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
    enableDynamicTheming = false; # Use DMS static colors (disable matugen auto-theming)
    enableAudioWavelength = true; # Audio visualization bars on dashboard (cava)
    enableCalendarEvents = true; # Calendar events via khal backend
    enableClipboardPaste = true; # Clipboard paste with wtype

    # ==========================================================================
    # DECLARATIVE SETTINGS (Optional)
    # ==========================================================================
    # Per docs: https://danklinux.com/docs/dankmaterialshell/nixos-flake
    # These can be configured declaratively or via DMS CLI/UI at runtime.
    #
    # Declarative configuration (written to config files):
    # settings = {
    #   theme = "dark";
    #   dynamicTheming = false;
    # };
    #
    # clipboardSettings = {
    #   maxHistory = 25;
    #   autoClearDays = 1;
    #   clearAtStartup = true;
    # };
    #
    # Runtime configuration via CLI:
    # - Browser Picker: dms settings browser-picker
    # - Lock Screen: dms settings lock-screen
    # - Night Light: dms settings night-light
    # - Power Management: dms settings power
    # - Clipboard: dms settings clipboard
    # - Plugins: dms plugins install <name>
    # - Check status: dms doctor
    # ==========================================================================

    # Optional: Plugin configuration
    # plugins = {
    #   dankBatteryAlerts.enable = true;
    #   mediaPlayer = {
    #     enable = true;
    #     settings.preferredSource = "spotify";
    #   };
    # };
  };
}
