# Core Features
#
# Essential configuration included in all or most profiles.
# This includes shell setup, version control, SSH, GPG, secrets management,
# and Nix configuration.

{
  imports = [
    ./shell.nix
    ./git.nix
    ./ssh.nix
    ./gpg.nix
    ./sops.nix
    ./nix.nix
    ./terminal.nix
    ./nh.nix
  ];
}
