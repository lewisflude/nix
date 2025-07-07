{
  ...
}:
{
  # NixOS-specific SOPS configuration
  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ../../secrets/secrets.yaml;

    secrets = {
      LATITUDE = {
        mode = "0400";
        owner = "root";
        group = "root"; # NixOS uses root group
      };
      LONGITUDE = {
        mode = "0400";
        owner = "root";
        group = "root";
      };
      HOME_ASSISTANT_BASE_URL = {
        mode = "0400";
        owner = "root";
        group = "root";
      };
    };
  };
}
