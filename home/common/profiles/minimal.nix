# Minimal Home Manager profile
# Essential tools and configurations only, without optional features
# Use this for servers or constrained environments
{ ... }:
{
  imports = [
    ../shell.nix
    ../git.nix
    ../ssh.nix
    ../gpg.nix
    ../nix-config.nix

    # Essential apps only (lightweight CLI tools)
    ../apps/bat.nix
    ../apps/direnv.nix
    ../apps/fzf.nix
    ../apps/ripgrep.nix
    ../apps/eza.nix
    ../apps/jq.nix

    # Library functions
    ../lib

    # Custom modules
    ../modules.nix
  ];
}
