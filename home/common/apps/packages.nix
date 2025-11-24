{
  pkgs,
  lib,
  ...
}:
{
  home.packages = [
    # Note: coreutils, libnotify, tree, nix-tree, nix-du, yaml-language-server,
    # gnutar, and gzip are handled in core-tooling.nix
    # Note: cachix is handled via programs.cachix in cachix.nix
    # Note: yq is handled via programs.yq in yq.nix
    # Note: sops is handled in features/security/default.nix
    # Note: nx is handled in core-tooling.nix
    # Note: musescore is installed via Homebrew cask (modules/darwin/apps.nix)
    # to avoid duplicate entries in Spotlight/Launchpad
    pkgs.pgcli
    pkgs.cursor-cli
    pkgs.claude-code # Claude agentic coding CLI (from claude-code-nix overlay)
  ]
  # Linux-only packages
  ++ lib.optionals pkgs.stdenv.isLinux [
    pkgs.seahorse # GNOME password and encryption key manager (PGP/GPG GUI)
  ];

  programs.htop.enable = true;
  programs.btop.enable = true;
}
