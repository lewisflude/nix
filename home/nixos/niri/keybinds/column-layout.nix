# Column Layout Keybindings
# Column width, height, positioning, and manipulation
_: {
  # Column width adjustment
  "Mod+R".action.switch-preset-column-width = { };
  "Mod+Minus".action.set-column-width = "-10%";
  "Mod+Equal".action.set-column-width = "+10%";

  # Window height adjustment
  "Mod+Shift+R".action.switch-preset-window-height = { };
  "Mod+Ctrl+R".action.reset-window-height = { };
  "Mod+Shift+Minus".action.set-window-height = "-10%";
  "Mod+Shift+Equal".action.set-window-height = "+10%";

  # Column centering
  "Mod+C".action.center-column = { };
  "Mod+Ctrl+C".action.center-visible-columns = { };

  # Column manipulation
  "Mod+BracketLeft".action.consume-or-expel-window-left = { };
  "Mod+BracketRight".action.consume-or-expel-window-right = { };
  "Mod+Comma".action.consume-window-into-column = { };
  "Mod+Period".action.expel-window-from-column = { };
  "Mod+W".action.toggle-column-tabbed-display = { };

  # Column navigation
  "Mod+Left".action.focus-column-left = { };
  "Mod+Right".action.focus-column-right = { };
  "Mod+H".action.focus-column-left = { };
  "Mod+L".action.focus-column-right = { };
  "Mod+Home".action.focus-column-first = { };
  "Mod+End".action.focus-column-last = { };

  # Move column (+Ctrl = move instead of focus)
  "Mod+Ctrl+Home".action.move-column-to-first = { };
  "Mod+Ctrl+End".action.move-column-to-last = { };
  "Mod+Ctrl+Left".action.move-column-left = { };
  "Mod+Ctrl+Right".action.move-column-right = { };
  "Mod+Ctrl+H".action.move-column-left = { };
  "Mod+Ctrl+L".action.move-column-right = { };

  # Function keys for column layout
  "F16".action.maximize-column = { };
  "F18".action.center-column = { };
  "F17".action.set-column-width = "50%";
  "F19".action.set-column-width = "50%";
}
