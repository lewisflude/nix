{ pkgs
, lib
, ...
}: {
  programs._1password = { enable = true; };

  programs._1password-gui = {
    enable = true;
  };

  security.pam = {
    u2f = {
      enable = true;
      settings = {
        interactive = true;
        cue = true;
        origin = "pam://yubi";
        authfile = pkgs.writeText "u2f-mappings" (lib.concatStrings [
          "lewis"
          ":2VSzAjl4mGzO++FxrAmemRqI4SXEuj7/wrFdvBE9E0QqI97nCpvUVz/Y5X7xI7Xn/9o9JqHe5+9BdAFNBrpv8Q==,LbUzOSvKgndpCtqsJT9C0bzZb+SuK9tIjjDW24iHXRN3D4nLv8R8Wrkon+oKQCaptnkSlzRMAoSRU79bunfGtA==,es256,+presence"
        ]);
      };
    };
    services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true;
    };
  };
  services = {
    pcscd.enable = true;
    udev.packages = [ pkgs.yubikey-personalization ];
  };
}
