{
  pkgs,
  lib,
  system,
  config,
  ...
}:
let
  platformLib = import ../../lib/functions.nix { inherit lib system; };
  inputs = config._module.args.inputs or {};
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
      devenv # Development environments

      # Enhanced command line tools
      eza # Modern ls alternative
      rsync # File synchronization
      trash-cli # Better trash (safer rm replacement)
      micro # Terminal text editor
      fd # Better find
      dust # Disk usage tree (keeping most modern option)
      procs # Better ps
      gping # Ping with graph
      tldr # Better man pages
      atuin # Modern shell history
      p7zip # 7-Zip archiver (keeping most universal option)
      pigz # Parallel gzip
      jq # JSON processor

      # Git tools
      git-extras # Extra git commands
      lazygit # Git TUI
      lazydocker # Docker TUI
      zellij # Terminal multiplexer (modern)
    ]
    ++
      platformLib.platformPackages
        [
          # Linux-specific packages
          networkmanager # Network management
          lsof # List open files
          wtype # Wayland text input automation (xdotool equivalent)
        ]
        [
          # Darwin-specific packages
          # Note: nil (Nix language server) moved to development/language-tools.nix
        ];

  programs.ghostty = {
    enable = true;
    package = platformLib.platformPackage pkgs.ghostty pkgs.ghostty-bin;
    enableZshIntegration = true;
    settings = {
      font-family = "Iosevka Nerd Font";
      font-feature = "+calt,+liga,+dlig";
      font-size = 12;
      font-synthetic-style = true;
      scrollback-limit = 100000;
      # shift+enter sends a newline (LF, 0x0A)
      keybind = [ "shift+enter=text:\\n" ];

    };
  };
}
