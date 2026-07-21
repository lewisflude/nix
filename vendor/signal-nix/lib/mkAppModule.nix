# Module Generator Helper
# Reduces boilerplate when creating application theming modules
#
# This helper standardizes the common patterns used across all Signal modules:
# - Automatic theme activation logic (respecting autoEnable and explicit enables)
# - Standard option generation for each application
# - Tier-specific configuration generators
# - Validation helpers for colors and configuration
{
  lib,
  palette,
  nix-colorizer,
}:

let
  signalLib = import ./default.nix { inherit lib palette nix-colorizer; };

  # ============================================================================
  # Validation Helpers
  # ============================================================================

  # Validate that required fields exist in a configuration
  validateRequiredFields =
    requiredFields: config:
    let
      missingFields = lib.filter (field: !(config ? ${field})) requiredFields;
    in
    if missingFields != [ ] then
      throw "Missing required fields in application config: ${lib.concatStringsSep ", " missingFields}"
    else
      config;

  # Validate color format (hex string with # prefix)
  validateHexColor =
    colorValue:
    assert lib.assertMsg (signalLib.isValidHexColor colorValue)
      "Invalid hex color format: ${colorValue}. Must be #RRGGBB or #RRGGBBAA";
    colorValue;

  # Validate that all colors in an attrset are valid hex colors
  validateColorAttrset = colors: lib.mapAttrs (name: color: validateHexColor color.hex) colors;

  # ============================================================================
  # Core Module Generator
  # ============================================================================

  # Main module generator function
  # Supports all 4 tiers of integration with appropriate abstractions
  mkAppModule =
    {
      # Required parameters
      appName, # Name of the Home Manager program (e.g., "alacritty", "kitty", "bat")
      category, # Signal category path as list (e.g., ["terminals"], ["cli"], ["editors"])

      # Optional parameters
      tier ? 2, # Integration tier (1-4). Determines which helper to use
      configPath ? [ ], # Path within programs.<app> to place config (e.g., ["settings", "colors"])
      configGenerator, # Function: signalColors -> attrset (required for all tiers)

      # Advanced options
      extraOptions ? { }, # Additional module-specific options to include
      programCheck ? null, # Custom function to check if program is enabled
      usesService ? false, # If true, uses services.<app> instead of programs.<app>
      customActivationCheck ? null, # Custom function for theme activation (overrides default)
      validateConfig ? true, # Whether to validate generated config

      # Tier 1 specific (native themes)
      themeGenerator ? null, # Function: mode -> derivation (for Tier 1 only)
      themePackage ? null, # Optional pre-built theme package

      # Tier 4 specific (raw config)
      configSerializer ? null, # Function: attrset -> string (for custom serialization)
    }:
    {
      config,
      signalLib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkIf mkOption types;
      cfg = config.theming.signal;
      themeMode = signalLib.resolveThemeMode cfg.mode;

      # Get colors for the resolved theme mode
      signalColors = signalLib.getColors themeMode;

      # Determine if this app should be themed
      # Uses centralized logic or custom check if provided
      shouldTheme =
        if customActivationCheck != null then
          customActivationCheck config cfg
        else
          let
            # Build attribute path for Signal config
            appPath = category ++ [ appName ];
            appCfg = lib.getAttrFromPath appPath cfg;
            signalEnable = appCfg.enable or false;

            # Check program/service enable status
            programEnable =
              if programCheck != null then
                programCheck config
              else if usesService then
                config.services.${appName}.enable or false
              else
                config.programs.${appName}.enable or false;
          in
          signalEnable || (cfg.autoEnable && programEnable);

      # Generate the configuration based on tier
      generatedConfig =
        let
          rawConfig = configGenerator signalColors;
        in
        if validateConfig then
          rawConfig # Validation happens in configGenerator if needed
        else
          rawConfig;

      # Apply config at the correct path within programs.<app> or services.<app>
      appConfig =
        if configPath == [ ] then generatedConfig else lib.setAttrByPath configPath generatedConfig;

      # Determine the target attribute path
      targetAttrPath = if usesService then "services" else "programs";
    in
    {
      config = mkIf (cfg.enable && shouldTheme) { ${targetAttrPath}.${appName} = appConfig; };
    };

  # ============================================================================
  # Tier-Specific Helpers
  # ============================================================================

  # Tier 1: Native Theme Options
  # Best integration - uses Home Manager's native theme support
  # Example: bat, helix
  mkTier1Module =
    {
      appName,
      category,
      themeGenerator, # Function: mode -> derivation (theme file)
      themePath ? [ "themes" ], # Path to theme option (e.g., ["themes"] for programs.bat.themes)
      themeConfigPath ? [
        "config"
        "theme"
      ], # Path to theme config
      extraThemeConfig ? { }, # Additional theme-related config
    }:
    {
      config,
      signalLib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkIf;
      cfg = config.theming.signal;
      themeMode = signalLib.resolveThemeMode cfg.mode;

      # Get colors for the resolved theme mode
      signalColorsDark = signalLib.getColors "dark";
      signalColorsLight = signalLib.getColors "light";

      # Generate theme files for both modes
      darkTheme = themeGenerator "dark" signalColorsDark pkgs;
      lightTheme = themeGenerator "light" signalColorsLight pkgs;

      # Determine theme activation
      shouldTheme = signalLib.shouldThemeApp appName (category ++ [ appName ]) cfg config;

      # Build theme configuration
      themeName = signalLib.getThemeName cfg.mode;
      themeConfig = {
        signal-dark = darkTheme;
        signal-light = lightTheme;
      }
      // extraThemeConfig;

      # Select active theme
      activeTheme = if cfg.mode == "auto" then "auto" else "signal-${themeMode}";
    in
    {
      config = mkIf (cfg.enable && shouldTheme) {
        programs.${appName} =
          (lib.setAttrByPath themePath themeConfig)
          // (lib.setAttrByPath themeConfigPath (
            {
              theme = activeTheme;
              theme-dark = "signal-dark";
              theme-light = "signal-light";
            }
            // extraThemeConfig
          ));
      };
    };

  # Tier 2: Structured Colors
  # Good integration - uses typed color options
  # Example: alacritty
  mkTier2Module =
    {
      appName,
      category,
      colorMapping, # Function: signalColors -> { colors = { ... }; }
      configPath ? [
        "settings"
        "colors"
      ],
      extraConfig ? { },
    }:
    mkAppModule {
      inherit
        appName
        category
        configPath
        ;
      tier = 2;
      configGenerator =
        signalColors:
        let
          colors = colorMapping signalColors;
        in
        colors // extraConfig;
    };

  # Tier 3: Freeform Settings
  # Acceptable integration - uses settings attrset
  # Example: kitty, ghostty, zellij
  mkTier3Module =
    {
      appName,
      category,
      settingsGenerator, # Function: signalColors -> signalLib -> { setting-key = "value"; ... }
      configPath ? [ "settings" ],
      extraSettings ? { },
    }:
    mkAppModule {
      inherit
        appName
        category
        configPath
        ;
      tier = 3;
      configGenerator =
        signalColors:
        let
          settings = settingsGenerator signalColors signalLib;
        in
        settings // extraSettings;
    };

  # Tier 4: Raw Config
  # Last resort - generates raw config strings
  # Example: wezterm, gtk, tmux
  mkTier4Module =
    {
      appName,
      category,
      configGenerator, # Function: signalColors -> themeMode -> pkgs -> string
      configOption ? "extraConfig", # Name of config option (e.g., "extraConfig", "extraCss")
      usesService ? false,
    }:
    {
      config,
      signalLib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkIf;
      cfg = config.theming.signal;
      themeMode = signalLib.resolveThemeMode cfg.mode;

      # Get colors for the resolved theme mode
      signalColors = signalLib.getColors themeMode;

      # Generate raw config string
      rawConfig = configGenerator signalColors themeMode pkgs;

      # Determine theme activation
      shouldTheme = signalLib.shouldThemeApp appName (category ++ [ appName ]) cfg config;

      targetAttrPath = if usesService then "services" else "programs";
    in
    {
      config = mkIf (cfg.enable && shouldTheme) {
        ${targetAttrPath}.${appName}.${configOption} = rawConfig;
      };
    };

  # ============================================================================
  # Convenience Helpers
  # ============================================================================

  # Simplified version for basic apps that just set programs.<app>.settings directly
  mkSimpleAppModule =
    {
      appName,
      category,
      configGenerator,
    }:
    mkAppModule {
      inherit appName category configGenerator;
      configPath = [ ];
    };

  # For apps that need service configuration instead of program configuration
  mkServiceModule =
    {
      appName, # Can be serviceName, kept as appName for consistency
      category,
      configGenerator,
      configPath ? [ ],
    }:
    mkAppModule {
      inherit
        appName
        category
        configGenerator
        configPath
        ;
      usesService = true;
    };

  # ============================================================================
  # Standard Color Mappings
  # ============================================================================

  # Standard ANSI color mapping used by most terminal applications
  # Returns an attrset with normal and bright ANSI colors
  makeAnsiColors =
    signalColors:
    let
      inherit (signalColors) accent;
    in
    {
      # Normal colors (0-7)
      black = signalColors.tonal."black";
      red = accent.danger.Lc75;
      green = accent.primary.Lc75;
      yellow = accent.warning.Lc75;
      blue = accent.secondary.Lc75;
      magenta = accent.tertiary.Lc75;
      cyan = accent.info.Lc75;
      white = signalColors.tonal."text-secondary";

      # Bright colors (8-15)
      bright-black = signalColors.tonal."text-tertiary";
      bright-red = accent.danger.Lc75;
      bright-green = accent.primary.Lc75;
      bright-yellow = accent.warning.Lc75;
      bright-blue = accent.secondary.Lc75;
      bright-magenta = accent.tertiary.Lc75;
      bright-cyan = accent.info.Lc75;
      bright-white = signalColors.tonal."text-primary";
    };

  # Standard UI color mapping for applications
  # Returns an attrset with common UI color roles
  makeUIColors = signalColors: {
    # Surface colors
    surface-base = signalColors.tonal."surface-base";
    surface-subtle = signalColors.tonal."surface-subtle";
    surface-hover = signalColors.tonal."surface-hover";

    # Text colors
    text-primary = signalColors.tonal."text-primary";
    text-secondary = signalColors.tonal."text-secondary";
    text-tertiary = signalColors.tonal."text-tertiary";

    # Divider/border colors
    divider-primary = signalColors.tonal."divider-primary";
    divider-strong = signalColors.tonal."divider-strong";

    # Accent colors
    accent-primary = signalColors.accent.primary.Lc75;
    accent-secondary = signalColors.accent.secondary.Lc75;
    accent-tertiary = signalColors.accent.tertiary.Lc75;

    # Semantic colors
    success = signalColors.accent.primary.Lc75;
    warning = signalColors.accent.warning.Lc75;
    danger = signalColors.accent.danger.Lc75;
    info = signalColors.accent.info.Lc75;
  };

  # ============================================================================
  # Export
  # ============================================================================
in
{
  inherit
    # Main generators
    mkAppModule
    mkTier1Module
    mkTier2Module
    mkTier3Module
    mkTier4Module

    # Convenience helpers
    mkSimpleAppModule
    mkServiceModule

    # Color mapping helpers
    makeAnsiColors
    makeUIColors

    # Validation helpers
    validateRequiredFields
    validateHexColor
    validateColorAttrset
    ;
}
