{
  # GNOME Keyring for credential storage (secrets only)
  # Note: SSH component is disabled because we use GPG agent for SSH with YubiKey
  # See: home/common/features/core/gpg.nix (services.gpg-agent.enableSshSupport = true)
  services.gnome-keyring = {
    enable = true;
    components = [
      "secrets"
      # "ssh" - Disabled to avoid conflict with GPG agent SSH support
    ];
  };
}
