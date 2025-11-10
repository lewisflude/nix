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
  config = mkIf (cfg.enable && cfg.applications.ghostty.enable && theme != null) {
    programs.ghostty = {
      settings =
        let
          inherit (theme) colors;
          # Helper to get hex without # prefix (for theme colors)
          hexRaw = color: lib.removePrefix "#" color.hex;
        in
        {
          # Set colors directly (ghostty doesn't support nested theme definitions in Home Manager)
          # Background and foreground (without # prefix)
          background = hexRaw colors."surface-base";
          foreground = hexRaw colors."text-primary";

          # Cursor colors (without # prefix)
          "cursor-color" = hexRaw colors."accent-primary";
          "cursor-text" = hexRaw colors."surface-base";

          # Selection colors (without # prefix)
          "selection-background" = hexRaw colors."divider-primary";
          "selection-foreground" = hexRaw colors."text-primary";

          # Split divider color (without # prefix)
          "split-divider-color" = hexRaw colors."divider-primary";

          # ANSI color palette (ghostty uses palette = N=COLOR format)
          # Set as a list for repeatable configuration field
          palette = [
            "0=${colors."ansi-black".hex}"
            "1=${colors."ansi-red".hex}"
            "2=${colors."ansi-green".hex}"
            "3=${colors."ansi-yellow".hex}"
            "4=${colors."ansi-blue".hex}"
            "5=${colors."ansi-magenta".hex}"
            "6=${colors."ansi-cyan".hex}"
            "7=${colors."ansi-white".hex}"
            # Bright colors (8-15)
            "8=${colors."ansi-bright-black".hex}"
            "9=${colors."ansi-red".hex}"
            "10=${colors."ansi-green".hex}"
            "11=${colors."ansi-yellow".hex}"
            "12=${colors."ansi-blue".hex}"
            "13=${colors."ansi-magenta".hex}"
            "14=${colors."ansi-cyan".hex}"
            "15=${colors."ansi-bright-white".hex}"
          ];
        };
    };
  };
}
