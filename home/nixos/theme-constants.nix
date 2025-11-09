{
  lib,
  ...
}:
let
  # Scientific Theme - Dark Mode Palette
  # Based on OKLCH color space for perceptually uniform colors
  palette = {
    # Focus/Primary actions - Blue (h240)
    focus = "#5a7dcf"; # Lc75-h240
    focusDim = "#3a5da3"; # Lc60-h240

    # Special/Accent - Purple (h290)
    special = "#a368cf"; # Lc75-h290
    specialDim = "#7d49a3"; # Lc60-h290

    # Danger/Error - Red (h040)
    danger = "#d9574a"; # Lc75-h040

    # Surfaces and dividers
    base = "#1e1f26"; # base-L015
    surface = "#2d2e39"; # surface-Lc10
    divider = "#454759"; # divider-Lc30
    dividerSubtle = "#353642"; # divider-Lc15

    # Text colors
    textPrimary = "#c0c3d1"; # text-Lc75
    textSecondary = "#9498ab"; # text-Lc60
    textTertiary = "#6b6f82"; # text-Lc45
  };
in
{
  niri.colors = {
    focus-ring = {
      active = lib.mkDefault palette.focus;
      inactive = lib.mkDefault palette.textTertiary;
    };
    border = {
      active = lib.mkDefault palette.special;
      inactive = lib.mkDefault palette.divider;
      urgent = lib.mkDefault palette.danger;
    };
    shadow = lib.mkDefault "${palette.base}aa";
    tab-indicator = {
      active = lib.mkDefault palette.special;
      inactive = lib.mkDefault palette.textTertiary;
    };
  };
}
