# Workspace Navigation Keybindings
# Workspace focus, movement, and navigation
_: {
  # Workspace navigation
  # U/I are above J/K on keyboard, so U=up and I=down (matching J=down, K=up pattern)
  "Mod+Page_Down".action.focus-workspace-down = { };
  "Mod+Page_Up".action.focus-workspace-up = { };
  "Mod+U".action.focus-workspace-up = { };
  "Mod+I".action.focus-workspace-down = { };

  # Move column to workspace (+Ctrl = move instead of focus)
  "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = { };
  "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = { };
  "Mod+Ctrl+U".action.move-column-to-workspace-up = { };
  "Mod+Ctrl+I".action.move-column-to-workspace-down = { };

  # Move workspace (+Shift = move the workspace itself)
  "Mod+Shift+Page_Down".action.move-workspace-down = { };
  "Mod+Shift+Page_Up".action.move-workspace-up = { };
  "Mod+Shift+U".action.move-workspace-up = { };
  "Mod+Shift+I".action.move-workspace-down = { };

  # Numbered workspace shortcuts
  "Mod+1".action.focus-workspace = 1;
  "Mod+2".action.focus-workspace = 2;
  "Mod+3".action.focus-workspace = 3;
  "Mod+4".action.focus-workspace = 4;
  "Mod+5".action.focus-workspace = 5;
  "Mod+6".action.focus-workspace = 6;
  "Mod+7".action.focus-workspace = 7;
  "Mod+8".action.focus-workspace = 8;
  "Mod+9".action.focus-workspace = 9;
  "Mod+0".action.focus-workspace = 10;

  # Move column to numbered workspace
  "Mod+Ctrl+1".action.move-column-to-workspace = 1;
  "Mod+Ctrl+2".action.move-column-to-workspace = 2;
  "Mod+Ctrl+3".action.move-column-to-workspace = 3;
  "Mod+Ctrl+4".action.move-column-to-workspace = 4;
  "Mod+Ctrl+5".action.move-column-to-workspace = 5;
  "Mod+Ctrl+6".action.move-column-to-workspace = 6;
  "Mod+Ctrl+7".action.move-column-to-workspace = 7;
  "Mod+Ctrl+8".action.move-column-to-workspace = 8;
  "Mod+Ctrl+9".action.move-column-to-workspace = 9;
  "Mod+Ctrl+0".action.move-column-to-workspace = 10;

  # Alt+Tab window/workspace switching
  "Alt+Tab".action.focus-window-or-workspace-down = { };
  "Alt+Shift+Tab".action.focus-window-or-workspace-up = { };

  # Overview
  "Mod+O".action.toggle-overview = { };
}
