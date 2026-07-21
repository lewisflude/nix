{
  lib,
  stdenv,
  signalLib,
  mode ? "dark",
}:

let
  inherit (lib) removePrefix;

  # Resolve theme mode
  themeMode = signalLib.resolveThemeMode mode;
  colors = signalLib.getColors themeMode;

  # Helper to remove # from hex colors
  hexRaw = color: removePrefix "#" color.hex;

  # Extract colors for GRUB theme
  background = colors.tonal."surface-base";
  surface = colors.tonal."surface-hover";
  text-primary = colors.tonal."text-primary";
  text-secondary = colors.tonal."text-secondary";
  accent = colors.accent.secondary.Lc75;
  divider = colors.tonal."divider-primary";

  # Theme configuration as text
  themeConf = ''
    # Signal Design System - GRUB2 Theme
    # Mode: ${themeMode}
    # Generated from signal-palette

    # Global properties
    title-text: ""
    desktop-image: "background.png"
    desktop-color: "#${hexRaw background}"
    terminal-box: "terminal_box_*.png"
    terminal-left: "0"
    terminal-top: "0"
    terminal-width: "100%"
    terminal-height: "100%"
    terminal-border: "0"

    # Boot menu
    + boot_menu {
      left = 15%
      top = 20%
      width = 70%
      height = 60%
      item_color = "#${hexRaw text-primary}"
      selected_item_color = "#${hexRaw accent}"
      item_font = "DejaVu Sans Regular 16"
      item_height = 32
      item_padding = 8
      item_spacing = 4
      item_icon_space = 4
      icon_width = 24
      icon_height = 24
      scrollbar = true
      scrollbar_width = 12
      scrollbar_thumb = "scrollbar_thumb_*.png"
    }

    # Progress bar
    + progress_bar {
      id = "__timeout__"
      left = 15%
      top = 82%
      width = 70%
      height = 24
      font = "DejaVu Sans Regular 12"
      text_color = "#${hexRaw text-secondary}"
      fg_color = "#${hexRaw accent}"
      bg_color = "#${hexRaw surface}"
      border_color = "#${hexRaw divider}"
      text = "@TIMEOUT_NOTIFICATION_SHORT@"
    }

    # Title text (optional)
    + label {
      top = 10%
      left = 0
      width = 100%
      height = 40
      align = "center"
      color = "#${hexRaw text-primary}"
      font = "DejaVu Sans Bold 20"
      text = "Signal"
    }
  '';

  # Create a solid color background image (1x1 pixel, scaled)
  # This is more efficient than a full image
  backgroundImg = stdenv.mkDerivation {
    name = "signal-grub-background";
    buildInputs = [ ];
    unpackPhase = "true";
    installPhase = ''
      mkdir -p $out
      # Create 1x1 PNG with background color
      # In production, use imagemagick or similar
      # For now, create a minimal PNG
      echo "Background image placeholder" > $out/background.png
    '';
  };
in
stdenv.mkDerivation {
  name = "signal-grub-theme-${themeMode}";
  version = "1.0.0";

  src = ./.;

  buildInputs = [ ];

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out

    # Install theme.txt
    cat > $out/theme.txt << 'EOF'
    ${themeConf}
    EOF

    # Create minimal background
    # TODO: Generate proper PNG with Signal colors
    echo "PNG placeholder" > $out/background.png

    # Create terminal box images (simple borders)
    # For now, create placeholders
    touch $out/terminal_box_n.png
    touch $out/terminal_box_nw.png
    touch $out/terminal_box_ne.png
    touch $out/terminal_box_w.png
    touch $out/terminal_box_e.png
    touch $out/terminal_box_s.png
    touch $out/terminal_box_sw.png
    touch $out/terminal_box_se.png

    # Create scrollbar images
    touch $out/scrollbar_thumb_c.png
  '';

  meta = {
    description = "Signal Design System theme for GRUB2 (${themeMode} mode)";
    license = lib.licenses.mit;
  };
}
