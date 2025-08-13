{ pkgs, ... }:

{
  systemd.settings.Manager.DefaultLimitNOFILE = "524288";

  security = {
    pam = {
      loginLimits = [
        {
          domain = "*";
          type = "hard";
          item = "nofile";
          value = "524288";
        }
        {
          domain = "*";
          type = "soft";
          item = "nofile";
          value = "524288";
        }
      ];

      services = {
        login = {
          enableGnomeKeyring = true;
          u2fAuth = true;
        };
        greetd = {
          enableGnomeKeyring = true;
          u2fAuth = true;
        };
        sudo = {
          enableGnomeKeyring = true;
          u2fAuth = true;
        };
        su.enableGnomeKeyring = true;
        swaylock = { };
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

    pki.certificateFiles = [ ../mitmproxy-ca-cert.pem ];
    polkit.enable = true;
  };

  # ─── GNOME Keyring ───────────────────────────────────────────────────────────
  services.gnome.gnome-keyring.enable = true;

  environment = {
    # ─── central, newline-terminated mapping file ──────────────────────────────
    etc."u2f_mappings" = {
      text = ''lewis:PaGbsjJa2IPXjK/nuSZEgqrqcP9JoxEO0IVVinIyfEXR0EbctKkhinM6f50ccHj7uSdy+YM2O+ToKVhqv5ynyQ==,cFyPyH4AUHDjTXelbVpf
nc4DnESr8xJWyZC42DwEiofkoqQdt0lBdxPGLwjviysl7WlH+jlEw3Yhe5TBiBLNOg==,es256,+presence'';
      mode = "0644";
    };

    # ─── user-space helpers ───────────────────────────────────────────────────
    systemPackages = with pkgs; [
      libsecret
      seahorse
      protonvpn-gui
    ];
  };

  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };

    _1password.enable = true;
    _1password-gui = {
      enable = true;
      package = pkgs._1password-gui-beta;
    };
  };

  boot.initrd.systemd.enable = true;
}

