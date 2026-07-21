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
# UPSTREAM SCHEMA: https://github.com/jarun/nnn
# SCHEMA VERSION: 4.9
# LAST VALIDATED: 2026-01-17
# NOTES: nnn uses NNN_FCOLORS environment variable for colors.
#        Format is a string of context:color pairs using ANSI codes.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Use semantic bridge for color resolution
  # nnn uses ANSI color codes (30-37 for foreground, 40-47 for background)
  # We map Signal semantic colors to ANSI codes
  colors = {
    # ANSI codes that will be themed by the terminal
    # 31=red, 32=green, 33=yellow, 34=blue, 35=magenta, 36=cyan, 37=white
    directory = "34"; # blue for directories
    executable = "32"; # green for executables
    link = "36"; # cyan for symlinks
    orphan = "31"; # red for broken links
    fifo = "35"; # magenta for pipes
    socket = "35"; # magenta for sockets
    block = "33"; # yellow for block devices
    char = "33"; # yellow for char devices
    regular = "37"; # white for regular files
    hardlink = "36"; # cyan for hardlinks
    missing = "31"; # red for missing files
  };

  # Check if nnn should be themed
  shouldTheme = cfg.fileManagers.nnn.enable or false || cfg.autoEnable;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    home.sessionVariables = {
      # NNN_FCOLORS format: c1c2c3c4:c1c2c3c4 (11 context colors)
      # Context order: directory, regular, executable, symlink, missing, orphan,
      #                fifo, socket, special, hardlink, unknown
      NNN_FCOLORS = "${colors.directory}${colors.regular}${colors.executable}${colors.link}${colors.missing}${colors.orphan}${colors.fifo}${colors.socket}${colors.block}${colors.hardlink}${colors.regular}";

      # Enable colors
      NNN_OPTS = "H"; # Show hidden files with color
    };
  };
}
