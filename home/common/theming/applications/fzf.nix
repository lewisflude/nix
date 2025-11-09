{
  config,
  lib,
  signalPalette ? null,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  theme = signalPalette;
in
{
  config = mkIf (cfg.enable && cfg.applications.fzf.enable && theme != null) {
    programs.fzf.colors = with theme.semantic; {
      # fzf requires hex colors with # prefix
      fg = text-primary.hex;
      bg = surface-base.hex;
      hl = accent-primary.hex;
      "fg+" = text-primary.hex;
      "bg+" = surface-subtle.hex;
      "hl+" = accent-focus.hex;
      info = accent-info.hex;
      prompt = accent-primary.hex;
      pointer = accent-focus.hex;
      marker = accent-primary.hex;
      spinner = accent-info.hex;
      header = text-secondary.hex;
    };
  };
}
