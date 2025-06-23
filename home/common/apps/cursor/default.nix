{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkMerge
    mkIf
    optional
    pathExists
    warn
    ;

  # ==== MODULE IMPORTS WITH ERROR HANDLING ====

  # Safe import function that provides fallbacks
  safeImport =
    path: fallback:
    if pathExists path then
      import path
    else
      warn "Missing config file: ${toString path}, using fallback" fallback;

  # Import core modules with validation
  constants =
    (safeImport ./constants.nix {
      commonIgnores = {
        "**/.DS_Store" = true;
        "**/.git" = true;
      };
      watcherIgnores = {
        "**/.DS_Store" = true;
        "**/.git" = true;
      };
    })
      { };

  coreSettings =
    (safeImport ./settings.nix {
      userSettings = { };
    })
      { inherit pkgs constants; };

  languageSettings =
    (safeImport ./language-settings.nix {
      userSettings = { };
    })
      { };

  aiSettings =
    (safeImport ./ai-settings.nix {
      userSettings = { };
    })
      { };

  extensions =
    (safeImport ./extensions.nix {
      extensions = [ ];
    })
      { inherit pkgs lib; };

  # ==== USER CONFIGURATION HANDLING ====

  # User config path and validation
  userConfigPath = ./user-config.nix;
  userConfigExists = pathExists userConfigPath;

  # Safe user config import with validation
  userConfig =
    if userConfigExists then
      let
        importedConfig = import userConfigPath { };
        # Validate that userConfig has the expected structure
        isValidConfig = importedConfig ? userSettings && builtins.isAttrs importedConfig.userSettings;
      in
      if isValidConfig then
        importedConfig
      else
        warn "Invalid user-config.nix structure, expected { userSettings = {}; }" { userSettings = { }; }
    else
      { userSettings = { }; };

  # ==== SETTINGS VALIDATION ====

  # Validate that all core modules loaded properly
  hasValidCoreSettings = coreSettings ? userSettings && builtins.isAttrs coreSettings.userSettings;
  hasValidLanguageSettings =
    languageSettings ? userSettings && builtins.isAttrs languageSettings.userSettings;
  hasValidAiSettings = aiSettings ? userSettings && builtins.isAttrs aiSettings.userSettings;
  hasValidExtensions = extensions ? extensions && builtins.isList extensions.extensions;

  # Validation warnings
  validationWarnings =
    optional (!hasValidCoreSettings) "Core settings validation failed"
    ++ optional (!hasValidLanguageSettings) "Language settings validation failed"
    ++ optional (!hasValidAiSettings) "AI settings validation failed"
    ++ optional (!hasValidExtensions) "Extensions validation failed";

  # ==== SETTINGS COMPOSITION ====

  # Merge all user settings with proper precedence
  # Order: core -> language -> ai -> user (user overrides all)
  allUserSettings = mkMerge (
    # Always include core settings (even if validation failed, use empty fallback)
    [ (if hasValidCoreSettings then coreSettings.userSettings else { }) ]

    # Add language settings if valid
    ++ optional hasValidLanguageSettings languageSettings.userSettings

    # Add AI settings if valid
    ++ optional hasValidAiSettings aiSettings.userSettings

    # Add user settings if they exist and are non-empty
    ++ optional (userConfig.userSettings != { }) userConfig.userSettings
  );

  # ==== EXTENSION COMPOSITION ====

  # Safe extension list with fallback
  extensionList = if hasValidExtensions then extensions.extensions else [ ];

  # ==== CONFIGURATION VALIDATION SUMMARY ====

  # Create a summary of what loaded successfully
  configSummary = {
    constants = constants != { };
    coreSettings = hasValidCoreSettings;
    languageSettings = hasValidLanguageSettings;
    aiSettings = hasValidAiSettings;
    extensions = hasValidExtensions;
    userConfig = userConfigExists && userConfig.userSettings != { };
    warnings = validationWarnings;
  };

  # Debug info (only shown if there are issues)
  debugInfo =
    if validationWarnings != [ ] then
      warn "Cursor configuration validation issues: ${toString validationWarnings}" true
    else
      true;

in
{
  # ==== CONDITIONAL VSCODE CONFIGURATION ====

  home.activation.makeVSCodeConfigWritable = mkIf pkgs.stdenv.isDarwin (
    let
      configPath = "${config.home.homeDirectory}/Library/Application\\ Support/Cursor/User/settings.json";
    in
    {
      after = [ "writeBoundary" ];
      before = [ ];
      data = ''
        install -m 0640 "$(readlink ${configPath})" ${configPath}
      '';
    }
  );

  # Only enable if we have at least basic settings
  programs.vscode = mkIf (hasValidCoreSettings || allUserSettings != { }) {
    enable = true;
    package = pkgs.code-cursor;

    profiles.default = {
      userSettings = allUserSettings;
      extensions = extensionList;
    };
  };

  # ==== DEVELOPMENT/DEBUG INFORMATION ====

  # Expose configuration summary for debugging (commented out by default)
  # This can be uncommented if you need to debug configuration loading issues
  # home.file.".cursor-config-debug.json".text = builtins.toJSON configSummary;

  # ==== ASSERTIONS FOR CRITICAL ISSUES ====

  # Add assertions to catch critical configuration errors
  assertions = [
    {
      assertion = pkgs ? code-cursor;
      message = "code-cursor package not found in pkgs. Ensure you have the cursor overlay or package available.";
    }
    {
      assertion = constants != { };
      message = "Constants module failed to load. Check constants.nix for syntax errors.";
    }
    {
      assertion = validationWarnings == [ ] || lib.length validationWarnings < 3;
      message = "Too many configuration validation failures (${toString (lib.length validationWarnings)}). Check your configuration files.";
    }
  ];

  # ==== SUCCESS CONFIRMATION ====

  # Silent validation - ensures debugInfo is evaluated
  home.activation.cursorConfigValidation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${if debugInfo then "# Cursor configuration loaded successfully" else ""}
  '';
}
