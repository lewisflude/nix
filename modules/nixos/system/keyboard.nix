{
  services.xserver = {
    xkb = {
      layout = "us";
      # Swaps Left Alt with Left Super, and Right Alt with Right Super.
      # We must also restore F13-F24, as XKB can map them to media keys.
      options = "altwin:swap_alt_win,lv3:lalt_switch,misc:extend,lv5:ralt_switch_lock,misc:extend";
    };
  };
}
