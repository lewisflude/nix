{ pkgs, ... }: {
  home.packages = with pkgs; [
    clipse
    foot
    wget
    curl
    comma
    rar
    p7zip
    devenv
    ghostty
    lsd
    lsof
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
    doas
    gping
    mosh
    aria2
    networkmanager
    tldr
    mcfly
    atool
    pigz
    jq
    git-extras
    lazygit
    lazydocker
    zellij
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
