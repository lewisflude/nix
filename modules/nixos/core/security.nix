{ pkgs, lib, ... }:

{
  # ─── limits and baseline security ────────────────────────────────────────────
  security.pam.loginLimits = [
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
  systemd.settings.Manager.DefaultLimitNOFILE = "524288";

  security.pki.certificateFiles = [ ../../../secrets/certificates/mitmproxy-ca-cert.pem ];
  security.polkit.enable = true;

  # ─── GNOME Keyring ───────────────────────────────────────────────────────────
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.sudo.enableGnomeKeyring = true;
  security.pam.services.su.enableGnomeKeyring = true;
  security.pam.services.swaylock = { };

  # ─── Automatic Keyring Unlock for Auto-login ────────────────────────────────
  # Enable systemd user services for GNOME keyring integration
  systemd.user.services.gnome-keyring-daemon = {
    description = "GNOME Keyring daemon";
    enable = true;
    serviceConfig = {
      Type = "dbus";
      BusName = "org.gnome.keyring";
      ExecStart = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --foreground --components=secrets,ssh";
      Restart = "on-failure";
    };
    wantedBy = [ "default.target" ];
  };

  # Auto-unlock login keyring for passwordless login sessions
  systemd.user.services.unlock-login-keyring = {
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

  # ─── Session Environment Setup ───────────────────────────────────────────────
  # Ensure keyring environment variables are set for all sessions
  environment.sessionVariables = {
    # Make sure applications know about the keyring
    XDG_RUNTIME_DIR = "/run/user/$UID";
  };

  # Add keyring socket environment for applications
  systemd.user.services.gnome-keyring-daemon.serviceConfig.Environment = [
    "XDG_RUNTIME_DIR=/run/user/%i"
  ];

  # ─── U 2 F global settings (absolute module path picked by pam.nix) ──────────
  security.pam.u2f = {
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

  security.pam.services = {
    sudo.u2fAuth = true;
    login.u2fAuth = true;
    # optionally:
    greetd.u2fAuth = true;
  };

  # ─── central, newline-terminated mapping file ────────────────────────────────
  environment.etc."u2f_mappings" = {
    text = ''lewis:PaGbsjJa2IPXjK/nuSZEgqrqcP9JoxEO0IVVinIyfEXR0EbctKkhinM6f50ccHj7uSdy+YM2O+ToKVhqv5ynyQ==,cFyPyH4AUHDjTXelbVpfnc4DnESr8xJWyZC42DwEiofkoqQdt0lBdxPGLwjviysl7WlH+jlEw3Yhe5TBiBLNOg==,es256,+presence'';
    mode = "0644";
  };

  # ─── user-space helpers ──────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    libsecret
    seahorse
    protonvpn-gui
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };

  programs._1password = {
    enable = true;
  };
  programs._1password-gui = {
    enable = true;
    package = pkgs._1password-gui-beta;
  };

  boot.initrd.systemd.enable = true;
}
