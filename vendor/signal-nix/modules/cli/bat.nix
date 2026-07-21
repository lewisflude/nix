# Signal Bat Theme Module
#
# This module ONLY applies Signal colors to bat.
# It assumes you have already enabled bat with:
#   programs.bat.enable = true;
#
# The module will not install bat or configure its functional behavior.
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
# CONFIGURATION METHOD: native-theme (Tier 1)
# HOME-MANAGER MODULE: programs.bat.themes
# UPSTREAM SCHEMA: https://github.com/sharkdp/bat#adding-new-themes
# SCHEMA VERSION: 0.24.0
# LAST VALIDATED: 2026-01-17
# NOTES: Uses Sublime Text tmTheme format. Home-Manager handles theme installation
#        and selection natively. This is the optimal integration method.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;

  # Generate tmTheme XML for bat using Signal colors
  # This creates a Sublime Text theme file that bat can use
  generateTmTheme =
    mode:
    let
      # Use semantic bridge for all color definitions
      colors = {
        # Base editor colors
        background = (semantic.core "background" mode).hex;
        foreground = (semantic.core "foreground" mode).hex;
        caret = (semantic.core "cursor" mode).hex;
        lineHighlight = (semantic.ui "element-hover" mode).hex;
        selection = (semantic.core "selection-bg" mode).hex;

        # Syntax highlighting colors
        comment = (semantic.syntax "comment" mode).hex;
        string = (semantic.syntax "string" mode).hex;
        number = (semantic.syntax "number" mode).hex;
        keyword = (semantic.syntax "keyword" mode).hex;
        operator = (semantic.syntax "operator" mode).hex;
        function = (semantic.syntax "function" mode).hex;
        type = (semantic.syntax "type" mode).hex;
        variable = (semantic.syntax "variable" mode).hex;
        constant = (semantic.syntax "constant" mode).hex;
        escape = (semantic.syntax "escape" mode).hex;
        punctuation = (semantic.syntax "punctuation" mode).hex;

        # Markup elements
        heading = (semantic.markup "heading" mode).hex;
        link = (semantic.markup "link" mode).hex;

        # Diff colors
        diffInserted = (semantic.vcs "added" mode).hex;
        diffDeleted = (semantic.vcs "deleted" mode).hex;
        diffChanged = (semantic.vcs "modified" mode).hex;
      };
    in
    pkgs.writeText "signal-${mode}.tmTheme" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>name</key>
        <string>Signal ${
          lib.toUpper (builtins.substring 0 1 mode)
        }${builtins.substring 1 (-1) mode}</string>
        <key>settings</key>
        <array>
          <dict>
            <key>settings</key>
            <dict>
              <key>background</key>
              <string>${colors.background}</string>
              <key>foreground</key>
              <string>${colors.foreground}</string>
              <key>caret</key>
              <string>${colors.caret}</string>
              <key>lineHighlight</key>
              <string>${colors.lineHighlight}</string>
              <key>selection</key>
              <string>${colors.selection}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Comment</string>
            <key>scope</key>
            <string>comment</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>${colors.comment}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>String</string>
            <key>scope</key>
            <string>string</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>${colors.string}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Number</string>
            <key>scope</key>
            <string>constant.numeric</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>${colors.number}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Keyword</string>
            <key>scope</key>
            <string>keyword, storage</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>${colors.keyword}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Operator</string>
            <key>scope</key>
            <string>keyword.operator</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>${colors.operator}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Function</string>
            <key>scope</key>
            <string>entity.name.function, meta.function-call</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>${colors.function}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Type</string>
            <key>scope</key>
            <string>entity.name.type, entity.name.class, support.type, support.class</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>${colors.type}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Variable</string>
            <key>scope</key>
            <string>variable</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>${colors.variable}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Constant</string>
            <key>scope</key>
            <string>constant</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>${colors.constant}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Tag</string>
            <key>scope</key>
            <string>entity.name.tag</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>${colors.function}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Attribute</string>
            <key>scope</key>
            <string>entity.other.attribute-name</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>${colors.type}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Punctuation</string>
            <key>scope</key>
            <string>punctuation</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>${colors.punctuation}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Escape</string>
            <key>scope</key>
            <string>constant.character.escape, string.regexp</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>${colors.escape}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Markup Heading</string>
            <key>scope</key>
            <string>markup.heading</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>${colors.heading}</string>
              <key>fontStyle</key>
              <string>bold</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Markup Bold</string>
            <key>scope</key>
            <string>markup.bold</string>
            <key>settings</key>
            <dict>
              <key>fontStyle</key>
              <string>bold</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Markup Italic</string>
            <key>scope</key>
            <string>markup.italic</string>
            <key>settings</key>
            <dict>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Markup Link</string>
            <key>scope</key>
            <string>markup.underline.link</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>${colors.link}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Diff Inserted</string>
            <key>scope</key>
            <string>markup.inserted, diff.inserted</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>${colors.diffInserted}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Diff Deleted</string>
            <key>scope</key>
            <string>markup.deleted, diff.deleted</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>${colors.diffDeleted}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Diff Changed</string>
            <key>scope</key>
            <string>markup.changed, diff.changed</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>${colors.diffChanged}</string>
            </dict>
          </dict>
        </array>
      </dict>
      </plist>
    '';

  # Generate both dark and light themes
  darkThemeFile = generateTmTheme "dark";
  lightThemeFile = generateTmTheme "light";

  # Package both theme files in a directory structure bat expects
  themePackage = pkgs.runCommand "bat-signal-themes" { } ''
    mkdir -p $out
    cp ${darkThemeFile} "$out/signal-dark.tmTheme"
    cp ${lightThemeFile} "$out/signal-light.tmTheme"
  '';

  # Resolved mode for static theme selection
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Check if bat should be themed - using centralized helper
  shouldTheme = signalLib.shouldThemeApp "bat" [
    "cli"
    "bat"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.bat = {
      themes = {
        signal-dark = {
          src = themePackage;
          file = "signal-dark.tmTheme";
        };
        signal-light = {
          src = themePackage;
          file = "signal-light.tmTheme";
        };
      };

      config = {
        # Use bat's auto-detection if mode is "auto", otherwise use resolved mode
        theme = if cfg.mode == "auto" then "auto" else "signal-${themeMode}";
        theme-dark = "signal-dark";
        theme-light = "signal-light";
        # Note: Signal only sets colors. Configure bat's behavior (italic-text,
        # style, pager, etc.) in your own programs.bat.config if desired.
      };
    };
  };
}
