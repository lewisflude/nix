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
    _config:
    # For now, default to dark mode
    # TODO: Implement actual system detection
    # This would require:
    # - Running gsettings commands (not possible in pure Nix evaluation)
    # - Reading systemd environment (not available at eval time)
    # - Reading XDG config files (possible but complex)
    #
    # Future implementation could:
    # - Use a systemd service to detect and cache preference
    # - Use a helper script that runs at build time
    # - Use environment variables set by the desktop environment
    "dark";

  # Compare two modes (useful for validation)
  modesEqual = mode1: mode2: normalizeMode mode1 == normalizeMode mode2;

  # Get resolved mode from config (convenience function)
  # This is the main function modules should use
  getResolvedMode = cfg: resolveMode (cfg.mode or "dark");
}
