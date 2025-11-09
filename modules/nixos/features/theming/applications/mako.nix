{
  config,
  lib,
  pkgs,
  signalPalette ? null,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  theme = signalPalette;
  colors = theme.colors;
in
{
  config = mkIf (cfg.enable && cfg.applications.mako.enable && theme != null) {
    # Apply theme colors to Mako notification daemon via home-manager
    # Mako uses background-color, text-color, border-color, etc. in its settings
    home-manager.users.${config.host.username} = {
      services.mako = {
        settings = {
          # Base colors for notifications
          background-color = colors."surface-base".hex;
          text-color = colors."text-primary".hex;
          border-color = colors."divider-primary".hex;
        };

        # Urgency-specific colors (mako uses INI-style sections in extraConfig)
        extraConfig = ''
          [urgency=low]
          background-color=${colors."surface-subtle".hex}
          text-color=${colors."text-secondary".hex}
          border-color=${colors."divider-secondary".hex}

          [urgency=normal]
          background-color=${colors."surface-base".hex}
          text-color=${colors."text-primary".hex}
          border-color=${colors."divider-primary".hex}

          [urgency=critical]
          background-color=${colors."accent-danger".hex}
          text-color=${colors."surface-base".hex}
          border-color=${colors."accent-danger".hex}
        '';
      };
    };
  };
}
