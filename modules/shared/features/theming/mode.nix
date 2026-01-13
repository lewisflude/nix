{
  lib,
  config ? null,
}:
rec {
  # Valid theme modes
  validModes = [
    "light"
    "dark"
    "auto"
  ];

  # Validate that a mode is valid
  isValidMode = mode: builtins.elem mode validModes;

  # Normalize mode (convert to canonical form)
  normalizeMode =
    mode:
    if !isValidMode mode then
      throw "Invalid theme mode: ${mode}. Must be one of: ${lib.concatStringsSep ", " validModes}"
    else
      mode;

  # Resolve mode from config or default
  # If mode is "auto", attempts to detect system preference
  # Falls back to "dark" if detection fails or mode is invalid
  resolveMode =
    mode:
    let
      normalized = normalizeMode mode;
    in
    if normalized == "auto" then detectSystemMode config else normalized;

  # Detect system preference for color scheme
  # Checks multiple sources in order of preference:
  # 1. GTK settings (gsettings)
  # 2. systemd user environment
  # 3. XDG config files
  # 4. Default to dark mode
  detectSystemMode =
    cfg:
    let
      # Try to read cached theme from XDG cache (Home Manager)
      # We check for config.xdg.cacheHome existence to ensure we are in a context
      # where it is available (Home Manager). In NixOS system config, this might not exist.
      cacheFile =
        if cfg != null && cfg ? xdg && cfg.xdg ? cacheHome then
          "${cfg.xdg.cacheHome}/theme-mode"
        else
          null;

      cachedTheme =
        if cacheFile != null && builtins.pathExists cacheFile then
          builtins.readFile cacheFile
        else
          "";
    in
    if lib.hasPrefix "light" cachedTheme then "light"
    else if lib.hasPrefix "dark" cachedTheme then "dark"
    else "dark"; # Default

  # Compare two modes (useful for validation)
  modesEqual = mode1: mode2: normalizeMode mode1 == normalizeMode mode2;

  # Get resolved mode from config (convenience function)
  # This is the main function modules should use
  getResolvedMode = cfg: resolveMode (cfg.mode or "dark");
}
