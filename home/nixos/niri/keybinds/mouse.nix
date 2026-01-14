# Mouse/Wheel Keybindings
# Mouse wheel bindings for workspace and column navigation
_: {
  # Workspace navigation with mouse wheel
  "Mod+WheelScrollDown" = {
    cooldown-ms = 150;
    action.focus-workspace-down = { };
  };
  "Mod+WheelScrollUp" = {
    cooldown-ms = 150;
    action.focus-workspace-up = { };
  };
  "Mod+Ctrl+WheelScrollDown" = {
    cooldown-ms = 150;
    action.move-column-to-workspace-down = { };
  };
  "Mod+Ctrl+WheelScrollUp" = {
    cooldown-ms = 150;
    action.move-column-to-workspace-up = { };
  };

  # Column navigation with mouse wheel (horizontal scroll)
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
  "Mod+Shift+WheelScrollDown".action.focus-column-right = { };
  "Mod+Shift+WheelScrollUp".action.focus-column-left = { };
  "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = { };
  "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = { };
}
