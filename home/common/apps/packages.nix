{
  pkgs,
  lib,
  system,
  ...
}:
let
  platformLib = (import ../../../lib/functions.nix { inherit lib; }).withSystem system;
in
{
  home.packages =
    with pkgs;
    # Core development tools
    [
      claude-code
      pkgs.gemini-cli-bin
      pkgs.cursor-cli
      codex
      nx-latest
    ]
    # System utilities
    ++ [
      coreutils
      libnotify
      tree
    ]
    # Note: Development tools (cmake, gnumake, pkg-config, openssl, etc.)
    # are now available in devShells. Use: nix develop .#devShells.development
    # Database tools
    ++ [
      pgcli
    ]
    # Nix tools
    ++ [
      cachix
      nix-tree
      nix-du
      sops
    ]
    # Language servers
    ++ [
      yaml-language-server
    ]
    # Platform-specific packages
    ++
      platformLib.platformPackages
        # Linux-specific
        [
          musescore
        ]
        # Darwin-specific
        [
          xcodebuild
          gnutar
          gzip
        ];

  # programs.rustup.enable = true; # Not available in home-manager

  # Monitoring tools
  programs.htop.enable = true;
  programs.btop.enable = true;
}
