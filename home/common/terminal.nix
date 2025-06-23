{ pkgs, lib, system, ... }: {
  # Common terminal packages across all platforms
  home.packages = with pkgs; [
    # Core utilities
    clipse          # Clipboard manager
    wget            # File downloader
    curl            # HTTP client
    comma           # Comma-separated values
    rar             # Archive manager
    p7zip           # 7-Zip archiver
    devenv          # Development environments
    
    # Enhanced command line tools
    lsd             # Better ls
    rsync           # File synchronization
    trash-cli       # Safe rm replacement
    micro           # Terminal text editor
    fd              # Better find
    bottom          # Better top
    duf             # Better df
    ncdu            # Disk usage analyzer
    dust            # Disk usage tree
    glances         # System monitor
    procs           # Better ps
    gping           # Ping with graph
    mosh            # Mobile shell
    aria2           # Download manager
    tldr            # Better man pages
    mcfly           # Shell history
    atool           # Archive manager
    pigz            # Parallel gzip
    jq              # JSON processor
    
    # Git tools
    git-extras      # Extra git commands
    lazygit         # Git TUI
    lazydocker      # Docker TUI
    zellij          # Terminal multiplexer
  ] ++ lib.optionals (lib.hasInfix "linux" system) [
    # Linux-specific packages
    foot            # Wayland terminal
    networkmanager  # Network management
    doas            # Privilege escalation
    lsof            # List open files
  ] ++ lib.optionals (lib.hasInfix "darwin" system) [
    # Darwin-specific packages
    nil             # Nix language server
  ];

  # Import common shell program configurations
  imports = [
    ./apps/bat.nix
    ./apps/direnv.nix
    ./apps/fzf.nix
    ./apps/ripgrep.nix
    ./apps/zoxide.nix
  ];

  # Base ghostty configuration (Linux only - use homebrew on Darwin)
  programs.ghostty = lib.mkIf (lib.hasInfix "linux" system) {
    enable = true;
    enableZshIntegration = true;
    settings = {
      # Common font configuration
      font-family = "Iosevka";
      font-size = lib.mkDefault 12;
      font-feature = "+calt,+liga,+dlig";
      
      # Common terminal behavior
      shell-integration = "zsh";
      background-blur = true;
    };
  };
}