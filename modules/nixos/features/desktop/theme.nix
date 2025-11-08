{
  config,
  lib,
  ...
}:
let
  cfg = config.host.features.desktop;
in
{

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # System-level Catppuccin theme configuration
      # This enables theming for system services like greetd, plymouth, tty, etc.
      # Disabled in favor of Scientific theme
      {
        catppuccin = {
          enable = false;
          flavor = "mocha";
          accent = "mauve";
        };
      }

      # System-level Scientific theme configuration (NixOS only)
      (lib.mkIf cfg.scientificTheme.enable {
        theming.scientific = {
          enable = true;
          mode = cfg.scientificTheme.mode;

          applications = {
            # Enable all Wayland/Linux desktop components
            waybar.enable = lib.mkDefault false; # Not using waybar currently
            fuzzel.enable = lib.mkDefault true;
            ironbar.enable = lib.mkDefault true;
            mako.enable = lib.mkDefault true;
            swaync.enable = lib.mkDefault true;
            swappy.enable = lib.mkDefault true;
          };
        };
      })
    ]
  );
}
