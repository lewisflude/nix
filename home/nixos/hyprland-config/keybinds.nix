{
  wayland.windowManager.hyprland.settings = {
    bind =
      [
        "$mainMod, Q, exec, uwsm app -- $terminal"
        "$mainMod, R, exec, uwsm app -- $menu"
        "$mainMod, F, exec, uwsm app -- firefox"
        "$mainMod SHIFT, F, fullscreen"
        "$mainMod, V, exec, uwsm app -- $terminal -e clipse"
        "$mainMod, C, killactive,"
        "$mainMod, M, exec, uwsm stop"
        "$mainMod, E, exec, uwsm app -- $fileManager"
        "$mainMod, P, pseudo,"
        "$mainMod, J, togglesplit,"
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod, G, togglespecialworkspace, gaming"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"
        "$mainMod SHIFT, G, movetoworkspace, special:gaming"
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
        ", Print, exec, uwsm app -- grimblast save screen"
        "$mainMod, Print, exec, uwsm app -- grimblast save area"
        "$mainMod SHIFT, Print, exec, uwsm app -- grimblast save active"
      ]
      ++ (builtins.concatLists (
        builtins.genList (
          i:
          let
            ws = i + 1;
          in
          [
            "$mainMod, code:1${toString i}, workspace, ${toString ws}"
            "$mainMod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
          ]
        ) 9
      ));
    bindm = [
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
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
