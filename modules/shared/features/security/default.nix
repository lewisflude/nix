{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.lists) optional optionals;
  cfg = config.host.features.security;
  platformLib = (import ../../../../lib/functions.nix { inherit lib; }).withSystem hostSystem;
  inherit (platformLib) isLinux;
in
{
  config = mkIf cfg.enable {

    security = mkIf isLinux {

      doas = {
        enable = true;
        extraRules = [
          {
            users = [ config.host.username ];
            keepEnv = true;
            persist = true;
          }
        ];
      };

      pam = {
        services = {
          login.u2fAuth = cfg.yubikey;
          sudo.u2fAuth = cfg.yubikey;
          greetd.u2fAuth = cfg.yubikey;
        };
        u2f = mkIf cfg.yubikey {
          enable = true;
          control = "sufficient";
          settings = {
            debug = false;
            interactive = true;
            cue = true;
            origin = "pam://yubi";
            authfile = "/etc/u2f_mappings";
            max_devices = 5;
          };
        };
      };

      polkit.enable = true;
    };

    services.gnome.gnome-keyring.enable = mkIf isLinux true;

    programs.gnupg.agent = mkIf (isLinux && cfg.gpg) {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = mkDefault pkgs.pinentry-qt;
    };

    networking.firewall = mkIf (isLinux && cfg.firewall) {
      enable = true;

    };

    environment.systemPackages = mkIf isLinux (
      with pkgs;
      optionals cfg.yubikey [
        yubikey-manager
        yubikey-personalization
        yubioath-flutter
      ]
      ++ optionals cfg.gpg [
        gnupg
        pinentry-qt
      ]
    );

    users.users.${config.host.username}.extraGroups = mkIf isLinux (optional cfg.yubikey "uucp");

    assertions = [
      {
        assertion = cfg.firewall -> isLinux;
        message = "Advanced firewall configuration is only available on NixOS";
      }
    ];
  };
}
