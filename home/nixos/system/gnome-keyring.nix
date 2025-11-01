# GNOME Keyring configuration via Home Manager
# This replaces the custom systemd.user.services configuration
{
  services.gnome-keyring = {
    enable = true;
    components = [
      "secrets"
      "ssh"
    ];
  };
}
