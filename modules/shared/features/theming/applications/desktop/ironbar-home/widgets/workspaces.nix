_: {
  type = "workspaces";
  class = "workspaces";
  # Match niri's workspace organization with semantic labels
  # 1-2: Browser, 3-4: Dev, 5-6: Chat, 7-8: Media, 9: Gaming, 10: Extra
  name_map = {
    "1" = "󰈹"; # Browser primary
    "2" = "󰖟"; # Browser secondary
    "3" = "󰨞"; # Development primary
    "4" = ""; # Development secondary
    "5" = "󰭹"; # Communication primary
    "6" = "󰙯"; # Communication secondary
    "7" = "󰝚"; # Media primary (Spotify/Obsidian)
    "8" = "󰎆"; # Media secondary
    "9" = "󰊴"; # Gaming (Steam/games)
    "10" = "󰋙"; # Extra workspace
  };
  all_monitors = false;
  # Ironbar dynamically shows workspaces as niri creates them
  # Workspaces appear when you navigate to them or windows open on them
  hide_empty = false;
  hide_lonely = false;
  # Force semantic icons instead of application icons
  icon_size = 18;
  # Use name_map icons, not focused window icons
  show_icon = false;
}
