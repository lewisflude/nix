{ catppuccin
, ...
}: {
  home.stateVersion = "25.05";
  home.username = "lewisflude";
  home.homeDirectory = "/Users/lewisflude";

  imports = [
    ./git.nix
    ./shell.nix
    ./apps.nix
    ./ssh.nix
    ./gpg.nix
    ./theme.nix
    ./terminal.nix
    ./direnv.nix
    catppuccin.homeModules.catppuccin
  ];
  programs = { home-manager.enable = true; };

  # User-specific environment variables
  home.sessionVariables = {
    # Terminal and Pager
    PAGER = "less";
    MANPAGER = "less -R";

    # XDG Base Directory
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_CACHE_HOME = "$HOME/.cache";
  };
}
