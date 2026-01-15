_: {
  type = "workspaces";
  class = "workspaces";
  # Clean, semantic workspace labels with visually consistent icons
  # Icons chosen for clarity, recognizability, and aesthetic harmony
  # 1-2: Browser, 3-4: Dev, 5-6: Chat, 7-8: Media, 9: Gaming, 10: Extra
  name_map = {
    "1" = ""; # Browser primary - clear globe icon
    "2" = ""; # Browser secondary - secondary window
    "3" = ""; # Development primary - code brackets
    "4" = ""; # Development secondary - terminal
    "5" = ""; # Communication primary - chat bubbles
    "6" = "󰇮"; # Communication secondary - mail
    "7" = ""; # Media primary - music note (Spotify/audio)
    "8" = ""; # Media secondary - video/film
    "9" = ""; # Gaming - gamepad icon
    "10" = ""; # Extra workspace - generic box/container
  };
  all_monitors = false;
  # Ironbar dynamically shows workspaces as niri creates them
  # Workspaces appear when you navigate to them or windows open on them
  hide_empty = false;
  hide_lonely = false;
  # Semantic icons with clean 18px sizing
  icon_size = 18;
  # Use name_map icons, not focused window icons
  show_icon = false;

  # Enable scroll navigation for workspace switching
  # Allows "scrubbing" workspaces directly from top bar
  on_scroll_up = "niri msg action focus-workspace-down";
  on_scroll_down = "niri msg action focus-workspace-up";
}
