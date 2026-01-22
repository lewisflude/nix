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
      example = true;
    };
    niri = mkEnableOption "Niri Wayland compositor" // {
      default = false;
      example = true;
    };
    hyprland = mkEnableOption "Hyprland Wayland compositor" // {
      default = false;
      example = true;
    };
    theming = mkEnableOption "system-wide theming" // {
      default = true;
      example = true;
    };
    utilities = mkEnableOption "desktop utilities" // {
      default = false;
      example = true;
    };

    # Signal theme options
    signalTheme = {
      enable = mkEnableOption "Signal OKLCH color palette theme" // {
        default = true;
        example = true;
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
