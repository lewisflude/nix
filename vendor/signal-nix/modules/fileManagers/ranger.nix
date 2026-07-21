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
# HOME-MANAGER MODULE: programs.ranger.settings + rifle.conf
# UPSTREAM SCHEMA: https://github.com/ranger/ranger
# SCHEMA VERSION: 1.9.3
# LAST VALIDATED: 2026-01-17
# NOTES: Ranger uses Python-based rc.conf for settings. Home-Manager provides
#        settings attrset and rifle configuration. We set color scheme.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Use semantic bridge for color resolution
  # Ranger uses terminal ANSI colors that are themed by Signal

  # Check if ranger should be themed
  shouldTheme = signalLib.shouldThemeApp "ranger" [
    "fileManagers"
    "ranger"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.ranger = {
      settings = {
        # Use custom colorscheme
        colorscheme = "signal";
      };

      # Create custom colorscheme file
      extraConfig = ''
        # Signal colorscheme for ranger
        # This is a Python module that ranger will load

        from ranger.gui.colorscheme import ColorScheme
        from ranger.gui.color import *

        class Signal(ColorScheme):
            progress_bar_color = blue

            def use(self, context):
                fg, bg, attr = default_colors

                if context.reset:
                    return default_colors

                elif context.in_browser:
                    if context.selected:
                        attr = reverse
                        fg = blue
                    if context.empty or context.error:
                        fg = red
                    if context.border:
                        fg = default
                    if context.media:
                        if context.image:
                            fg = yellow
                        else:
                            fg = magenta
                    if context.container:
                        fg = magenta
                    if context.directory:
                        fg = blue
                    elif context.executable and not \
                            any((context.media, context.container,
                                 context.fifo, context.socket)):
                        fg = green
                    if context.socket:
                        fg = magenta
                    if context.fifo or context.device:
                        fg = yellow
                    if context.link:
                        fg = cyan if context.good else magenta
                    if context.tag_marker and not context.selected:
                        attr |= bold
                        if fg in (red, magenta):
                            fg = white
                        else:
                            fg = red
                    if not context.selected and (context.cut or context.copied):
                        fg = black
                        attr |= bold
                    if context.main_column:
                        if context.selected:
                            attr |= bold
                        if context.marked:
                            attr |= bold
                            fg = yellow
                    if context.badinfo:
                        if attr & reverse:
                            bg = magenta
                        else:
                            fg = magenta

                elif context.in_titlebar:
                    attr |= bold
                    if context.hostname:
                        fg = cyan
                    elif context.directory:
                        fg = blue
                    elif context.tab:
                        if context.good:
                            fg = green
                    elif context.link:
                        fg = cyan

                elif context.in_statusbar:
                    if context.permissions:
                        if context.good:
                            fg = cyan
                        elif context.bad:
                            fg = magenta
                    if context.marked:
                        attr |= bold | reverse
                        fg = yellow
                    if context.message:
                        if context.bad:
                            attr |= bold
                            fg = red
                    if context.loaded:
                        bg = default
                    if context.vcsinfo:
                        fg = blue
                        attr &= ~bold
                    if context.vcscommit:
                        fg = yellow
                        attr &= ~bold

                if context.text:
                    if context.highlight:
                        attr |= reverse

                if context.in_taskview:
                    if context.title:
                        fg = blue

                    if context.selected:
                        attr |= reverse

                    if context.loaded:
                        if context.selected:
                            fg = cyan
                        else:
                            fg = green

                return fg, bg, attr
      '';
    };
  };
}
