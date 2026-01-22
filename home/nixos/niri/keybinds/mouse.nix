# Mouse/Wheel Keybindings - "Tape Scrolling" Metaphor
# Vertical scroll = scrubbing the horizontal "tape" of columns
_: {
  # Primary "tape scrolling" - vertical wheel moves horizontally through columns
  # Per guide: "Scrubbing the tape" - map scroll wheel to column focus
  "Mod+WheelScrollDown" = {
    cooldown-ms = 150;
    action.focus-column-right = { };
  };
  "Mod+WheelScrollUp" = {
    cooldown-ms = 150;
    action.focus-column-left = { };
  };

  # Move column (not just focus) with Ctrl modifier
  "Mod+Ctrl+WheelScrollDown" = {
    cooldown-ms = 150;
    action.move-column-right = { };
  };
  "Mod+Ctrl+WheelScrollUp" = {
    cooldown-ms = 150;
    action.move-column-left = { };
  };

  # Workspace navigation moved to Shift modifier
  "Mod+Shift+WheelScrollDown" = {
    cooldown-ms = 150;
    action.focus-workspace-down = { };
  };
  "Mod+Shift+WheelScrollUp" = {
    cooldown-ms = 150;
    action.focus-workspace-up = { };
  };
  "Mod+Ctrl+Shift+WheelScrollDown" = {
    cooldown-ms = 150;
    action.move-column-to-workspace-down = { };
  };
  "Mod+Ctrl+Shift+WheelScrollUp" = {
    cooldown-ms = 150;
    action.move-column-to-workspace-up = { };
  };

  # Horizontal scroll (if supported) also navigates columns
  "Mod+WheelScrollRight" = {
    cooldown-ms = 150;
    action.focus-column-right = { };
  };
  "Mod+WheelScrollLeft" = {
    cooldown-ms = 150;
    action.focus-column-left = { };
  };
  "Mod+Ctrl+WheelScrollRight" = {
    cooldown-ms = 150;
    action.move-column-right = { };
  };
  "Mod+Ctrl+WheelScrollLeft" = {
    cooldown-ms = 150;
    action.move-column-left = { };
  };
}
