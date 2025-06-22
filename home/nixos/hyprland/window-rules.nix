{ ... }: {
  wayland.windowManager.hyprland.settings = {
    # Window rules
    windowrule = [
      # Floating windows
      "float, ^(pavucontrol)$"
      "float, ^(blueman-manager)$"
      "float, ^(nm-connection-editor)$"
      "float, ^(chromium)$"
      "float, ^(thunar)$"
      "float, ^(nwg-look)$"
      "float, ^(qt5ct)$"
      "float, ^(qt6ct)$"
      "float, ^(kvantummanager)$"
      
      # Pin floating windows
      "pin, ^(wofi)$"
      "pin, ^(fuzzel)$"
      
      # Opacity rules
      "opacity 0.8 0.8, ^(Alacritty)$"
      "opacity 0.8 0.8, ^(kitty)$"
      "opacity 0.9 0.9, ^(ghostty)$"
      
      # Size rules for floating windows
      "size 800 600, ^(pavucontrol)$"
      "size 800 600, ^(blueman-manager)$"
      "size 600 400, ^(nm-connection-editor)$"
    ];

    # Enhanced window rules (windowrulev2)
    windowrulev2 = [
      # Workspace assignments
      "workspace 1, class:^(firefox)$"
      "workspace 2, class:^(Code)$"
      "workspace 2, class:^(code-oss)$"
      "workspace 2, class:^(vscodium)$"
      "workspace 3, class:^(discord)$"
      "workspace 3, class:^(Discord)$"
      "workspace 4, class:^(Spotify)$"
      "workspace 4, class:^(spotify)$"
      "workspace 5, class:^(obsidian)$"
      "workspace 5, class:^(Obsidian)$"
      
      # Gaming workspace (special optimizations)
      "workspace special:gaming, class:^(steam)$"
      "workspace special:gaming, class:^(Steam)$"
      "workspace special:gaming, class:^(lutris)$"
      "workspace special:gaming, class:^(Lutris)$"
      "workspace special:gaming, class:^(heroic)$"
      "workspace special:gaming, class:^(Heroic)$"
      "workspace special:gaming, class:^(bottles)$"
      "workspace special:gaming, class:^(Bottles)$"
      
      # Gaming optimizations (no blur, no shadow for performance)
      "noblur, class:^(steam)$"
      "noblur, class:^(Steam)$"
      "noblur, class:^(lutris)$"
      "noblur, class:^(Lutris)$"
      "noblur, class:^(heroic)$"
      "noblur, class:^(Heroic)$"
      "noshadow, class:^(steam)$"
      "noshadow, class:^(Steam)$"
      "noshadow, class:^(lutris)$"
      "noshadow, class:^(Lutris)$"
      "noshadow, class:^(heroic)$"
      "noshadow, class:^(Heroic)$"
      
      # Game windows (immediate rendering for lower latency)
      "immediate, class:^(steam_app_).*"
      "immediate, class:^(wine)$"
      "immediate, class:^(lutris)$"
      "immediate, title:^(.*)(.exe)$"
      
      # Fullscreen game optimizations
      "fullscreen, class:^(steam_app_).*"
      "noblur, class:^(steam_app_).*"
      "noshadow, class:^(steam_app_).*"
      "nomaximizerequest, class:^(steam_app_).*"
      
      # Picture-in-Picture
      "float, title:^(Picture-in-Picture)$"
      "pin, title:^(Picture-in-Picture)$"
      "size 400 225, title:^(Picture-in-Picture)$"
      "move 100%-420 100%-245, title:^(Picture-in-Picture)$"
      
      # File picker dialogs
      "float, title:^(Open File)$"
      "float, title:^(Select a File)$"
      "float, title:^(Choose wallpaper)$"
      "float, title:^(Open Folder)$"
      "float, title:^(Save As)$"
      "float, title:^(Library)$"
      "size 800 600, title:^(Open File)$"
      "size 800 600, title:^(Select a File)$"
      "size 800 600, title:^(Open Folder)$"
      "size 800 600, title:^(Save As)$"
      
      # Authentication dialogs
      "float, class:^(polkit-gnome-authentication-agent-1)$"
      "center, class:^(polkit-gnome-authentication-agent-1)$"
      "pin, class:^(polkit-gnome-authentication-agent-1)$"
      
      # Notification area
      "float, class:^(mako)$"
      "noanim, class:^(mako)$"
      
      # Terminal preferences
      "float, title:^(ghostty)$ AND title:^(Preferences)$"
      "center, title:^(ghostty)$ AND title:^(Preferences)$"
      "size 800 600, title:^(ghostty)$ AND title:^(Preferences)$"
      
      # System monitors
      "float, class:^(htop)$"
      "float, class:^(btop)$"
      "float, class:^(bottom)$"
      "size 1000 700, class:^(htop)$"
      "size 1000 700, class:^(btop)$"
      "size 1000 700, class:^(bottom)$"
      
      # Calculator
      "float, class:^(gnome-calculator)$"
      "float, class:^(kcalc)$"
      "pin, class:^(gnome-calculator)$"
      "pin, class:^(kcalc)$"
    ];

    # Layer rules for waybar and other overlays
    layerrule = [
      "blur, waybar"
      "ignorezero, waybar"
      "blur, notifications"
      "ignorezero, notifications"
      "blur, launcher"
      "ignorezero, launcher"
    ];
  };
}