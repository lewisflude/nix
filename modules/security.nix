{ pkgs, ... }:
{
  # Enable Touch ID for sudo (nix-darwin only supports sudo_local PAM service)
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

  # Disable built-in SSH agent to avoid conflicts with GPG agent
  launchd.daemons."com.openssh.ssh-agent" = {
    serviceConfig = {
      Disabled = true;
    };
  };
}
