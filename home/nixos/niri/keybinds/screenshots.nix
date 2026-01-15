# Screenshot Keybindings
# Screenshot capture and clipboard operations
{
  pkgs,
  lib,
  ...
}:
{
  "Print" = {
    allow-inhibiting = false;
    action.spawn = [
      "sh"
      "-c"
      ''
        FILE="$HOME/Pictures/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png"
        grim -t png "$FILE" && wl-copy < "$FILE" && notify-send "Screenshot" "Saved and copied to clipboard" -i "$FILE"
      ''
    ];
  };

  "Mod+Shift+Print" = {
    allow-inhibiting = false;
    action.spawn = [
      "sh"
      "-c"
      ''
        GEOM=$(slurp) && if [ -n "$GEOM" ]; then
          FILE="$HOME/Pictures/Screenshots/satty-$(date +%Y%m%d-%H%M%S).png"
          grim -g "$GEOM" -t ppm - | satty --filename - --fullscreen --output-filename "$FILE"
          notify-send "Screenshot" "Area saved" -i "$FILE"
        fi
      ''
    ];
  };

  "Shift+Print" = {
    allow-inhibiting = false;
    action.spawn = [
      "sh"
      "-c"
      ''
        GEOM=$(slurp) && if [ -n "$GEOM" ]; then
          FILE="$HOME/Pictures/Screenshots/satty-$(date +%Y%m%d-%H%M%S).png"
          grim -g "$GEOM" -t ppm - | satty --filename - --fullscreen --output-filename "$FILE"
          notify-send "Screenshot" "Area saved" -i "$FILE"
        fi
      ''
    ];
  };

  "Ctrl+Print" = {
    allow-inhibiting = false;
    action.spawn = [
      "sh"
      "-c"
      ''
        FILE="$HOME/Pictures/Screenshots/satty-$(date +%Y%m%d-%H%M%S).png"
        grim -t ppm - | satty --filename - --fullscreen --output-filename "$FILE"
        notify-send "Screenshot" "Screen saved" -i "$FILE"
      ''
    ];
  };

  "Alt+Print" = {
    allow-inhibiting = false;
    action.spawn = [
      "sh"
      "-c"
      ''
        GEOM=$(slurp) && if [ -n "$GEOM" ]; then
          grim -g "$GEOM" -t png | wl-copy && notify-send "Screenshot" "Area copied to clipboard"
        fi
      ''
    ];
  };

  "Mod+Ctrl+Shift+Print" = {
    allow-inhibiting = false;
    action.spawn = [
      "sh"
      "-c"
      ''
        GEOM=$(slurp) && if [ -n "$GEOM" ]; then
          FILE="$HOME/Pictures/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png"
          grim -g "$GEOM" -t png "$FILE" && wl-copy < "$FILE" && notify-send "Screenshot" "Area saved and copied to clipboard" -i "$FILE"
        fi
      ''
    ];
  };

  # Standard region screenshot (Windows/macOS muscle memory)
  "Mod+Shift+S" = {
    allow-inhibiting = false;
    action.spawn = [
      "sh"
      "-c"
      ''
        FILE="$HOME/Pictures/Screenshots/region-$(date +%Y%m%d-%H%M%S).png"
        grim -g "$(slurp)" - | tee "$FILE" | wl-copy && \
        notify-send "Region Captured" "Saved to $FILE and Clipboard" -i "$FILE"
      ''
    ];
  };

  "Mod+Shift+C" = {
    action.spawn = [
      (lib.getExe pkgs.hyprpicker)
      "-a"
    ];
  };
}
