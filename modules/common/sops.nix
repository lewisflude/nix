{
  config,
  username,
  pkgs,
  ...
}:
let
  rootGroup = if pkgs.stdenv.isDarwin then "wheel" else "root";
in
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
        group = rootGroup;
      };
      LONGITUDE = {
        mode = "0400";
        owner = "root";
        group = rootGroup;
      };
      HOME_ASSISTANT_BASE_URL = {
        mode = "0400";
        owner = "root";
        group = rootGroup;
      };
    };
  };

}
