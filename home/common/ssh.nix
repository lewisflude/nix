{pkgs, ...}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    package = pkgs.openssh.override {withSecurityKey = true;};

    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        controlMaster = "auto";
        controlPath = "~/.ssh/master-%r@%h:%p";
        controlPersist = "10m";
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ed25519_sk";
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
