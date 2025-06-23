{
  pkgs,
  lib,
  config,
  ...
}:

{
  programs.ssh = {
    enable = true;
    package = pkgs.openssh.override { withSecurityKey = true; };

    addKeysToAgent = "yes";
    # SSH agent is handled by GPG agent via environment variable

    matchBlocks = {
      "*" = {
        identitiesOnly = true;
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
      };

      "github.com" = {
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
        forwardAgent = false;
      };
    };
  };

}
