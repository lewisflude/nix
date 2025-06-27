{
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "DP-1,3440x1440@165,0x0,1,vrr,1"
    ];

    windowrule = [
      # Floating windows - utility applications
      "float,class:^(pavucontrol|nm-connection-editor|1Password|blueman-manager|blueberry|qt5ct|qt6ct)$"
      "size 622 652,class:^(pavucontrol|nm-connection-editor|1Password)$"
      "center,class:^(pavucontrol|nm-connection-editor|1Password)$"
      "animation slide,class:^(pavucontrol|nm-connection-editor|1Password)$"

      # Floating windows - media applications
      "float,class:^(mpv|vlc|obs|gimp|inkscape|blender)$"
      "size 1280 720,class:^(mpv|vlc)$"
      "center,class:^(mpv|vlc)$"
      "workspace special:media,class:^(mpv|vlc|obs)$"
      "animation fade,class:^(mpv|vlc|obs)$"

      # Workspace assignments
      "workspace 1,class:^(firefox|brave|chromium|google-chrome)$" # Web browsers
      "workspace 2,class:^(code|vscodium|sublime_text|jetbrains-.*)$" # IDEs
      "workspace 3,class:^(ghostty|foot|kitty|alacritty|wezterm)$" # Terminals
      "workspace 4,class:^(discord|slack|telegram-desktop|element-desktop|signal-desktop)$" # Communication
      "workspace 5,class:^(thunderbird|evolution|geary|mailspring)$" # Email
      "workspace 6,class:^(spotify|clementine|lollypop)$" # Music

      # Gaming workspace and optimizations
      "workspace special:gaming,class:^(steam_app_|steam_app|lutris|gamescope)$"
      "workspace special:gaming,title:^(Steam)$"
      "immediate,class:^(steam_app_|gamescope|firefox|brave|chromium|google-chrome)$"
      "noanim,class:^(steam_app_|steam_app|lutris|gamescope)$"
      "opacity 1.0,class:^(steam_app_|steam_app|lutris|gamescope)$"
      "fullscreen,class:^(gamescope)$"
      "noblur,class:^(steam_app_|steam_app|lutris|gamescope|firefox|brave|chromium|google-chrome)$"
      "noshadow,class:^(steam_app_|steam_app|lutris|gamescope|firefox|brave|chromium|google-chrome)$"

      # General window behavior
      "tile,class:^(firefox|brave|chromium|google-chrome|code|vscodium|sublime_text|jetbrains-.*)$"
      "animation slide,class:^(firefox|brave|chromium|google-chrome|code|vscodium|sublime_text|jetbrains-.*)$"
      "animation fade,class:^(discord|slack|telegram-desktop|element-desktop|signal-desktop|thunderbird|evolution|geary|mailspring|spotify|clementine|lollypop)$"
    ];

    # Special workspace configurations
    workspace = [
      "special:gaming, rounding:false, blur:false, animation:false"
      "special:magic, rounding:true, blur:true, animation:true"
      "special:media, rounding:true, blur:true, animation:true"
    ];
  };
}
