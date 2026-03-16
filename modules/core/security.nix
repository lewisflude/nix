# Security configuration module
# Provides doas, PAM, polkit, and 1Password
{ config, ... }:
let
  inherit (config) username;
in
{
  flake.modules.nixos.security =
    {
      pkgs,
      lib,
      ...
    }@nixosArgs:
    {
      security = {
        pam = {
          loginLimits = [
            {
              domain = "*";
              type = "soft";
              item = "nofile";
              value = "524288";
            }
            {
              domain = "*";
              type = "hard";
              item = "nofile";
              value = "1048576";
            }
          ];
          services =
            let
              basePamConfig = ''
                account required ${pkgs.linux-pam}/lib/security/pam_unix.so
                auth sufficient ${pkgs.pam_u2f}/lib/security/pam_u2f.so authfile=/etc/u2f_mappings cue nouserok userpresence=1 origin=pam://yubi
                auth sufficient ${pkgs.linux-pam}/lib/security/pam_unix.so
                auth optional ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so
                password sufficient ${pkgs.linux-pam}/lib/security/pam_unix.so yescrypt
                password optional ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so use_authtok
                session required ${pkgs.linux-pam}/lib/security/pam_env.so conffile=/etc/pam/environment readenv=0
                session required ${pkgs.linux-pam}/lib/security/pam_unix.so
                session required ${pkgs.linux-pam}/lib/security/pam_limits.so conf=/etc/security/limits.conf
                session optional ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so auto_start
              '';
            in
            {
              login.enableGnomeKeyring = true;
              niri.enableGnomeKeyring = true;

              greetd.text = ''
                ${basePamConfig}
                session required ${pkgs.systemd}/lib/security/pam_systemd.so class=greeter
              '';

              swaylock.text = ''
                ${basePamConfig}
                session required ${pkgs.systemd}/lib/security/pam_systemd.so
                auth required ${pkgs.linux-pam}/lib/security/pam_deny.so
              '';

              sudo.u2fAuth = false; # Use password for sudo (desktop workflow)
              login.u2fAuth = true; # YubiKey required at login (proves physical presence)
            };
          u2f = {
            enable = true;
            control = "sufficient";
            settings = {
              cue = true;
              nouserok = true;
              pinverification = 1;
              userpresence = 1;
              origin = "pam://yubi";
              authfile = "/etc/u2f_mappings";
            };
          };
        };
        polkit.enable = true;
      };

      services.gnome.gnome-keyring.enable = true;

      systemd.tmpfiles.rules = [
        "d /run/polkit-1 0755 root root"
        "d /run/polkit-1/rules.d 0755 root root"
      ];

      systemd = {
        settings.Manager.DefaultLimitNOFILE = "524288";
        user.extraConfig = ''
          [Manager]
          DefaultLimitNOFILE=524288
        '';
      };

      environment.etc = {
        # Public key material only (like an SSH public key) — safe in plaintext.
        # Stored in read-only NixOS-managed /etc/, preventing key injection.
        "u2f_mappings" = {
          text = "${username}:PaGbsjJa2IPXjK/nuSZEgqrqcP9JoxEO0IVVinIyfEXR0EbctKkhinM6f50ccHj7uSdy+YM2O+ToKVhqv5ynyQ==,cFyPyH4AUHDjTXelbVpfnc4DnESr8xJWyZC42DwEiofkoqQdt0lBdxPGLwjviysl7WlH+jlEw3Yhe5TBiBLNOg==,es256,+presence";
          mode = "0644";
        };
        "security/limits.conf" = {
          text = lib.concatMapStringsSep "\n" (
            limit: "${limit.domain} ${limit.type} ${limit.item} ${toString limit.value}"
          ) nixosArgs.config.security.pam.loginLimits;
          mode = "0644";
        };
      };

      # Note: GPG agent is configured via home-manager in modules/gpg.nix
      # (provides more complete config with pinentry, cache TTLs, etc.)
      programs = {
        _1password.enable = true;
        _1password-gui = {
          enable = true;
          package = pkgs._1password-gui-beta;
        };
      };
    };
}
