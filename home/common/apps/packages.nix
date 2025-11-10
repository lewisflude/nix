{
  pkgs,
  lib,
  system,
  ...
}:
let
  helpers = import ./_helpers.nix { inherit lib system; };
  inherit (helpers) platformLib getNxPackage;
  nx = getNxPackage pkgs;
in
{
  home.packages = [
    # Note: coreutils, libnotify, tree, nix-tree, nix-du, yaml-language-server,
    # gnutar, and gzip are handled in core-tooling.nix
    # Note: cachix is handled via programs.cachix in cachix.nix
    # Note: yq is handled via programs.yq in yq.nix
    # Note: sops is handled in features/security/default.nix
    # Note: musescore is installed via Homebrew cask (modules/darwin/apps.nix)
    # to avoid duplicate entries in Spotlight/Launchpad
    pkgs.pgcli
    pkgs.cursor-cli
    pkgs.claude-code # Claude agentic coding CLI
  ]
  ++ lib.optional (nx != null) nx
  ++ platformLib.platformPackages [ ] [ pkgs.xcodebuild ];

  programs.htop.enable = true;
  programs.btop.enable = true;
}
