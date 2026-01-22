# Workspace Navigation Keybindings
# Following niri's dynamic workspace philosophy:
# - Workspaces are navigated up/down (not by index)
# - Workspaces appear/disappear dynamically as needed
# - Move workspaces to keep frequently-used ones adjacent
_: {
  # Workspace navigation (up/down)
  # U/I are above J/K on keyboard, so U=up and I=down (matching J=down, K=up pattern)
  "Mod+Page_Down".action.focus-workspace-down = { };
  "Mod+Page_Up".action.focus-workspace-up = { };
  "Mod+U".action.focus-workspace-up = { };
  "Mod+I".action.focus-workspace-down = { };

  # Move column to adjacent workspace (+Ctrl = move instead of focus)
  "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = { };
  "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = { };
  "Mod+Ctrl+U".action.move-column-to-workspace-up = { };
  "Mod+Ctrl+I".action.move-column-to-workspace-down = { };

  # Move workspace position (+Shift = reorder the workspace itself)
  # Use this to keep frequently-used workspaces adjacent for quick switching
  "Mod+Shift+Page_Down".action.move-workspace-down = { };
  "Mod+Shift+Page_Up".action.move-workspace-up = { };
  "Mod+Shift+U".action.move-workspace-up = { };
  "Mod+Shift+I".action.move-workspace-down = { };

  # Alt+Tab window/workspace switching
  "Alt+Tab".action.focus-window-or-workspace-down = { };
  "Alt+Shift+Tab".action.focus-window-or-workspace-up = { };

  # Overview - visual workspace/window picker
  "Mod+O".action.toggle-overview = { };
}
