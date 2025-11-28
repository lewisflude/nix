{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    optionalAttrs
    ;
  inherit (lib.lists) optional optionals;
  platformLib = (import ../../../../lib/functions.nix { inherit lib; }).withSystem hostSystem;
  inherit (platformLib) isLinux;
in
{
  imports = [ ];
  config =
    let
      cfg = config.host.features.security;
    in
    mkIf cfg.enable (mkMerge [
      {
        assertions = [
          {
            assertion = cfg.firewall -> isLinux;
            message = "Advanced firewall configuration is only available on NixOS";
          }
        ];
      }

      (optionalAttrs isLinux {
        security = {
          doas = {
            enable = true;
            extraRules = [
              {
                users = [ config.host.username ];
                keepEnv = true;
                persist = true;
                noPass = true; # Allow passwordless privilege escalation (matches sudo config)
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

        networking.firewall = mkIf cfg.firewall {
          enable = true;
        };

        services.gnome.gnome-keyring.enable = true;

        environment.systemPackages = optionals cfg.yubikey [
          pkgs.yubikey-manager
          pkgs.yubikey-personalization
          pkgs.yubioath-flutter
        ];

        users.users.${config.host.username}.extraGroups = optional cfg.yubikey "uucp";
      })

    ]);
}
