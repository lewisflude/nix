{
  config,
  lib,
  themeContext ? null,
  signalPalette ? null, # Backward compatibility
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  # Use themeContext if available, otherwise fall back to signalPalette for backward compatibility
  theme = themeContext.theme or signalPalette;

  # Get semantic colors (prefer colors over semantic for new API)
  semantic = theme.colors or theme.semantic or { };

  # Helper to ensure hex color has # prefix
  # Home Manager's fzf module should handle this, but we ensure it's correct
  ensureHex =
    color:
    let
      hexValue =
        if builtins.isString color then
          color
        else if color ? hex then
          color.hex
        else
          throw "Invalid color format for fzf: ${toString color}";
    in
    if lib.hasPrefix "#" hexValue then hexValue else "#${hexValue}";
in
{
  config = mkIf (cfg.enable && cfg.applications.fzf.enable && theme != null) {
    programs.fzf.colors = {
      # fzf requires hex colors with # prefix
      # Ensure all colors have the # prefix
      fg = ensureHex semantic."text-primary";
      bg = ensureHex semantic."surface-base";
      hl = ensureHex semantic."accent-primary";
      "fg+" = ensureHex semantic."text-primary";
      "bg+" = ensureHex semantic."surface-subtle";
      "hl+" = ensureHex semantic."accent-focus";
      info = ensureHex semantic."accent-info";
      prompt = ensureHex semantic."accent-primary";
      pointer = ensureHex semantic."accent-focus";
      marker = ensureHex semantic."accent-primary";
      spinner = ensureHex semantic."accent-info";
      header = ensureHex semantic."text-secondary";
    };
  };
}
