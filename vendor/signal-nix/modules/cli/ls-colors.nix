# Signal LS_COLORS Module
#
# ⚠️  DEPRECATION NOTICE: Consider using the vivid module instead (cli/vivid.nix)
# The vivid module provides:
# - More comprehensive file type database (hundreds of types)
# - Better maintainability (YAML themes vs hardcoded strings)
# - RGB hex color support with automatic 24-bit/8-bit conversion
# - Industry standard used by fd, eza, tree, and many other tools
#
# This module sets LS_COLORS for traditional ls and tools that respect it.
# LS_COLORS is widely used by:
# - GNU ls and BSD ls
# - Shell completions (zsh, bash, fish)
# - File managers and various CLI tools
# - Any tool that checks LS_COLORS for file type colors
#
# Note: This is separate from EZA_COLORS (eza-specific format)
{
  signalLib,
  signalPalette,
  semantic,
  nix-colorizer,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
# CONFIGURATION METHOD: environment-variables (Tier 5)
# HOME-MANAGER MODULE: home.sessionVariables
# UPSTREAM SCHEMA: https://www.gnu.org/software/coreutils/manual/html_node/General-output-formatting.html
# SCHEMA VERSION: coreutils 9.4
# LAST VALIDATED: 2026-01-20
# NOTES: LS_COLORS uses colon-separated key=value pairs with ANSI color codes.
#        Format follows the dircolors output format.
let
  inherit (lib) mkIf concatStringsSep;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Build LS_COLORS string from Signal colors
  # Note: LS_COLORS uses ANSI color codes, not hex colors
  # We use a simplified mapping of Signal color concepts to ANSI codes
  lsColors =
    let
      colors =
        if signalLib.resolveThemeMode cfg.mode == "dark" then
          {
            # Reset and defaults
            "rs" = "0"; # reset
            "di" = "01;34"; # directory - bold blue
            "ln" = "01;36"; # symbolic link - bold cyan
            "mh" = "00"; # multi-hardlink
            "pi" = "40;33"; # pipe/FIFO - black background, yellow text
            "so" = "01;35"; # socket - bold magenta
            "do" = "01;35"; # door - bold magenta
            "bd" = "40;33;01"; # block device - black bg, bold yellow
            "cd" = "40;33;01"; # character device - black bg, bold yellow
            "or" = "40;31;01"; # orphaned symlink - black bg, bold red
            "mi" = "00"; # missing file (orphaned symlink target)
            "su" = "37;41"; # setuid file - white on red
            "sg" = "30;43"; # setgid file - black on yellow
            "ca" = "00"; # file with capability
            "tw" = "30;42"; # sticky+other-writable dir - black on green
            "ow" = "34;42"; # other-writable dir - blue on green
            "st" = "37;44"; # sticky dir - white on blue
            "ex" = "01;32"; # executable - bold green

            # Archives and compressed files - using warning color (180 -> 38;5;180)
            "*.tar" = "38;5;180";
            "*.tgz" = "38;5;180";
            "*.arc" = "38;5;180";
            "*.arj" = "38;5;180";
            "*.taz" = "38;5;180";
            "*.lha" = "38;5;180";
            "*.lz4" = "38;5;180";
            "*.lzh" = "38;5;180";
            "*.lzma" = "38;5;180";
            "*.tlz" = "38;5;180";
            "*.txz" = "38;5;180";
            "*.tzo" = "38;5;180";
            "*.t7z" = "38;5;180";
            "*.zip" = "38;5;180";
            "*.z" = "38;5;180";
            "*.dz" = "38;5;180";
            "*.gz" = "38;5;180";
            "*.lrz" = "38;5;180";
            "*.lz" = "38;5;180";
            "*.lzo" = "38;5;180";
            "*.xz" = "38;5;180";
            "*.zst" = "38;5;180";
            "*.tzst" = "38;5;180";
            "*.bz2" = "38;5;180";
            "*.bz" = "38;5;180";
            "*.tbz" = "38;5;180";
            "*.tbz2" = "38;5;180";
            "*.tz" = "38;5;180";
            "*.deb" = "38;5;180";
            "*.rpm" = "38;5;180";
            "*.jar" = "38;5;180";
            "*.war" = "38;5;180";
            "*.ear" = "38;5;180";
            "*.sar" = "38;5;180";
            "*.rar" = "38;5;180";
            "*.alz" = "38;5;180";
            "*.ace" = "38;5;180";
            "*.zoo" = "38;5;180";
            "*.cpio" = "38;5;180";
            "*.7z" = "38;5;180";
            "*.rz" = "38;5;180";
            "*.cab" = "38;5;180";
            "*.wim" = "38;5;180";
            "*.swm" = "38;5;180";
            "*.dwm" = "38;5;180";
            "*.esd" = "38;5;180";

            # Image formats - using categorical color (141 -> 38;5;141)
            "*.jpg" = "38;5;141";
            "*.jpeg" = "38;5;141";
            "*.mjpg" = "38;5;141";
            "*.mjpeg" = "38;5;141";
            "*.gif" = "38;5;141";
            "*.bmp" = "38;5;141";
            "*.pbm" = "38;5;141";
            "*.pgm" = "38;5;141";
            "*.ppm" = "38;5;141";
            "*.tga" = "38;5;141";
            "*.xbm" = "38;5;141";
            "*.xpm" = "38;5;141";
            "*.tif" = "38;5;141";
            "*.tiff" = "38;5;141";
            "*.png" = "38;5;141";
            "*.svg" = "38;5;141";
            "*.svgz" = "38;5;141";
            "*.mng" = "38;5;141";
            "*.pcx" = "38;5;141";
            "*.webp" = "38;5;141";
            "*.avif" = "38;5;141";

            # Video formats - using categorical color (120 -> 38;5;120)
            "*.mov" = "38;5;120";
            "*.mpg" = "38;5;120";
            "*.mpeg" = "38;5;120";
            "*.m2v" = "38;5;120";
            "*.mkv" = "38;5;120";
            "*.webm" = "38;5;120";
            "*.ogm" = "38;5;120";
            "*.mp4" = "38;5;120";
            "*.m4v" = "38;5;120";
            "*.mp4v" = "38;5;120";
            "*.vob" = "38;5;120";
            "*.qt" = "38;5;120";
            "*.nuv" = "38;5;120";
            "*.wmv" = "38;5;120";
            "*.asf" = "38;5;120";
            "*.rm" = "38;5;120";
            "*.rmvb" = "38;5;120";
            "*.flc" = "38;5;120";
            "*.avi" = "38;5;120";
            "*.fli" = "38;5;120";
            "*.flv" = "38;5;120";
            "*.gl" = "38;5;120";
            "*.dl" = "38;5;120";
            "*.xcf" = "38;5;120";
            "*.xwd" = "38;5;120";
            "*.yuv" = "38;5;120";
            "*.cgm" = "38;5;120";
            "*.emf" = "38;5;120";

            # Audio formats - using categorical color (111 -> 38;5;111)
            "*.aac" = "38;5;111";
            "*.au" = "38;5;111";
            "*.flac" = "38;5;111";
            "*.m4a" = "38;5;111";
            "*.mid" = "38;5;111";
            "*.midi" = "38;5;111";
            "*.mka" = "38;5;111";
            "*.mp3" = "38;5;111";
            "*.mpc" = "38;5;111";
            "*.ogg" = "38;5;111";
            "*.ra" = "38;5;111";
            "*.wav" = "38;5;111";
            "*.oga" = "38;5;111";
            "*.opus" = "38;5;111";
            "*.spx" = "38;5;111";
            "*.xspf" = "38;5;111";

            # Documents - using categorical color (75 -> 38;5;75)
            "*.pdf" = "38;5;75";
            "*.doc" = "38;5;75";
            "*.docx" = "38;5;75";
            "*.odt" = "38;5;75";
            "*.txt" = "38;5;75";
            "*.md" = "38;5;75";
            "*.tex" = "38;5;75";

            # Code files - using secondary accent color (111 -> 38;5;111)
            "*.c" = "38;5;111";
            "*.cpp" = "38;5;111";
            "*.h" = "38;5;111";
            "*.hpp" = "38;5;111";
            "*.py" = "38;5;111";
            "*.js" = "38;5;111";
            "*.ts" = "38;5;111";
            "*.rs" = "38;5;111";
            "*.go" = "38;5;111";
            "*.java" = "38;5;111";
            "*.sh" = "38;5;111";
            "*.nix" = "38;5;111";
          }
        else
          {
            # Light mode colors (inverted for visibility on light background)
            "rs" = "0";
            "di" = "01;34";
            "ln" = "01;36";
            "mh" = "00";
            "pi" = "47;30";
            "so" = "01;35";
            "do" = "01;35";
            "bd" = "47;30;01";
            "cd" = "47;30;01";
            "or" = "47;31;01";
            "mi" = "00";
            "su" = "30;41";
            "sg" = "37;43";
            "ca" = "00";
            "tw" = "37;42";
            "ow" = "30;42";
            "st" = "30;44";
            "ex" = "01;32";

            # Archives
            "*.tar" = "38;5;130";
            "*.tgz" = "38;5;130";
            "*.arc" = "38;5;130";
            "*.arj" = "38;5;130";
            "*.taz" = "38;5;130";
            "*.lha" = "38;5;130";
            "*.lz4" = "38;5;130";
            "*.lzh" = "38;5;130";
            "*.lzma" = "38;5;130";
            "*.tlz" = "38;5;130";
            "*.txz" = "38;5;130";
            "*.tzo" = "38;5;130";
            "*.t7z" = "38;5;130";
            "*.zip" = "38;5;130";
            "*.z" = "38;5;130";
            "*.dz" = "38;5;130";
            "*.gz" = "38;5;130";
            "*.lrz" = "38;5;130";
            "*.lz" = "38;5;130";
            "*.lzo" = "38;5;130";
            "*.xz" = "38;5;130";
            "*.zst" = "38;5;130";
            "*.tzst" = "38;5;130";
            "*.bz2" = "38;5;130";
            "*.bz" = "38;5;130";
            "*.tbz" = "38;5;130";
            "*.tbz2" = "38;5;130";
            "*.tz" = "38;5;130";
            "*.deb" = "38;5;130";
            "*.rpm" = "38;5;130";
            "*.jar" = "38;5;130";
            "*.war" = "38;5;130";
            "*.ear" = "38;5;130";
            "*.sar" = "38;5;130";
            "*.rar" = "38;5;130";
            "*.alz" = "38;5;130";
            "*.ace" = "38;5;130";
            "*.zoo" = "38;5;130";
            "*.cpio" = "38;5;130";
            "*.7z" = "38;5;130";
            "*.rz" = "38;5;130";
            "*.cab" = "38;5;130";
            "*.wim" = "38;5;130";
            "*.swm" = "38;5;130";
            "*.dwm" = "38;5;130";
            "*.esd" = "38;5;130";

            # Images
            "*.jpg" = "38;5;55";
            "*.jpeg" = "38;5;55";
            "*.mjpg" = "38;5;55";
            "*.mjpeg" = "38;5;55";
            "*.gif" = "38;5;55";
            "*.bmp" = "38;5;55";
            "*.pbm" = "38;5;55";
            "*.pgm" = "38;5;55";
            "*.ppm" = "38;5;55";
            "*.tga" = "38;5;55";
            "*.xbm" = "38;5;55";
            "*.xpm" = "38;5;55";
            "*.tif" = "38;5;55";
            "*.tiff" = "38;5;55";
            "*.png" = "38;5;55";
            "*.svg" = "38;5;55";
            "*.svgz" = "38;5;55";
            "*.mng" = "38;5;55";
            "*.pcx" = "38;5;55";
            "*.webp" = "38;5;55";
            "*.avif" = "38;5;55";

            # Videos
            "*.mov" = "38;5;28";
            "*.mpg" = "38;5;28";
            "*.mpeg" = "38;5;28";
            "*.m2v" = "38;5;28";
            "*.mkv" = "38;5;28";
            "*.webm" = "38;5;28";
            "*.ogm" = "38;5;28";
            "*.mp4" = "38;5;28";
            "*.m4v" = "38;5;28";
            "*.mp4v" = "38;5;28";
            "*.vob" = "38;5;28";
            "*.qt" = "38;5;28";
            "*.nuv" = "38;5;28";
            "*.wmv" = "38;5;28";
            "*.asf" = "38;5;28";
            "*.rm" = "38;5;28";
            "*.rmvb" = "38;5;28";
            "*.flc" = "38;5;28";
            "*.avi" = "38;5;28";
            "*.fli" = "38;5;28";
            "*.flv" = "38;5;28";
            "*.gl" = "38;5;28";
            "*.dl" = "38;5;28";
            "*.xcf" = "38;5;28";
            "*.xwd" = "38;5;28";
            "*.yuv" = "38;5;28";
            "*.cgm" = "38;5;28";
            "*.emf" = "38;5;28";

            # Audio
            "*.aac" = "38;5;25";
            "*.au" = "38;5;25";
            "*.flac" = "38;5;25";
            "*.m4a" = "38;5;25";
            "*.mid" = "38;5;25";
            "*.midi" = "38;5;25";
            "*.mka" = "38;5;25";
            "*.mp3" = "38;5;25";
            "*.mpc" = "38;5;25";
            "*.ogg" = "38;5;25";
            "*.ra" = "38;5;25";
            "*.wav" = "38;5;25";
            "*.oga" = "38;5;25";
            "*.opus" = "38;5;25";
            "*.spx" = "38;5;25";
            "*.xspf" = "38;5;25";

            # Documents
            "*.pdf" = "38;5;25";
            "*.doc" = "38;5;25";
            "*.docx" = "38;5;25";
            "*.odt" = "38;5;25";
            "*.txt" = "38;5;25";
            "*.md" = "38;5;25";
            "*.tex" = "38;5;25";

            # Code files
            "*.c" = "38;5;25";
            "*.cpp" = "38;5;25";
            "*.h" = "38;5;25";
            "*.hpp" = "38;5;25";
            "*.py" = "38;5;25";
            "*.js" = "38;5;25";
            "*.ts" = "38;5;25";
            "*.rs" = "38;5;25";
            "*.go" = "38;5;25";
            "*.java" = "38;5;25";
            "*.sh" = "38;5;25";
            "*.nix" = "38;5;25";
          };

      # Build the color string
      colorPairs = lib.attrsets.mapAttrsToList (k: v: "${k}=${v}") colors;
    in
    concatStringsSep ":" colorPairs;

  # Check if LS_COLORS should be set
  # Most tools use LS_COLORS, so we enable it when autoEnable is on or explicitly enabled
  shouldTheme = cfg.cli.ls-colors.enable or false || cfg.autoEnable;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    # Set LS_COLORS for all tools that respect it
    home.sessionVariables = {
      LS_COLORS = lsColors;
    };
  };
}
