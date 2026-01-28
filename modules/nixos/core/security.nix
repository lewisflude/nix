{
  pkgs,
  config,
  lib,
  ...
}:
{
  security = {
    doas = {
      enable = true;
      extraRules = [
        {
          users = [ "lewis" ];
          keepEnv = true;
          noPass = true; # Allow passwordless privilege escalation (matches sudo config)
        }
      ];
    };
    pam = {
      loginLimits = [
        {
          domain = "*";
          type = "soft";
          item = "nofile";
          value = "65536";
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
          # Shared PAM configuration for graphical login services
          # Enables U2F authentication with YubiKey and GNOME Keyring integration
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
            session required ${pkgs.systemd}/lib/security/pam_systemd.so
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
            auth required ${pkgs.linux-pam}/lib/security/pam_deny.so
          '';

          sudo.u2fAuth = true;
          login.u2fAuth = true;
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
    settings.Manager.DefaultLimitNOFILE = builtins.toString config.host.systemDefaults.fileDescriptorLimit;
    user.extraConfig = ''
      [Manager]
      DefaultLimitNOFILE=${builtins.toString config.host.systemDefaults.fileDescriptorLimit}
    '';
    user.services.unlock-login-keyring = {
      description = "Unlock GNOME login keyring for auto-login";
      after = [ "gnome-keyring-daemon.service" ];
      wants = [ "gnome-keyring-daemon.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.writeShellScript "unlock-keyring" ''
          sleep 2
          if ! ${pkgs.libsecret}/bin/secret-tool lookup dummy dummy 2>/dev/null; then
            printf '\n' | ${pkgs.gnome-keyring}/bin/gnome-keyring --unlock 2>/dev/null || true
          fi
        ''}";
      };
      wantedBy = [ "default.target" ];
    };
  };
  environment.etc = {
      # U2F/FIDO2 key mappings for YubiKey authentication
      # Generated with: pamu2fcfg -o pam://yubi -i pam://yubi
      "u2f_mappings" = {
        text = "lewis:PaGbsjJa2IPXjK/nuSZEgqrqcP9JoxEO0IVVinIyfEXR0EbctKkhinM6f50ccHj7uSdy+YM2O+ToKVhqv5ynyQ==,cFyPyH4AUHDjTXelbVpfnc4DnESr8xJWyZC42DwEiofkoqQdt0lBdxPGLwjviysl7WlH+jlEw3Yhe5TBiBLNOg==,es256,+presence";
        mode = "0644";
      };
      "security/limits.conf" = {
        text = lib.concatMapStringsSep "\n" (
          limit: "${limit.domain} ${limit.type} ${limit.item} ${toString limit.value}"
        ) config.security.pam.loginLimits;
        mode = "0644";
      };
    };

  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      package = pkgs._1password-gui-beta;
    };
  };
}
