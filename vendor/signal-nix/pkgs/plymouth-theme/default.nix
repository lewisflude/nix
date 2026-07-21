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

  # Convert hex to RGB values (0-1 range for Plymouth)
  hexToRgbFloat =
    color:
    let
      hex = hexRaw color;
      # Extract R, G, B components
      r = builtins.substring 0 2 hex;
      g = builtins.substring 2 2 hex;
      b = builtins.substring 4 2 hex;

      # Convert hex to decimal (0-255) then to float (0-1)
      # Use fromHex helper from lib
      hexToDec =
        hexStr:
        let
          hexDigits = {
            "0" = 0;
            "1" = 1;
            "2" = 2;
            "3" = 3;
            "4" = 4;
            "5" = 5;
            "6" = 6;
            "7" = 7;
            "8" = 8;
            "9" = 9;
            "a" = 10;
            "b" = 11;
            "c" = 12;
            "d" = 13;
            "e" = 14;
            "f" = 15;
            "A" = 10;
            "B" = 11;
            "C" = 12;
            "D" = 13;
            "E" = 14;
            "F" = 15;
          };
          chars = lib.stringToCharacters (lib.toLower hexStr);
          values = map (c: hexDigits.${c}) chars;
        in
        lib.foldl (acc: val: acc * 16 + val) 0 values;

      toFloat = hexStr: (hexToDec hexStr) / 255.0;
    in
    {
      r = toFloat r;
      g = toFloat g;
      b = toFloat b;
    };

  # Format RGB float for Plymouth script (3 decimal places)
  formatRgb =
    rgb:
    "${builtins.toString (builtins.floor (rgb.r * 1000) / 1000)}, ${
      builtins.toString (builtins.floor (rgb.g * 1000) / 1000)
    }, ${builtins.toString (builtins.floor (rgb.b * 1000) / 1000)}";

  # Extract colors for Plymouth theme
  background = colors.tonal."surface-base";
  surface = colors.tonal."surface-hover";
  text-primary = colors.tonal."text-primary";
  text-secondary = colors.tonal."text-secondary";
  accent = colors.accent.secondary.Lc75;
  divider = colors.tonal."divider-primary";

  # Convert to RGB floats for Plymouth
  bgRgb = hexToRgbFloat background;
  accentRgb = hexToRgbFloat accent;
  textRgb = hexToRgbFloat text-primary;
  dividerRgb = hexToRgbFloat divider;

  # Plymouth theme descriptor
  plymouthFile = ''
    [Plymouth Theme]
    Name=Signal ${lib.strings.toUpper (lib.substring 0 1 themeMode)}${lib.substring 1 (-1) themeMode}
    Description=Signal Design System boot splash theme (${themeMode} mode)
    ModuleName=script

    [script]
    ImageDir=/usr/share/plymouth/themes/signal-${themeMode}
    ScriptFile=/usr/share/plymouth/themes/signal-${themeMode}/signal.script
  '';

  # Plymouth script with Signal colors
  plymouthScript = ''
    # Signal Design System Plymouth Theme
    # Mode: ${themeMode}
    # Generated from signal-palette

    # ============================================================================
    # Window and Background Setup
    # ============================================================================

    # Set background color (top and bottom for gradient support)
    Window.SetBackgroundTopColor(${formatRgb bgRgb});
    Window.SetBackgroundBottomColor(${formatRgb bgRgb});

    # Get screen dimensions
    screen_width = Window.GetWidth();
    screen_height = Window.GetHeight();

    # ============================================================================
    # Logo Display
    # ============================================================================

    # Create Signal logo text
    logo.image = Image.Text("Signal", ${formatRgb textRgb}, 1, "Sans Bold 48");
    logo.sprite = Sprite(logo.image);
    logo.sprite.SetX(screen_width / 2 - logo.image.GetWidth() / 2);
    logo.sprite.SetY(screen_height / 2 - 100);

    # ============================================================================
    # Progress Bar
    # ============================================================================

    # Progress bar dimensions and position
    progress_bar.width = 400;
    progress_bar.height = 8;
    progress_bar.x = screen_width / 2 - progress_bar.width / 2;
    progress_bar.y = screen_height / 2 + 50;

    # Progress bar background (divider color)
    progress_box.image = Image(progress_bar.width, progress_bar.height);
    for (x = 0; x < progress_bar.width; x++) {
      for (y = 0; y < progress_bar.height; y++) {
        progress_box.image.SetPixel(x, y, ${formatRgb dividerRgb});
      }
    }
    progress_box.sprite = Sprite(progress_box.image);
    progress_box.sprite.SetPosition(progress_bar.x, progress_bar.y, 0);

    # Progress bar fill (accent color)
    progress_bar.image = Image(1, progress_bar.height);
    for (y = 0; y < progress_bar.height; y++) {
      progress_bar.image.SetPixel(0, y, ${formatRgb accentRgb});
    }
    progress_bar.sprite = Sprite(progress_bar.image);
    progress_bar.sprite.SetPosition(progress_bar.x, progress_bar.y, 1);

    # ============================================================================
    # Spinner Animation (dots below progress bar)
    # ============================================================================

    spinner.frame = 0;
    spinner.num_dots = 3;
    spinner.dot_size = 4;
    spinner.spacing = 16;

    # Create spinner dots
    for (i = 0; i < spinner.num_dots; i++) {
      spinner.dots[i].image = Image(spinner.dot_size, spinner.dot_size);
      for (x = 0; x < spinner.dot_size; x++) {
        for (y = 0; y < spinner.dot_size; y++) {
          spinner.dots[i].image.SetPixel(x, y, ${formatRgb textRgb});
        }
      }
      spinner.dots[i].sprite = Sprite(spinner.dots[i].image);
      dot_x = screen_width / 2 - (spinner.num_dots * spinner.spacing) / 2 + i * spinner.spacing;
      spinner.dots[i].sprite.SetPosition(dot_x, progress_bar.y + 24, 1);
      spinner.dots[i].sprite.SetOpacity(0.3);
    }

    # ============================================================================
    # Status Message
    # ============================================================================

    status_text.image = Image.Text("", ${formatRgb textRgb}, 1, "Sans Regular 14");
    status_text.sprite = Sprite(status_text.image);
    status_text.sprite.SetPosition(screen_width / 2, progress_bar.y + 60, 2);

    # ============================================================================
    # Callback Functions
    # ============================================================================

    # Boot progress callback
    fun boot_progress_cb(duration, progress) {
      # Update progress bar width
      new_width = Math.Int(progress_bar.width * progress);
      progress_bar.sprite.SetImage(progress_bar.image.Scale(new_width, progress_bar.height));
    }

    Plymouth.SetBootProgressFunction(boot_progress_cb);

    # Refresh callback (for spinner animation)
    fun refresh_cb() {
      # Animate spinner dots
      spinner.frame++;
      if (spinner.frame > 30) spinner.frame = 0;
      
      for (i = 0; i < spinner.num_dots; i++) {
        # Calculate opacity based on frame
        phase = (spinner.frame + i * 10) % 30;
        if (phase < 15) {
          opacity = 0.3 + (phase / 15.0) * 0.7;
        } else {
          opacity = 1.0 - ((phase - 15) / 15.0) * 0.7;
        }
        spinner.dots[i].sprite.SetOpacity(opacity);
      }
    }

    Plymouth.SetRefreshFunction(refresh_cb);

    # Status update callback
    fun status_update_cb(status) {
      if (status == "normal") {
        status_text.image = Image.Text("Starting system...", ${formatRgb textRgb}, 1, "Sans Regular 14");
      } else if (status == "failed") {
        status_text.image = Image.Text("System startup failed", ${formatRgb accentRgb}, 1, "Sans Regular 14");
      }
      
      status_text.sprite.SetImage(status_text.image);
      status_text.sprite.SetX(screen_width / 2 - status_text.image.GetWidth() / 2);
    }

    Plymouth.SetUpdateStatusFunction(status_update_cb);

    # Display normal callback
    fun display_normal_callback() {
      global.status = "normal";
      status_update_cb("normal");
    }

    Plymouth.SetDisplayNormalFunction(display_normal_callback);

    # Display password callback
    fun display_password_callback(prompt, bullets) {
      # Show password prompt
      prompt_text.image = Image.Text(prompt, ${formatRgb textRgb}, 1, "Sans Regular 14");
      prompt_text.sprite = Sprite(prompt_text.image);
      prompt_text.sprite.SetX(screen_width / 2 - prompt_text.image.GetWidth() / 2);
      prompt_text.sprite.SetY(screen_height / 2 + 100);
      
      # Show password bullets
      bullet_text = "";
      for (i = 0; i < bullets; i++) {
        bullet_text += "•";
      }
      
      bullets_image = Image.Text(bullet_text, ${formatRgb textRgb}, 1, "Sans Regular 20");
      bullets_sprite = Sprite(bullets_image);
      bullets_sprite.SetX(screen_width / 2 - bullets_image.GetWidth() / 2);
      bullets_sprite.SetY(screen_height / 2 + 130);
    }

    Plymouth.SetDisplayPasswordFunction(display_password_callback);

    # Message callback
    fun message_callback(text) {
      message.image = Image.Text(text, ${formatRgb textRgb}, 1, "Sans Regular 12");
      message.sprite = Sprite(message.image);
      message.sprite.SetPosition(screen_width / 2 - message.image.GetWidth() / 2, screen_height - 50, 10000);
    }

    Plymouth.SetMessageFunction(message_callback);

    # Quit callback
    fun quit_callback() {
      # Fade out animation
      for (i = 0; i < 10; i++) {
        opacity = 1.0 - (i / 10.0);
        logo.sprite.SetOpacity(opacity);
        progress_box.sprite.SetOpacity(opacity);
        progress_bar.sprite.SetOpacity(opacity);
        status_text.sprite.SetOpacity(opacity);
        for (j = 0; j < spinner.num_dots; j++) {
          spinner.dots[j].sprite.SetOpacity(opacity * 0.3);
        }
        Plymouth.Sleep(0.016); # ~60fps
      }
    }

    Plymouth.SetQuitFunction(quit_callback);
  '';

in
stdenv.mkDerivation {
  name = "signal-plymouth-theme-${themeMode}";
  version = "1.0.0";

  src = ./.;

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/share/plymouth/themes/signal-${themeMode}

    # Install .plymouth descriptor
    cat > $out/share/plymouth/themes/signal-${themeMode}/signal-${themeMode}.plymouth << 'EOF'
    ${plymouthFile}
    EOF

    # Install .script file
    cat > $out/share/plymouth/themes/signal-${themeMode}/signal.script << 'EOF'
    ${plymouthScript}
    EOF

    # Create empty images directory (Plymouth script generates graphics programmatically)
    mkdir -p $out/share/plymouth/themes/signal-${themeMode}/images
  '';

  meta = {
    description = "Signal Design System boot splash theme for Plymouth (${themeMode} mode)";
    longDescription = ''
      A modern, minimal boot splash screen using Signal's scientifically-designed
      OKLCH colors. Features animated progress bar and spinner with Signal branding.
    '';
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
}
