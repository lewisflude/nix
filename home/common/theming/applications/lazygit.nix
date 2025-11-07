{
  config,
  lib,
  pkgs,
  scientificPalette ? null,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.scientific;
  theme = scientificPalette;
in
{
  config = mkIf (cfg.enable && cfg.applications.lazygit.enable && theme != null) {
    programs.lazygit.settings = {
      gui = {
        theme = with theme.semantic; {
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
