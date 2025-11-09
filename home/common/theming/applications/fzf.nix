{
  config,
  lib,
  scientificPalette ? null,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.scientific;
  theme = scientificPalette;
  # Helper to strip # prefix from hex colors for FZF (FZF expects hex without #)
  stripHash = hex: lib.removePrefix "#" hex;
in
{
  config = mkIf (cfg.enable && cfg.applications.fzf.enable && theme != null) {
    programs.fzf.colors = with theme.semantic; {
      fg = stripHash text-primary.hex;
      bg = stripHash surface-base.hex;
      hl = stripHash accent-primary.hex;
      "fg+" = stripHash text-primary.hex;
      "bg+" = stripHash surface-subtle.hex;
      "hl+" = stripHash accent-focus.hex;
      info = stripHash accent-info.hex;
      prompt = stripHash accent-primary.hex;
      pointer = stripHash accent-focus.hex;
      marker = stripHash accent-primary.hex;
      spinner = stripHash accent-info.hex;
      header = stripHash text-secondary.hex;
    };
  };
}
