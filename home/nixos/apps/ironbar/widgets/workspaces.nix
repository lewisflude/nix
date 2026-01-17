_: {
  type = "workspaces";
  class = "workspaces";
  # Standard Unicode circled numbers - guaranteed to work with Nix JSON serialization
  # Nerd Font icons (Private Use Area U+F0000+) get stripped by builtins.toJSON
  # These are standard Unicode that will serialize correctly
  name_map = {
    "1" = "①"; # Circled digit one
    "2" = "②"; # Circled digit two
    "3" = "③"; # Circled digit three
    "4" = "④"; # Circled digit four
    "5" = "⑤"; # Circled digit five
    "6" = "⑥"; # Circled digit six
    "7" = "⑦"; # Circled digit seven
    "8" = "⑧"; # Circled digit eight
    "9" = "⑨"; # Circled digit nine
    "10" = "⑩"; # Circled number ten
  };
  all_monitors = false;
  # Ironbar dynamically shows workspaces as niri creates them
  # Workspaces appear when you navigate to them or windows open on them
  hide_empty = false;
  hide_lonely = false;
  # Semantic icons with clean 18px sizing
  icon_size = 18;
  # Use name_map icons, not focused window icons
  show_icon = true;

  # Enable scroll navigation for workspace switching
  # Allows "scrubbing" workspaces directly from top bar
  on_scroll_up = "niri msg action focus-workspace-down";
  on_scroll_down = "niri msg action focus-workspace-up";
}
