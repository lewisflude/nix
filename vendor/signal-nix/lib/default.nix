{
  lib,
  palette,
  nix-colorizer,
  ...
}:
let
  # Import mkAppModule helpers
  appModuleHelpers = import ./mkAppModule.nix { inherit lib palette nix-colorizer; };

  # Import semantic bridge
  semantic = import ./semantic.nix { inherit lib palette; };

  # Import validation library
  validate = import ./validate.nix { inherit lib; };
in
rec {
  # Export semantic bridge and validation
  inherit semantic validate;

  # ============================================================================
  # Platform Detection and Guards
  # ============================================================================

  # Platform metadata for apps
  # Use this to define which platforms an app supports
  platform = {
    # Check if running on Linux
    # Usage: platform.isLinux pkgs
    isLinux = pkgs: pkgs.stdenv.isLinux;

    # Check if running on Darwin (macOS)
    # Usage: platform.isDarwin pkgs
    isDarwin = pkgs: pkgs.stdenv.isDarwin;

    # Get current platform name
    # Returns "linux" or "darwin"
    current = pkgs: if pkgs.stdenv.isLinux then "linux" else "darwin";

    # Platform requirements for each app category
    # Apps not listed here are assumed to be cross-platform
    linuxOnly = [
      # Desktop compositors (Wayland/X11)
      "hyprland"
      "sway"
      "niri"
      # Window managers (X11)
      "i3"
      "bspwm"
      "awesome"
      # Launchers (Wayland/X11)
      "rofi"
      "wofi"
      "tofi"
      "dmenu"
      "fuzzel"
      # Status bars (Wayland/X11)
      "waybar"
      "polybar"
      "ironbar"
      # Notification daemons (Wayland/X11)
      "dunst"
      "mako"
      "swaync"
      # Screen lockers
      "swaylock"
      # Wayland-only terminal
      "foot"
      # Gaming overlay
      "mangohud"
      # Screenshot annotation (Wayland)
      "satty"
    ];

    # Check if an app is Linux-only
    # Usage: platform.isLinuxOnly "hyprland"
    isLinuxOnly = appName: builtins.elem appName platform.linuxOnly;

    # Check if an app is available on current platform
    # Usage: platform.isAvailable pkgs "hyprland"
    isAvailable = pkgs: appName: if platform.isLinuxOnly appName then platform.isLinux pkgs else true;

    # Get platform guard condition for mkIf
    # Returns true if the app should be configured (platform matches)
    # Usage: platform.guard pkgs "hyprland"
    guard = pkgs: appName: !platform.isLinuxOnly appName || platform.isLinux pkgs;

    # Generate assertion for platform compatibility
    # Usage: platform.mkAssertion pkgs cfg "hyprland" ["desktop" "compositors" "hyprland"]
    mkAssertion =
      pkgs: cfg: appName: optionPath:
      let
        isEnabled = (lib.getAttrFromPath optionPath cfg).enable or false;
        optionStr = "theming.signal.${lib.concatStringsSep "." optionPath}.enable";
      in
      {
        assertion = !isEnabled || platform.guard pkgs appName;
        message = ''
          ${appName} is only available on Linux, but you are on ${platform.current pkgs}.

          Either:
          1. Remove or disable the option:
             ${optionStr} = false;

          2. Or use platform guards in your configuration:
             ${optionStr} = lib.mkIf pkgs.stdenv.isLinux true;
        '';
      };
  };

  # Re-export mkAppModule helpers
  inherit (appModuleHelpers)
    mkAppModule
    mkTier1Module
    mkTier2Module
    mkTier3Module
    mkTier4Module
    mkSimpleAppModule
    mkServiceModule
    makeAnsiColors
    makeUIColors
    validateRequiredFields
    validateHexColor
    validateColorAttrset
    ;

  # Resolve theme mode to a concrete value (dark or light)
  # Converts "auto" to "dark" as the default
  # Validates input and provides helpful error messages
  resolveThemeMode =
    mode:
    assert lib.assertMsg (lib.elem mode [
      "auto"
      "dark"
      "light"
    ]) "Invalid theme mode '${mode}'. Must be 'auto', 'dark', or 'light'.";
    if mode == "auto" then "dark" else mode;

  # ============================================================================
  # Color Conversion Utilities (using nix-colorizer for high-fidelity)
  # ============================================================================

  # Extract hex color string from color object
  # Required for Zellij theme format (Home Manager serializes to KDL with hex values)
  # Input: color object with .hex attribute (e.g., "#6b87c8")
  # Output: hex color string (e.g., "#6b87c8")
  toHex = color: color.hex;

  # Convert hex color to space-separated RGB string (0-255 range)
  # Required for terminal applications that need RGB format
  # Input: color object with .hex attribute (e.g., "#6b87c8")
  # Output: space-separated RGB string (e.g., "107 135 200")
  # Uses nix-colorizer for accurate hex -> sRGB conversion
  hexToRgbSpaceSeparated =
    color:
    let
      srgb = nix-colorizer.hex.to.srgb color.hex;
      # Convert from [0, 1] range to [0, 255] range and round
      r = builtins.floor (srgb.r * 255.0 + 0.5);
      g = builtins.floor (srgb.g * 255.0 + 0.5);
      b = builtins.floor (srgb.b * 255.0 + 0.5);
    in
    "${toString r} ${toString g} ${toString b}";

  # Convert hex color to comma-separated RGB string (0-255 range)
  # Required for KDE/Qt color scheme format
  # Input: color object with .hex attribute (e.g., "#6b87c8")
  # Output: comma-separated RGB string (e.g., "107,135,200")
  # Uses nix-colorizer for accurate hex -> sRGB conversion
  hexToRgbCommaSeparated =
    color:
    let
      srgb = nix-colorizer.hex.to.srgb color.hex;
      # Convert from [0, 1] range to [0, 255] range and round
      r = builtins.floor (srgb.r * 255.0 + 0.5);
      g = builtins.floor (srgb.g * 255.0 + 0.5);
      b = builtins.floor (srgb.b * 255.0 + 0.5);
    in
    "${toString r},${toString g},${toString b}";

  # Add alpha channel to hex color in RRGGBBAA format (no # prefix)
  # Required for Fuzzel color format
  # Input: color object with .hex attribute, alpha value [0.0, 1.0]
  # Output: 8-character hex string without # (e.g., "6b87c8ff")
  hexWithAlpha =
    color: alpha:
    let
      # Strip # from hex color
      hexColor = lib.removePrefix "#" color.hex;

      # Convert alpha (0.0-1.0) to byte value (0-255)
      alphaByte = builtins.floor (alpha * 255.0 + 0.5);

      # Convert byte to 2-character uppercase hex string
      # We need to handle 0-15 (single digit) and 16-255 (double digit)
      toHexDigit =
        n:
        if n < 10 then
          toString n
        else if n == 10 then
          "A"
        else if n == 11 then
          "B"
        else if n == 12 then
          "C"
        else if n == 13 then
          "D"
        else if n == 14 then
          "E"
        else if n == 15 then
          "F"
        else
          throw "toHexDigit: invalid digit ${toString n}";

      # Split byte into high and low nibbles
      highNibble = alphaByte / 16;
      lowNibble = alphaByte - (highNibble * 16);

      alphaHex = toHexDigit highNibble + toHexDigit lowNibble;
    in
    lib.toUpper hexColor + alphaHex;

  # Validate hex color format
  # Returns: true if valid hex color (#RRGGBB or #RRGGBBAA format)
  isValidHexColor =
    str:
    let
      stripped = lib.removePrefix "#" str;
      len = builtins.stringLength stripped;
      validLength = len == 6 || len == 8;
      isHexChar = c: builtins.match "[0-9a-fA-F]" c != null;
      allHex = lib.all isHexChar (lib.stringToCharacters stripped);
    in
    (lib.hasPrefix "#" str) && validLength && allHex;

  # ============================================================================
  # Existing functions
  # ============================================================================

  # Centralized logic to determine if an application should be themed
  # Reduces boilerplate across all module files
  # Usage: shouldTheme = signalLib.shouldThemeApp "bat" cfg config;
  shouldThemeApp =
    appName: # Name of the app in signal config (e.g., "bat" for cfg.cli.bat)
    appPath: # Attribute path in signal config (e.g., ["cli" "bat"])
    cfg: # The theming.signal config
    config: # The full Home Manager config
    let
      signalEnable = lib.getAttrFromPath appPath cfg;
      programEnable = config.programs.${appName}.enable or false;
    in
    signalEnable.enable or false || (cfg.autoEnable && programEnable);

  # Validate that a theme mode is valid (dark or light, not auto)
  # Returns true if valid, false otherwise
  isValidResolvedMode = mode: mode == "dark" || mode == "light";

  # Get the theme name for a module (e.g., "signal-dark", "signal-light")
  # This ensures consistent theme naming across all modules
  getThemeName =
    mode:
    let
      resolved = resolveThemeMode mode;
    in
    "signal-${resolved}";

  # Get colors for a specific mode
  getColors = mode: {
    tonal = if mode == "dark" then palette.tonal.dark else palette.tonal.light;

    inherit (palette) accent;

    categorical = if mode == "dark" then palette.categorical.dark else palette.categorical.light;
  };

  # Get syntax highlighting colors for a specific mode
  # Provides consistent color mappings for code editors and syntax highlighters
  getSyntaxColors =
    mode:
    let
      colors = getColors mode;
    in
    {
      # Base colors - use palette for both modes
      background = colors.tonal."surface-base".hex;
      foreground = colors.tonal."text-primary".hex;
      caret = colors.accent.info.Lc75.hex;
      lineHighlight = colors.tonal."surface-hover".hex;
      selection = colors.tonal."divider-primary".hex;

      # Syntax elements - consistent across modes, palette handles lightness inversion
      comment = colors.tonal."text-tertiary".hex;
      string = colors.categorical."data-viz-02".hex;
      number = colors.categorical."data-viz-06".hex;
      keyword = colors.accent.tertiary.Lc75.hex;
      operator = colors.accent.secondary.Lc75.hex;
      function = colors.accent.info.Lc75.hex;
      type = colors.categorical."data-viz-06".hex;
      variable = colors.tonal."text-primary".hex;
      constant = colors.categorical."data-viz-06".hex;
      escape = colors.categorical."data-viz-08".hex;
      punctuation = colors.tonal."text-tertiary".hex;

      # Markup
      heading = colors.accent.danger.Lc75.hex;
      link = colors.accent.info.Lc75.hex;

      # Diff
      diffInserted = colors.categorical."data-viz-02".hex;
      diffDeleted = colors.accent.danger.Lc75.hex;
      diffChanged = colors.accent.info.Lc75.hex;
    };

  # Brand governance helpers
  brandGovernance = {
    # Merge brand colors with functional colors based on policy
    mergeColors =
      {
        policy,
        functionalColors,
        brandColors,
        decorativeBrandColors,
      }:
      if policy == "functional-override" then
        functionalColors // { decorative = decorativeBrandColors; }
      else if policy == "separate-layer" then
        functionalColors
        // {
          brand = brandColors;
          decorative = decorativeBrandColors;
        }
      else if policy == "integrated" then
        functionalColors // brandColors // { decorative = decorativeBrandColors; }
      else
        functionalColors;
  };

  # Accessibility helpers
  # NOTE: These are simplified approximations for basic validation.
  # They do NOT implement full APCA (Accessible Perceptual Contrast Algorithm).
  # For production accessibility compliance, use proper APCA tools or manual verification.
  # See: https://github.com/Myndex/SAPC-APCA
  accessibility = {
    # Simple contrast estimation based on lightness difference
    # This is a rough approximation and should NOT be relied upon for accessibility compliance
    # Returns: Estimated contrast value (0-108, where higher is better)
    estimateContrast =
      {
        foreground,
        background,
      }:
      let
        fg = foreground.l;
        bg = background.l;
        diff =
          let
            raw = fg - bg;
          in
          if raw < 0.0 then -raw else raw;
      in
      # WARNING: This is a linear approximation, not actual APCA
      # Real APCA is non-linear and considers perceptual factors
      diff * 108.0;

    # Check if contrast meets minimum requirement (using simplified estimation)
    # WARNING: Do not rely on this for accessibility compliance
    meetsMinimum =
      {
        foreground,
        background,
        minimum,
      }:
      let
        contrast = accessibility.estimateContrast { inherit foreground background; };
      in
      contrast >= minimum;
  };

  # Color manipulation helpers
  # NOTE: These functions only manipulate LCH values and do NOT recalculate hex/RGB.
  # The returned hex/hexRaw/rgb values will be incorrect if you use them.
  # Use these only if you need to adjust LCH values and will recalculate colors separately.
  colors = {
    # Adjust lightness while preserving chroma and hue
    # Returns: Color with adjusted L value (but original hex/rgb - DO NOT USE THOSE)
    # Use case: Calculate target lightness before passing to color generation system
    adjustLightness =
      {
        color,
        delta,
      }:
      {
        l = lib.max 0.0 (lib.min 1.0 (color.l + delta));
        inherit (color) c h;
        # WARNING: These values are WRONG after lightness adjustment
        # Do not use hex/hexRaw/rgb from the returned value
        # Include them only for type compatibility
        hex = throw "adjustLightness does not recalculate hex - use LCH values only";
        hexRaw = throw "adjustLightness does not recalculate hexRaw - use LCH values only";
        rgb = throw "adjustLightness does not recalculate rgb - use LCH values only";
      };

    # Adjust chroma while preserving lightness and hue
    # Returns: Color with adjusted C value (but original hex/rgb - DO NOT USE THOSE)
    # Use case: Calculate target chroma before passing to color generation system
    adjustChroma =
      {
        color,
        delta,
      }:
      {
        inherit (color) l h;
        c = lib.max 0.0 (color.c + delta);
        # WARNING: These values are WRONG after chroma adjustment
        # Do not use hex/hexRaw/rgb from the returned value
        hex = throw "adjustChroma does not recalculate hex - use LCH values only";
        hexRaw = throw "adjustChroma does not recalculate hexRaw - use LCH values only";
        rgb = throw "adjustChroma does not recalculate rgb - use LCH values only";
      };
  };
}
