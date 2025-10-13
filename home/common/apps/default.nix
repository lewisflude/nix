{...}: {
  imports = [
    # Package installations
    ./packages.nix

    # Application configurations
    ./cursor
    ./bat.nix
    ./direnv.nix
    ./fzf.nix
    ./ripgrep.nix
    ./helix.nix
    ./obsidian.nix
    ./aws.nix
    ./docker.nix
    ./atuin.nix
    ./lazygit.nix
    ./lazydocker.nix
    ./micro.nix
    ./eza.nix
    ./jq.nix
    ./zellij.nix
  ];
}
