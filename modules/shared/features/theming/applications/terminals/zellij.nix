{
  config,
  lib,
  themeContext ? null,
  ...
}:
let
  inherit (lib) mkIf removePrefix;
  cfg = config.theming.signal;
  inherit (themeContext) theme;

  # Helper to get hex without # prefix (Zellij uses hex without #)
  hexRaw = color: removePrefix "#" color.hex;

  # Generate Zellij theme in KDL format
  # Zellij uses a specific set of color keys in its theme system
  zellijThemeKdl = ''
    // Signal Theme for Zellij
    // Auto-generated from Signal theme palette
    themes {
      signal {
        // Foreground/background
        fg "${hexRaw theme.colors."text-primary"}"
        bg "${hexRaw theme.colors."surface-base"}"

        // UI elements
        black "${hexRaw theme.colors."ansi-black"}"
        red "${hexRaw theme.colors."ansi-red"}"
        green "${hexRaw theme.colors."ansi-green"}"
        yellow "${hexRaw theme.colors."ansi-yellow"}"
        blue "${hexRaw theme.colors."ansi-blue"}"
        magenta "${hexRaw theme.colors."ansi-magenta"}"
        cyan "${hexRaw theme.colors."ansi-cyan"}"
        white "${hexRaw theme.colors."ansi-white"}"

        // Bright colors
        orange "${hexRaw theme.colors."accent-warning"}"
        gray "${hexRaw theme.colors."text-secondary"}"
        purple "${hexRaw theme.colors."accent-special"}"
        gold "${hexRaw theme.colors."accent-warning"}"
        silver "${hexRaw theme.colors."divider-primary"}"
        pink "${hexRaw theme.colors."accent-danger"}"
        brown "${hexRaw theme.colors."accent-warning"}"
      }
    }
  '';
in
{
  config = mkIf (cfg.enable && cfg.applications.zellij.enable && theme != null) {
    # Add theme configuration to Zellij
    # This will be merged with the existing extraConfig
    xdg.configFile."zellij/themes/signal.kdl".text = zellijThemeKdl;

    # Set the theme in Zellij settings
    programs.zellij.settings = {
      theme = "signal";
    };
  };
}
