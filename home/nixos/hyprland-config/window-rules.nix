{ lib, ... }:
let
  # Helper to create a regex from a list of app classes
  mkClass = apps: "^(${lib.strings.concatStringsSep "|" apps})$";

  # Application lists for rules
  browsers = [
    "firefox"
    "brave"
    "chromium"
    "google-chrome"
  ];
  chatApps = [
    "discord"
    "slack"
    "telegram-desktop"
    "element-desktop"
    "signal-desktop"
  ];
  codeEditors = [
    "code"
    "cursor"
    "vscodium"
    "sublime_text"
    "jetbrains-.*"
  ];
  emailClients = [
    "thunderbird"
    "evolution"
    "geary"
    "mailspring"
  ];
  floatingMedia = [
    "mpv"
    "vlc"
    "obs"
    "gimp"
    "inkscape"
    "blender"
  ];
  floatingUtils = [
    "pavucontrol"
    "nm-connection-editor"
    "1Password"
    "blueman-manager"
    "blueberry"
    "qt5ct"
    "qt6ct"
  ];
  gamingApps = [
    "steam_app_"
    "steam_app"
    "lutris"
    "gamescope"
  ];
  musicPlayers = [
    "spotify"
    "clementine"
    "lollypop"
  ];
  terminals = [
    "ghostty"
    "foot"
    "kitty"
    "alacritty"
    "wezterm"
  ];

in
{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      # --- Floating Rules ---
      # Utilities
      "float,class:${mkClass floatingUtils}"
      "size 622 652,class:^(pavucontrol|nm-connection-editor|1Password)$"
      "center,class:^(pavucontrol|nm-connection-editor|1Password)$"
      "animation slide,class:^(pavucontrol|nm-connection-editor|1Password)$"

      # Media
      "float,class:${mkClass floatingMedia}"
      "size 1280 720,class:^(mpv|vlc)$"
      "center,class:^(mpv|vlc)$"
      "workspace special:media,class:^(mpv|vlc|obs)$"
      "animation fade,class:^(mpv|vlc|obs)$"

      # --- Workspace Assignments ---
      "workspace 1,class:${mkClass browsers}" #  Browser
      "workspace 2,class:${mkClass terminals}" #  Terminal
      "workspace 3,class:${mkClass codeEditors}" #  Code/IDEs
      "workspace 4,class:${mkClass musicPlayers}" #  Music
      "workspace 5,class:${mkClass chatApps}" #  Chat
      "workspace 6,class:${mkClass emailClients}" #  Email (default)
      "workspace special:gaming,class:${mkClass gamingApps}"
      "workspace special:gaming silent,title:^(Steam)$"

      # --- Performance & Style Optimizations ---
      # Gaming
      "immediate,class:(${mkClass gamingApps}|${mkClass browsers})"
      "noanim,class:${mkClass gamingApps}"
      "opacity 1.0,class:${mkClass gamingApps}"
      "fullscreen,class:^(gamescope)$"
      "noblur,class:(${mkClass gamingApps}|${mkClass browsers})"
      "noshadow,class:(${mkClass gamingApps}|${mkClass browsers})"

      # Tiling & animations for common apps
      "tile,class:(${mkClass browsers}|${mkClass codeEditors})"
      "animation slide,class:(${mkClass browsers}|${mkClass codeEditors})"
      "animation fade,class:(${mkClass chatApps}|${mkClass emailClients}|${mkClass musicPlayers})"
    ];

    # --- Special Workspace Configurations ---
    workspace = [
      "special:gaming, rounding:false, blur:false, animation:false"
      "special:magic, rounding:true, blur:true, animation:true"
      "special:media, rounding:true, blur:true, animation:true"
    ];
  };
}
