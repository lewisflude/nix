{
  catppuccin,
  username,
  system,
  lib,
  ...
}:
{
  home.stateVersion = "25.05";
  home.username = username;
  
  # Platform-specific home directory
  home.homeDirectory = if lib.hasInfix "darwin" system 
    then "/Users/${username}"
    else "/home/${username}";

  imports = [
    # Common configurations (cross-platform)
    ./common
    
    # Platform-specific configurations
  ] ++ lib.optionals (lib.hasInfix "darwin" system) [
    ./darwin
  ];
  
  programs = {
    home-manager.enable = true;
  };

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
