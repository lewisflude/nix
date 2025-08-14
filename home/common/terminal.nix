{
  pkgs,
  lib,
  system,
  ghostty,
  ...
}:
let
  platformLib = import ../../lib/functions.nix { inherit lib system; };
in
{
  # Common terminal packages across all platforms
  home.packages =
    with pkgs;
    [
      # Core utilities
      clipse # Clipboard manager
      wget # File downloader
      curl # HTTP client
      comma # Comma-separated values
      rar # Archive manager
      p7zip # 7-Zip archiver
      devenv # Development environments

      # Enhanced command line tools
      eza # Modern ls alternative
      rsync # File synchronization
      trash-cli # Safe rm replacement
      micro # Terminal text editor
      fd # Better find
      duf # Better df
      ncdu # Disk usage analyzer
      dust # Disk usage tree
      procs # Better ps
      gping # Ping with graph
      mosh # Mobile shell
      aria2 # Download manager
      tldr # Better man pages
      atuin # Modern shell history
      atool # Archive manager
      pigz # Parallel gzip
      jq # JSON processor

      # Git tools
      git-extras # Extra git commands
      lazygit # Git TUI
      lazydocker # Docker TUI
      zellij # Terminal multiplexer
    ]
    ++
      platformLib.platformPackages
        [
          # Linux-specific packages
          networkmanager # Network management
          doas # Privilege escalation
          lsof # List open files
        ]
        [
          # Darwin-specific packages
          # Note: nil (Nix language server) moved to development/language-tools.nix
        ];

  programs.ghostty = {
    enable = true;
    package = platformLib.platformPackage pkgs.ghostty null;
    enableZshIntegration = true;
    settings = {
      font-family = "Iosevka Nerd Font";
      font-feature = "+calt,+liga,+dlig";
      font-size = 12;
      font-synthetic-style = true;

      scrollback-limit = 100000;
    };
  };
}
