{ ... }: {
  wayland.windowManager.hyprland.settings = {
    # Key bindings
    bind = [
      # Basic window management
      "$mod, C, killactive,"
      "$mod, M, exit,"
      "$mod, E, exec, $fileManager"
      "$mod, V, togglefloating,"
      "$mod, R, exec, $menu"
      "$mod, P, pseudo, # dwindle"
      "$mod, J, togglesplit, # dwindle"

      # Move focus with vim keys
      "$mod, h, movefocus, l"
      "$mod, l, movefocus, r"
      "$mod, k, movefocus, u"
      "$mod, j, movefocus, d"

      # Move focus with arrow keys
      "$mod, left, movefocus, l"
      "$mod, right, movefocus, r"
      "$mod, up, movefocus, u"
      "$mod, down, movefocus, d"

      # Move windows with vim keys
      "$mod SHIFT, h, movewindow, l"
      "$mod SHIFT, l, movewindow, r"
      "$mod SHIFT, k, movewindow, u"
      "$mod SHIFT, j, movewindow, d"

      # Move windows with arrow keys
      "$mod SHIFT, left, movewindow, l"
      "$mod SHIFT, right, movewindow, r"
      "$mod SHIFT, up, movewindow, u"
      "$mod SHIFT, down, movewindow, d"

      # Workspace switching
      "$mod, 1, workspace, 1"
      "$mod, 2, workspace, 2"
      "$mod, 3, workspace, 3"
      "$mod, 4, workspace, 4"
      "$mod, 5, workspace, 5"
      "$mod, 6, workspace, 6"
      "$mod, 7, workspace, 7"
      "$mod, 8, workspace, 8"
      "$mod, 9, workspace, 9"
      "$mod, 0, workspace, 10"

      # Move active window to workspace
      "$mod SHIFT, 1, movetoworkspace, 1"
      "$mod SHIFT, 2, movetoworkspace, 2"
      "$mod SHIFT, 3, movetoworkspace, 3"
      "$mod SHIFT, 4, movetoworkspace, 4"
      "$mod SHIFT, 5, movetoworkspace, 5"
      "$mod SHIFT, 6, movetoworkspace, 6"
      "$mod SHIFT, 7, movetoworkspace, 7"
      "$mod SHIFT, 8, movetoworkspace, 8"
      "$mod SHIFT, 9, movetoworkspace, 9"
      "$mod SHIFT, 0, movetoworkspace, 10"

      # Special workspaces
      "$mod, S, togglespecialworkspace, magic"
      "$mod SHIFT, S, movetoworkspace, special:magic"
      "$mod, G, togglespecialworkspace, gaming"
      "$mod SHIFT, G, movetoworkspace, special:gaming"

      # Scroll through existing workspaces
      "$mod, mouse_down, workspace, e+1"
      "$mod, mouse_up, workspace, e-1"

      # Terminal
      "$mod, Return, exec, $terminal"
      "$mod SHIFT, Return, exec, $terminal"

      # Screenshots
      ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
      "SHIFT, Print, exec, grim -g \"$(slurp)\" - | swappy -f -"
      "$mod, Print, exec, grim - | wl-copy"
      "$mod SHIFT, Print, exec, grim - | swappy -f -"

      # Application launches (using UWSM prefix)
      "$mod, B, exec, uwsm app -- firefox"
      "$mod, F, exec, uwsm app -- nautilus"
      "$mod, D, exec, uwsm app -- discord"
      "$mod, O, exec, uwsm app -- obsidian"

      # System controls
      "$mod, L, exec, hyprlock"
      "$mod SHIFT, E, exec, hyprctl dispatch exit"

      # Media controls (using playerctl)
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioPause, exec, playerctl play-pause"
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPrev, exec, playerctl previous"
      ", XF86AudioStop, exec, playerctl stop"
    ];

    # Mouse bindings
    bindm = [
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
    ];

    # Bind keys that need to repeat
    binde = [
      # Volume controls
      ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

      # Brightness controls
      ", XF86MonBrightnessUp, exec, brightnessctl s 10%+"
      ", XF86MonBrightnessDown, exec, brightnessctl s 10%-"

      # Resize windows with vim keys
      "$mod CTRL, h, resizeactive, -20 0"
      "$mod CTRL, l, resizeactive, 20 0"
      "$mod CTRL, k, resizeactive, 0 -20"
      "$mod CTRL, j, resizeactive, 0 20"

      # Resize windows with arrow keys
      "$mod CTRL, left, resizeactive, -20 0"
      "$mod CTRL, right, resizeactive, 20 0"
      "$mod CTRL, up, resizeactive, 0 -20"
      "$mod CTRL, down, resizeactive, 0 20"
    ];
  };
}