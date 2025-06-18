{ pkgs, lib, ... }:
{
  programs.ssh = {
    enable = true;
    package = pkgs.openssh.override { withSecurityKey = true; };

    extraConfig = ''
      IgnoreUnknown UseKeychain        # let non-Apple OpenSSH ignore it

      Host *
        AddKeysToAgent yes
        IdentitiesOnly yes
        ServerAliveInterval 60
        ServerAliveCountMax 3
        ControlMaster auto
        ControlPath ~/.ssh/control/%r@%h:%p
        ControlPersist 10m
    '';

    matchBlocks."github.com".extraOptions = {
      IdentityFile = "~/.ssh/id_ecdsa_sk_github";
      IdentitiesOnly = "yes";
    };
  };

  home.activation.createSshControlDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.ssh/control
  '';
}
