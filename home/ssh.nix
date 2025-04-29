{ config, lib, pkgs, ... }: {
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        extraOptions = {
          AddKeysToAgent = "yes";
          UseKeychain = "no";
          IdentitiesOnly = "yes";
        };
      };
    };
    extraConfig = ''
      Host *
        AddKeysToAgent yes
        UseKeychain no
        IdentitiesOnly yes
    '';
  };
}
