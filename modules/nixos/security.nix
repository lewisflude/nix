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

  security.pki.certificateFiles = [ ../mitmproxy-ca-cert.pem ];
  security.polkit.enable = true;

  # ─── GNOME Keyring ───────────────────────────────────────────────────────────
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.sudo.enableGnomeKeyring = true;
  security.pam.services.su.enableGnomeKeyring = true;
  security.pam.services.swaylock = { };

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
