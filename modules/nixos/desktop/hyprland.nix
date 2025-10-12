_: {
  services = {
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", GROUP="video", MODE="0664"
    '';
    geoclue2.enable = true;
  };
}
