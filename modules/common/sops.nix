{
  config,
  username,
  pkgs,
  ...
}:
{

  environment.systemPackages = with pkgs; [
    sops
  ];

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ../../secrets/secrets.yaml;

    secrets = {
      LATITUDE = {
        mode = "0400";
        owner = "root";
        group = "root";
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
