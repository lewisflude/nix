{ pkgs, ... }: {
  # Configure SSH
  services.openssh = { enable = true; };

  # Configure environment variables for GPG
  environment.variables = { GPG_TTY = "$(tty)"; };

  # Enable Touch ID for sudo
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    watchIdAuth = true;
  };

  # Add YubiKey tools
  environment.systemPackages = with pkgs; [
    yubikey-personalization
    yubico-pam
    yubikey-manager
  ];
}
