{ lib
, config
, pkgs
, inputs
, ...
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

    # Niri integration - Use includes method (recommended over enableKeybinds)
    # See: https://danklinux.com/docs/dankmaterialshell/nixos-flake
    niri = {
      enableSpawn = true; # Auto-start DMS with niri

      # Use includes for flexible keybind management (default, recommended)
      # This generates config files in ~/.config/niri/dms/:
      #   - binds.kdl (keybindings)
      #   - colors.kdl (DMS colors)
      #   - layout.kdl (gaps, window radius)
      #   - alttab.kdl (alt-tab configuration)
      includes = {
        enable = true; # Recommended: more flexible than enableKeybinds
        override = true; # DMS settings take precedence
      };

      # Don't use enableKeybinds - it's less flexible and may conflict with includes
      # enableKeybinds = false; # (default when omitted)
    };

    # Core feature toggles (all enabled for full DMS experience)
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    enableVPN = true; # VPN management widget
    enableDynamicTheming = true; # Wallpaper-based dynamic theming
    enableAudioWavelength = true; # Audio visualization
    enableCalendarEvents = true; # Calendar events via khal
    enableClipboardPaste = true; # Clipboard paste support

    # NOTE: DankMaterialShell includes these features built-in:
    # - Dank Dash: Dashboard with media controls, weather, calendar, system info
    # - Launcher: Application launcher with filesystem search (fuzzel-based)
    # - Control Center: System settings and quick toggle interface
    # These are integrated into DMS and don't require separate packages

    # Optional: Custom settings (uncomment and configure as needed)
    # settings = {
    #   # DankMaterialShell settings go here
    #   # Written to ~/.config/DankMaterialShell/settings.json
    # };

    # Optional: Clipboard settings (uncomment and configure as needed)
    # clipboardSettings = {
    #   # Clipboard configuration goes here
    #   # Written to ~/.config/DankMaterialShell/clsettings.json
    # };

    # Optional: Session settings (uncomment and configure as needed)
    # session = {
    #   # Session configuration goes here
    #   # Written to ~/.local/state/DankMaterialShell/session.json
    # };

    # Plugin configuration
    # Plugins can be added later via DMS settings UI or CLI: dms plugins install <plugin-name>
    # plugins = {
    #   dankBatteryAlerts.enable = true;
    # };
  };
}
