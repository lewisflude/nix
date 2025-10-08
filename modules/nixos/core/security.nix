{ pkgs, ... }: {
  # ─── limits and baseline security ────────────────────────────────────────────
  security = {
    # Enable doas for privilege escalation
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
        sudo.enableGnomeKeyring = true;
        su.enableGnomeKeyring = true;
        swaylock = { };
        sudo.u2fAuth = true;
        login.u2fAuth = true;
        # optionally:
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

  # ─── GNOME Keyring ───────────────────────────────────────────────────────────
  services.gnome.gnome-keyring.enable = true;

  # ─── Automatic Keyring Unlock for Auto-login ────────────────────────────────
  # Enable systemd user services for GNOME keyring integration
  systemd = {
    settings.Manager.DefaultLimitNOFILE = "524288";

    user.services = {
      gnome-keyring-daemon = {
        description = "GNOME Keyring daemon";
        enable = true;
        serviceConfig = {
          Type = "dbus";
          BusName = "org.gnome.keyring";
          ExecStart = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --foreground --components=secrets,ssh";
          Restart = "on-failure";
          Environment = [
            "XDG_RUNTIME_DIR=/run/user/%i"
          ];
        };
        wantedBy = [ "default.target" ];
      };

      # Auto-unlock login keyring for passwordless login sessions
      unlock-login-keyring = {
        description = "Unlock GNOME login keyring for auto-login sessions";
        after = [ "gnome-keyring-daemon.service" ];
        wants = [ "gnome-keyring-daemon.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          # Use empty password for auto-login scenarios - keyring will use the same password as login
          ExecStart = "${pkgs.writeShellScript "unlock-keyring" ''
            # Wait for keyring daemon to be ready
            sleep 2

            # Try to unlock with empty password first (for passwordless auto-login)
            if ! ${pkgs.libsecret}/bin/secret-tool lookup dummy dummy 2>/dev/null; then
              # Create/unlock default keyring with empty password for auto-login
              printf '\n' | ${pkgs.gnome-keyring}/bin/gnome-keyring --unlock 2>/dev/null || true
            fi
          ''}";
        };
        wantedBy = [ "default.target" ];
      };
    };
  };

  # ─── Session Environment Setup ───────────────────────────────────────────────
  # Ensure keyring environment variables are set for all sessions
  environment = {
    sessionVariables = {
      # Make sure applications know about the keyring
      XDG_RUNTIME_DIR = "/run/user/$UID";
    };

    # ─── central, newline-terminated mapping file ────────────────────────────────
    etc."u2f_mappings" = {
      text = ''lewis:PaGbsjJa2IPXjK/nuSZEgqrqcP9JoxEO0IVVinIyfEXR0EbctKkhinM6f50ccHj7uSdy+YM2O+ToKVhqv5ynyQ==,cFyPyH4AUHDjTXelbVpfnc4DnESr8xJWyZC42DwEiofkoqQdt0lBdxPGLwjviysl7WlH+jlEw3Yhe5TBiBLNOg==,es256,+presence'';
      mode = "0400";
    };

    # ─── user-space helpers ──────────────────────────────────────────────────────
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
