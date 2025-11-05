{ pkgs, ... }:
{
  security = {
    doas = {
      enable = true;
      extraRules = [
        {
          users = [ "lewis" ];
          keepEnv = true;
          persist = true;
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
      services = {
        login.enableGnomeKeyring = true;
        greetd.enableGnomeKeyring = true;
        niri.enableGnomeKeyring = true;
        sudo.enableGnomeKeyring = true;
        su.enableGnomeKeyring = true;
        swaylock = { };
        sudo.u2fAuth = true;
        login.u2fAuth = true;
        greetd.u2fAuth = true;
      };
      u2f = {
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
  # Note: gnome-keyring-daemon user service is now managed by Home Manager's
  # services.gnome-keyring module (see home/nixos/system/gnome-keyring.nix)
  # This replaces the custom systemd.user.services.gnome-keyring-daemon configuration

  # Ensure polkit runtime directories are created (tmpfiles.d best practice)
  systemd.tmpfiles.rules = [
    "d /run/polkit-1 0755 root root"
    "d /run/polkit-1/rules.d 0755 root root"
  ];

  systemd = {
    settings.Manager.DefaultLimitNOFILE = "524288";
    user.services = {
      # Auto-unlock service for login keyring in auto-login scenarios
      # This complements Home Manager's gnome-keyring service which handles the daemon
      unlock-login-keyring = {
        description = "Unlock GNOME login keyring for auto-login sessions";
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
  };
  environment = {
    sessionVariables = {
      XDG_RUNTIME_DIR = "/run/user/$UID";
    };
    etc."u2f_mappings" = {
      text = ''lewis:PaGbsjJa2IPXjK/nuSZEgqrqcP9JoxEO0IVVinIyfEXR0EbctKkhinM6f50ccHj7uSdy+YM2O+ToKVhqv5ynyQ==,cFyPyH4AUHDjTXelbVpfnc4DnESr8xJWyZC42DwEiofkoqQdt0lBdxPGLwjviysl7WlH+jlEw3Yhe5TBiBLNOg==,es256,+presence'';
      mode = "0400";
    };
  };
  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-qt; # Changed from pinentry-gnome3 due to webkitgtk removal
    };
    _1password = {
      enable = true;
    };
    _1password-gui = {
      enable = true;
      package = pkgs._1password-gui-beta;
    };
  };
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.dbus.enable = true;
}
