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
    mkDefault
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

        services.gnome.gnome-keyring.enable = true;

        environment.systemPackages =
          with pkgs;
          optionals cfg.yubikey [
            yubikey-manager
            yubikey-personalization
            yubioath-flutter
          ]
          ++ optionals cfg.gpg [
            gnupg
            pinentry-qt
          ];

        users.users.${config.host.username}.extraGroups = optional cfg.yubikey "uucp";
      })

      (mkIf (isLinux && cfg.gpg) {
        programs.gnupg.agent = {
          enable = true;
          enableSSHSupport = true;
          pinentryPackage = mkDefault pkgs.pinentry-qt;
        };
      })

      (mkIf (isLinux && cfg.firewall) {
        networking.firewall = {
          enable = true;
        };
      })
    ]);
}
