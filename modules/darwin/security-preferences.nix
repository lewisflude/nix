{
  lib,
  config,
  ...
}:
let
  cfg = config.host.features.securityPreferences;
in
{
  options.host.features.securityPreferences = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable security and firewall preferences";
    };
  };

  config = lib.mkIf cfg.enable {

    networking.applicationFirewall = {
      enable = true;
      blockAllIncoming = false;
      allowSigned = true;
      allowSignedApp = true;
      enableStealthMode = false;
    };

    system.defaults = {

      loginwindow = {
        GuestEnabled = false;
        DisableConsoleAccess = true;
        SHOWFULLNAME = false;
        autoLoginUser = null;
        PowerOffDisabledWhileLoggedIn = false;
        RestartDisabledWhileLoggedIn = false;
        ShutDownDisabledWhileLoggedIn = false;
        SleepDisabled = false;
      };
    };
  };
}
