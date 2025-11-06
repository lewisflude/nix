_: {
  services.keyd = {
    enable = true;
    keyboards.mnk88 = {

      ids = [ "4b50:8800" ];
      settings = {

        global = {

          overload_tap_timeout = 200;
        };

        main = {

          capslock = "leftcontrol";

          leftalt = "leftmeta";
          rightalt = "rightmeta";

          leftcontrol = "leftalt";
          rightcontrol = "rightalt";
        };

        nav = {

          h = "left";
          j = "down";
          k = "up";
          l = "right";

          w = "C-right";
          b = "C-left";

          u = "pagedown";
          i = "pageup";
          y = "home";
          o = "end";

          c = "C-c";
          v = "C-v";
          x = "C-x";
          z = "C-z";
          s = "C-s";
          f = "C-f";
          d = "delete";

          f1 = "brightnessdown";
          f2 = "brightnessup";
          f5 = "volumedown";
          f6 = "volumeup";
          f7 = "previoussong";
          f8 = "playpause";
          f9 = "nextsong";
          f10 = "mute";
        };
      };
    };
  };

  systemd.services.keyd = {
    wantedBy = [ "sysinit.target" ];

    before = [ "display-manager.service" ];
  };
}
