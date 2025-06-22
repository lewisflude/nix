{ pkgs, ... }: {
  # environment.systemPackages = with pkgs; [
  #   sops
  # ];

  # sops = {
  #   gnupg.home = "/home/lewis/.gnupg";
  #   gnupg.sshKeyPaths = [ ];
  #   defaultSopsFile = ../../secrets.yaml;
  #   secrets = {
  #     foo = { };
  #   };
  # };
}
