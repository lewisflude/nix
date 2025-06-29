{
  pkgs,
  lib,
  system,
  ...
}:
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
      lsd # Better ls
      rsync # File synchronization
      trash-cli # Safe rm replacement
      micro # Terminal text editor
      fd # Better find
      bottom # Better top
      duf # Better df
      ncdu # Disk usage analyzer
      dust # Disk usage tree
      glances # System monitor
      procs # Better ps
      gping # Ping with graph
      mosh # Mobile shell
      aria2 # Download manager
      tldr # Better man pages
      mcfly # Shell history
      atool # Archive manager
      pigz # Parallel gzip
      jq # JSON processor

      # Git tools
      git-extras # Extra git commands
      lazygit # Git TUI
      lazydocker # Docker TUI
      zellij # Terminal multiplexer
    ]
    ++ lib.optionals (lib.hasInfix "linux" system) [
      # Linux-specific packages
      foot # Wayland terminal
      networkmanager # Network management
      doas # Privilege escalation
      lsof # List open files
    ]
    ++ lib.optionals (lib.hasInfix "darwin" system) [
      # Darwin-specific packages
      nil # Nix language server
    ];

  programs.ghostty = {
    enable = true;
    package = if lib.hasInfix "linux" system then pkgs.ghostty else null;
    enableZshIntegration = true;
    settings = {
      font-family = "Iosevka Nerd Font";
      font-feature = "+calt,+liga,+dlig";
      font-size = 12;
      font-synthetic-style = true;
      cursor-color = "#f5e0dc";
      cursor-style = "block";
      cursor-style-blink = false;
      cursor-text = "#cdd6f4";

      scrollback-limit = 100000;
      copy-on-select = true;
      clipboard-read = "allow";
      clipboard-write = "allow";
      clipboard-paste-protection = false;
      click-repeat-interval = 500;

      background-opacity = 0.95;
      background-blur = true;
      window-padding-x = 8;
      window-padding-y = 8;
      window-save-state = "always";

      mouse-hide-while-typing = true;
      mouse-scroll-multiplier = 3;
    };
  };
}
