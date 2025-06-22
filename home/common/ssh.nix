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

    extraConfig = ''
      Host *
        IdentityAgent ${config.home.homeDirectory}/.gnupg/S.gpg-agent.ssh
        IdentitiesOnly yes
        AddKeysToAgent yes
        ServerAliveInterval 60
        ServerAliveCountMax 3
        ControlMaster auto
        ControlPath ~/.ssh/control/%r@%h:%p
        ControlPersist 10m
    '';

    matchBlocks."github.com".extraOptions = {
      IdentityFile = "~/.ssh/id_ecdsa_sk_github";
      IdentitiesOnly = "yes";
      # Only use this identity for SSH connections, not Git signing
      ForwardAgent = "no";
    };
  };

  home.activation.createSshControlDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.ssh/control
  '';
}
