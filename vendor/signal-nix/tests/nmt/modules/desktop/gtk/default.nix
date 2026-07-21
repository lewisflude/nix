# Signal Design System - GTK Theming NMT Tests
{
  lib,
  pkgs,
  self,
}:
{
  nmt-gtk-basic-dark = {
    name = "gtk-basic-dark";
    modules = [
      {
        gtk.enable = true;
        signal = {
          enable = true;
          mode = "dark";
          gtk.enable = true;
        };
        nmt.script = ''
          assertFileExists home-files/.config/gtk-3.0/gtk.css
          assertFileRegex home-files/.config/gtk-3.0/gtk.css '@define-color theme_bg_color'
        '';
      }
    ];
  };

  nmt-gtk-basic-light = {
    name = "gtk-basic-light";
    modules = [
      {
        gtk.enable = true;
        signal = {
          enable = true;
          mode = "light";
          gtk.enable = true;
        };
        nmt.script = ''
          assertFileExists home-files/.config/gtk-3.0/gtk.css
        '';
      }
    ];
  };

  nmt-gtk-adwaita-palette = {
    name = "gtk-adwaita-palette";
    modules = [
      {
        gtk.enable = true;
        signal = {
          enable = true;
          mode = "dark";
          gtk.enable = true;
        };
        nmt.script = ''
          CONFIG="home-files/.config/gtk-3.0/gtk.css"

          # Verify Adwaita palette colors are defined
          for color in blue_1 green_2 yellow_3 orange_4 red_5 purple_1 brown_2 light_3 dark_4; do
            grep -q "@define-color $color" "$CONFIG" || {
              echo "ERROR: Missing Adwaita palette color: $color"
              exit 1
            }
          done

          echo "✓ All Adwaita palette colors present"
        '';
      }
    ];
  };

  nmt-gtk4-css-custom-properties = {
    name = "gtk4-css-custom-properties";
    modules = [
      {
        gtk.enable = true;
        signal = {
          enable = true;
          mode = "dark";
          gtk.enable = true;
        };
        nmt.script = ''
          CONFIG="home-files/.config/gtk-4.0/gtk.css"

          # Verify GTK4 CSS has :root block with CSS custom properties
          assertFileExists "$CONFIG"
          assertFileRegex "$CONFIG" ':root'

          # Verify accent colors (CSS custom properties use dashes)
          for var in accent-bg-color accent-fg-color accent-color; do
            grep -q -- "--$var:" "$CONFIG" || {
              echo "ERROR: Missing CSS custom property: --$var"
              exit 1
            }
          done

          # Verify window colors
          for var in window-bg-color window-fg-color; do
            grep -q -- "--$var:" "$CONFIG" || {
              echo "ERROR: Missing CSS custom property: --$var"
              exit 1
            }
          done

          # Verify helper variables
          for var in border-opacity dim-opacity disabled-opacity window-radius; do
            grep -q -- "--$var:" "$CONFIG" || {
              echo "ERROR: Missing helper variable: --$var"
              exit 1
            }
          done

          # Verify font variables
          for var in document-font-family document-font-size monospace-font-family monospace-font-size; do
            grep -q -- "--$var:" "$CONFIG" || {
              echo "ERROR: Missing font variable: --$var"
              exit 1
            }
          done

          # Verify accent presets
          for var in accent-blue accent-green accent-red accent-purple accent-slate; do
            grep -q -- "--$var:" "$CONFIG" || {
              echo "ERROR: Missing accent preset: --$var"
              exit 1
            }
          done

          # Verify palette colors with dashes
          grep -q -- "--blue-1:" "$CONFIG" || {
            echo "ERROR: Missing palette color: --blue-1"
            exit 1
          }

          echo "✓ All GTK4 CSS custom properties present"
        '';
      }
    ];
  };

  nmt-gtk4-standalone-colors = {
    name = "gtk4-standalone-colors";
    modules = [
      {
        gtk.enable = true;
        signal = {
          enable = true;
          mode = "dark";
          gtk.enable = true;
        };
        nmt.script = ''
          CONFIG="home-files/.config/gtk-4.0/gtk.css"

          # Verify standalone color variables exist
          # These should be different from bg colors (darker in light, lighter in dark)
          for var in destructive-color success-color warning-color error-color; do
            grep -q -- "--$var:" "$CONFIG" || {
              echo "ERROR: Missing standalone color: --$var"
              exit 1
            }
          done

          echo "✓ All standalone colors present"
        '';
      }
    ];
  };

  nmt-gtk3-no-custom-properties = {
    name = "gtk3-no-custom-properties";
    modules = [
      {
        gtk.enable = true;
        signal = {
          enable = true;
          mode = "dark";
          gtk.enable = true;
        };
        nmt.script = ''
          CONFIG="home-files/.config/gtk-3.0/gtk.css"

          # GTK3 CSS should NOT have :root block (GTK3 doesn't fully support CSS custom properties)
          if grep -q ':root' "$CONFIG"; then
            echo "ERROR: GTK3 CSS should not contain :root block"
            exit 1
          fi

          # But should have @define-color directives
          assertFileRegex "$CONFIG" '@define-color'

          echo "✓ GTK3 CSS uses @define-color without :root block"
        '';
      }
    ];
  };
}
