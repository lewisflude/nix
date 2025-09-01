{pkgs, ...}: {
  programs.ssh = {
    enable = true;
    package = pkgs.openssh.override {withSecurityKey = true;};

    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        controlMaster = "auto";
        controlPath = "~/.ssh/master-%r@%h:%p";
        controlPersist = "10m";
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
