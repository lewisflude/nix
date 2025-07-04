services.hypridle = {
  enable = true;
  settings = {
    general = {
      lock_cmd = "pidof hyprlock || uwsm app -- hyprlock";
      before_sleep_cmd = "loginctl lock-session";
    };

    listener = [
      {
        timeout = 300;
        on-timeout = "loginctl lock-session";
      }
      {
        timeout = 600;
        on-timeout = "hyprctl dispatch dpms off";
        on-resume = "hyprctl dispatch dpms on";
      }
    ];
  };
};
