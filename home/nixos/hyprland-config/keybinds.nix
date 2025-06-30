{
  wayland.windowManager.hyprland.settings = {
    bind =
      [
        "$mod, Q, exec, uwsm app -- $terminal"
        "$mod, R, exec, uwsm app -- $menu"
        "$mod, F, exec, uwsm app -- firefox"
        "$mod SHIFT, F, fullscreen"
        "$mod, V, exec, uwsm app -- $terminal --class clipse -e 'clipse'"
        "$mod, C, killactive,"
        "$mod, M, exec, uwsm stop"
        "$mod, E, exec, uwsm app -- $fileManager"
        "$mod, P, pseudo,"
        "$mod, J, togglesplit,"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod, S, togglespecialworkspace, magic"
        "$mod, G, togglespecialworkspace, gaming"
        "$mod SHIFT, S, movetoworkspace, special:magic"
        "$mod SHIFT, G, movetoworkspace, special:gaming"
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
        ", Print, exec, uwsm app -- grimblast save screen"
        "$mod, Print, exec, uwsm app -- grimblast save area"
        "$mod SHIFT, Print, exec, uwsm app -- grimblast save active"
      ]
      ++ (builtins.concatLists (
        builtins.genList (
          i:
          let
            ws = i + 1;
          in
          [
            "$mod, code:1${toString i}, workspace, ${toString ws}"
            "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
          ]
        ) 9
      ));
    bindm = [
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
    ];
    bindel = [
      ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
      ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ",XF86MonBrightnessUp, exec, brightnessctl s 10%+"
      ",XF86MonBrightnessDown, exec, brightnessctl s 10%-"
    ];
    bindl = [
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPause, exec, playerctl play-pause"
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioPrev, exec, playerctl previous"
    ];
  };
}
