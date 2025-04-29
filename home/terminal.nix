{ pkgs, ... }:  {
  home.packages = with pkgs; [
    clipse
    wget
    curl
    comma
    rar
    p7zip
    devenv
    lsd
    rsync
    trash-cli
    micro
    fd
    bottom
    duf
    ncdu
    dust
    glances
    procs
    gping
    mosh
    aria2
    tldr
    mcfly
    atool
    pigz
    jq
    nil
    git-extras
    lazygit
    lazydocker
    zellij
  ];


  programs = {
    ghostty = {
      enable = true;
      package = null;
      enableZshIntegration = true;
      settings = {
        # Font configuration
        font-family = "Iosevka Nerd Font Mono";
        font-size = "16";
        font-feature = ["+calt" "+liga" "+dlig"];

        # Window appearance
        window-colorspace = "display-p3";
        window-padding-x = "10";
        window-padding-y = "10";
        background-opacity = "1.0";
        background-blur = "0";

        # Cursor configuration
        cursor-style = "block";
        cursor-style-blink = "true";

        # Terminal behavior
        copy-on-select = "true";
        scrollback-limit = "10000";
        shell-integration = "zsh";

        # Performance settings
        window-vsync = "true";

        # Window configuration
        window-decoration = "true";
        window-save-state = "always";

        # Theme
        theme = "catppuccin-mocha";
      };
    };
  };
}
