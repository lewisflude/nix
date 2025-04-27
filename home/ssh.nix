{ config, lib, pkgs, ... }: {
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_sk";
        extraOptions = {
          AddKeysToAgent = "yes";
          UseKeychain = "yes";
          IdentitiesOnly = "yes";
        };
      };
    };
    extraConfig = ''
      Host *
        AddKeysToAgent yes
        UseKeychain yes
        IdentitiesOnly yes
    '';
  };
}
