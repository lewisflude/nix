# Security configuration module
# Provides doas, PAM, polkit, and 1Password
{ config, ... }:
let
  inherit (config) username;
in
{
  flake.modules.nixos.security =
    { pkgs, ... }:
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
          services = {
            login.enableGnomeKeyring = true;
            niri.enableGnomeKeyring = true;

            # No `greetd.text` here on purpose.
            #
            # Upstream's greetd module sets `useDefaultRules = false` and
            # delegates its whole stack to `login` via substack/include, so
            # everything configured on `login` above and in `security.pam.u2f`
            # below already applies to the greeter. Setting `.text` replaces the
            # generated stack wholesale (upstream's own `text` is only a
            # mkDefault), which previously dropped `pinverification=1` from the
            # u2f line, plus pam_loginuid and pam_lastlog2.
            #
            # The `pam_systemd ... class=greeter` line that used to live here was
            # also inert: greetd injects XDG_SESSION_CLASS itself, and per
            # pam_systemd(8) that env var takes precedence over `class=`.

            sudo.u2f.enable = false; # Use password for sudo (desktop workflow)
            login.u2f.enable = true; # YubiKey required at login (proves physical presence)
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
        user.settings.Manager.DefaultLimitNOFILE = "524288";
      };

      environment.etc = {
        # Public key material only (like an SSH public key) — safe in plaintext.
        # Stored in read-only NixOS-managed /etc/, preventing key injection.
        "u2f_mappings" = {
          text = "${username}:PaGbsjJa2IPXjK/nuSZEgqrqcP9JoxEO0IVVinIyfEXR0EbctKkhinM6f50ccHj7uSdy+YM2O+ToKVhqv5ynyQ==,cFyPyH4AUHDjTXelbVpfnc4DnESr8xJWyZC42DwEiofkoqQdt0lBdxPGLwjviysl7WlH+jlEw3Yhe5TBiBLNOg==,es256,+presence";
          mode = "0644";
        };
        # /etc/security/limits.conf is deliberately NOT written here. NixOS never
        # creates that path: security.pam.services.<name>.limits defaults to
        # security.pam.loginLimits and reaches PAM as
        # `pam_limits.so conf=/nix/store/...-limits.conf`. This entry existed
        # only to feed the hand-written greetd stack removed above.
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
