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
  config = mkIf (cfg.enable && cfg.applications.ghostty.enable && theme != null) {
    programs.ghostty = {
      settings =
        let
          colors = theme.semantic;
        in
        {
          # Background and foreground
          background = colors."surface-base".hex;
          foreground = colors."text-primary".hex;

          # Cursor
          cursor-color = colors."accent-primary".hex;
          cursor-text = colors."surface-base".hex;

          # Selection
          selection-background = "${colors."accent-primary".hex}";
          selection-foreground = colors."surface-base".hex;

          # ANSI colors (0-7: normal colors)
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
