{
  config,
  lib,
  themeContext ? null,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  inherit (themeContext) theme;
in
{
  config = mkIf (cfg.enable && cfg.applications.lazygit.enable && theme != null) {
    programs.lazygit.settings = {
      gui = {
        theme = with theme.colors; {
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
