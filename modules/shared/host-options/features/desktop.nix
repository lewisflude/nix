# Desktop Environment Feature Options
{
  lib,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  desktop = {
    enable = mkEnableOption "desktop environment and customization" // {
      default = true;
    };
    niri = mkEnableOption "Niri Wayland compositor" // {
      default = false;
    };
    hyprland = mkEnableOption "Hyprland Wayland compositor" // {
      default = false;
    };
    theming = mkEnableOption "system-wide theming" // {
      default = true;
    };
    utilities = mkEnableOption "desktop utilities" // {
      default = false;
    };

    # Signal theme options
    signalTheme = {
      enable = mkEnableOption "Signal OKLCH color palette theme" // {
        default = true;
      };
      mode = mkOption {
        type = types.enum [
          "light"
          "dark"
          "auto"
        ];
        default = "dark";
        description = ''
          Color theme mode:
          - light: Use light mode colors
          - dark: Use dark mode colors
          - auto: Follow system preference (defaults to dark)
        '';
        example = "auto";
      };
    };
  };
}
