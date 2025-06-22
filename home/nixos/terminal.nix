{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Terminal and command line tools
    foot            # Wayland terminal
    clipse          # Clipboard manager
    ghostty         # Alternative terminal
    lsd             # Better ls
    lsof            # List open files
    trash-cli       # Safe rm replacement
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
    git-extras      # Extra git commands
    lazydocker      # Docker TUI
  ];

  programs = {
    ghostty = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        font-family = "Iosevka";
        font-size = 12;
        background-blur = true;
        shell-integration = "zsh";
        shell-integration-features = "cursor,sudo,title";
        font-feature = "+calt,+liga,+dlig";
        gtk-titlebar = true;
        gtk-tabs-location = "top";
        window-decoration = "server";
      };
    };
  };
}