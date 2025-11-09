{
  config,
  lib,
  pkgs,
  themeContext ? null,
  signalPalette ? null, # Backward compatibility
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  # Use themeContext if available, otherwise fall back to signalPalette for backward compatibility
  theme = themeContext.theme or signalPalette;
in
{
  config = mkIf (cfg.enable && cfg.applications.lazygit.enable && theme != null) {
    programs.lazygit.settings = {
      gui = {
        theme = with (theme.colors or theme.semantic); {
          selectedLineBgColor = [ surface-subtle.hex ];
          selectedRangeBgColor = [ surface-emphasis.hex ];
          activeBorderColor = [ accent-primary.hex ];
          inactiveBorderColor = [ divider-primary.hex ];
          searchingActiveBorderColor = [ accent-focus.hex ];
          optionsTextColor = [ accent-info.hex ];
          defaultFgColor = [ text-primary.hex ];
        };
      };
    };
  };
}
