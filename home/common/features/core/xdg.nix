{
  config,
  lib,
  pkgs,
  ...
}:
{
  # XDG Base Directory Specification
  # Manages standard user directories and ensures proper XDG compliance
  xdg = {
    enable = true;

    # User directories - standard locations for common folders
    userDirs = lib.mkIf pkgs.stdenv.isLinux {
      enable = true;
      createDirectories = true;

      # Standard user directories
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";

      # Additional directories
      publicShare = "${config.home.homeDirectory}/Public";
      templates = "${config.home.homeDirectory}/Templates";
    };
  };
}
