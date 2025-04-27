{ pkgs, ... }: {
  # Configure SSH
  services.openssh = { enable = true; };

  # Configure environment variables for GPG
  environment.variables = { GPG_TTY = "$(tty)"; };

  # Enable YubiKey PAM module
  security.pam.services = {
    sudo = {
      enable = true;
      text = ''
        auth       required       pam_yubico.so mode=challenge-response
        auth       required       pam_unix.so
      '';
    };
    login = {
      enable = true;
      text = ''
        auth       required       pam_yubico.so mode=challenge-response
        auth       required       pam_unix.so
      '';
    };
  };

  # Add YubiKey PAM package
  environment.systemPackages = with pkgs; [
    yubikey-personalization
    yubico-pam
  ];
}
