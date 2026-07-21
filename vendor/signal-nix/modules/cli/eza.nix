# Signal Eza Theme Module
#
# This module ONLY applies Signal colors to eza via EZA_COLORS.
# It assumes you have already enabled eza with:
#   programs.eza.enable = true;
#
# The module will not install eza or configure its functional behavior.
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
# CONFIGURATION METHOD: raw-config (Tier 4)
# HOME-MANAGER MODULE: home.sessionVariables.EZA_COLORS
# UPSTREAM SCHEMA: https://the.exa.website/docs/colour-themes
# SCHEMA VERSION: 0.18.0
# LAST VALIDATED: 2026-01-17
# NOTES: Eza only supports color theming via EZA_COLORS environment variable.
#        No structured Home-Manager options exist. Must build colon-separated string
#        of key=value pairs matching LS_COLORS format.
let
  inherit (lib) mkIf concatStringsSep;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Build EZA_COLORS string from Signal colors
  # Note: eza uses ANSI color codes, not hex colors
  # We use a simplified mapping of Signal color concepts to ANSI codes
  ezaColors =
    let
      colors =
        if signalLib.resolveThemeMode cfg.mode == "dark" then
          {
            # File types
            di = "1;34"; # directories - bold blue
            ex = "1;32"; # executables - bold green
            fi = "0"; # regular files
            ln = "1;36"; # symlinks - bold cyan
            or = "31;40"; # orphaned symlinks - red on dark

            # Permissions
            ur = "38;5;${toString 75}"; # user read - from text-Lc75
            uw = "38;5;${toString 203}"; # user write - danger color
            ux = "38;5;${toString 120}"; # user execute - success color
            gr = "38;5;${toString 60}"; # group read - text-Lc60
            gw = "38;5;${toString 203}"; # group write
            gx = "38;5;${toString 120}"; # group execute
            tr = "38;5;${toString 45}"; # other read - text-Lc45
            tw = "38;5;${toString 203}"; # other write
            tx = "38;5;${toString 120}"; # other execute

            # User/Group
            uu = "1;33"; # current user - bold yellow (focus)
            un = "33"; # other users
            gu = "1;36"; # current group - bold cyan
            gn = "36"; # other groups

            # File size - using categorical colors
            sn = "38;5;${toString 75}"; # size numbers
            sb = "38;5;${toString 60}"; # size units

            # Dates
            da = "38;5;${toString 111}"; # dates - info color

            # Git status - using accent colors
            ga = "38;5;${toString 120}"; # new/added - success green
            gm = "38;5;${toString 111}"; # modified - info blue
            gd = "38;5;${toString 203}"; # deleted - danger red
            gv = "38;5;${toString 141}"; # renamed - special purple
            gt = "38;5;${toString 180}"; # type changed - warning
            gi = "2;38;5;${toString 60}"; # ignored - dim text-Lc60
            gc = "1;38;5;${toString 203}"; # conflicted - bold danger

            # Git repo
            Gm = "1;38;5;${toString 111}"; # main branch - bold info
            Go = "38;5;${toString 141}"; # other branch - special
            Gc = "38;5;${toString 120}"; # clean - success
            Gd = "38;5;${toString 203}"; # dirty - danger

            # Special files
            mp = "1;35"; # mount point - bold magenta
            sp = "38;5;${toString 180}"; # special files - warning

            # File types with categorical colors
            im = "38;5;${toString 141}"; # images - GA01
            vi = "38;5;${toString 120}"; # videos - GA02
            mu = "38;5;${toString 111}"; # music - GA03
            lo = "38;5;${toString 203}"; # lossless - GA04
            cr = "38;5;${toString 180}"; # crypto - GA05
            do = "38;5;${toString 75}"; # documents - GA06
            co = "38;5;${toString 139}"; # compressed - GA07
            tm = "2;38;5;${toString 60}"; # temp - dim
            bu = "38;5;${toString 120}"; # build files - success

            # UI elements
            xx = "38;5;${toString 45}"; # punctuation - text-Lc45
            hd = "1;38;5;${toString 75}"; # header - bold text-Lc75
            lp = "36"; # symlink path - cyan
            cc = "38;5;${toString 180}"; # escaped chars - warning
          }
        else
          {
            # Light mode colors (inverted for visibility)
            di = "1;34"; # directories
            ex = "1;32"; # executables
            fi = "0"; # regular files
            ln = "1;36"; # symlinks
            or = "31;47"; # orphaned symlinks - red on light

            # Permissions
            ur = "38;5;${toString 25}";
            uw = "38;5;${toString 160}";
            ux = "38;5;${toString 28}";
            gr = "38;5;${toString 60}";
            gw = "38;5;${toString 160}";
            gx = "38;5;${toString 28}";
            tr = "38;5;${toString 240}";
            tw = "38;5;${toString 160}";
            tx = "38;5;${toString 28}";

            # User/Group
            uu = "1;33";
            un = "33";
            gu = "1;36";
            gn = "36";

            # File size
            sn = "38;5;${toString 25}";
            sb = "38;5;${toString 60}";

            # Dates
            da = "38;5;${toString 25}";

            # Git status
            ga = "38;5;${toString 28}";
            gm = "38;5;${toString 25}";
            gd = "38;5;${toString 160}";
            gv = "38;5;${toString 55}";
            gt = "38;5;${toString 130}";
            gi = "2;38;5;${toString 240}";
            gc = "1;38;5;${toString 160}";

            # Git repo
            Gm = "1;38;5;${toString 25}";
            Go = "38;5;${toString 55}";
            Gc = "38;5;${toString 28}";
            Gd = "38;5;${toString 160}";

            # Special files
            mp = "1;35";
            sp = "38;5;${toString 130}";

            # File types
            im = "38;5;${toString 55}";
            vi = "38;5;${toString 28}";
            mu = "38;5;${toString 25}";
            lo = "38;5;${toString 160}";
            cr = "38;5;${toString 130}";
            do = "38;5;${toString 25}";
            co = "38;5;${toString 92}";
            tm = "2;38;5;${toString 240}";
            bu = "38;5;${toString 28}";

            # UI elements
            xx = "38;5;${toString 240}";
            hd = "1;38;5;${toString 25}";
            lp = "36";
            cc = "38;5;${toString 130}";
          };

      # Build the color string
      colorPairs = lib.attrsets.mapAttrsToList (k: v: "${k}=${v}") colors;
    in
    concatStringsSep ":" colorPairs;

  # Check if eza should be themed
  # Check if eza should be themed - using centralized helper
  shouldTheme = signalLib.shouldThemeApp "eza" [
    "cli"
    "eza"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    # Assumes user has already set programs.eza.enable = true
    # Only set the color theme via environment variable
    home.sessionVariables = {
      EZA_COLORS = ezaColors;
    };
  };
}
