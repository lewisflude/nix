{
  pkgs,
  ...
}:

{
  programs.ssh = {
    enable = true;
    package = pkgs.openssh.override { withSecurityKey = true; };

    addKeysToAgent = "yes";
    # SSH agent is handled by GPG agent via environment variable

    controlMaster = "auto";
    controlPath = "~/.ssh/master-%r@%h:%p";
    controlPersist = "10m";

    matchBlocks = {
      "*" = {
        identitiesOnly = true;
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
      };

      "github.com" = {
        identitiesOnly = true;
        forwardAgent = false;
      };
    };
  };

}
