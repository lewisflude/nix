# XDG Base Directory configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.xdg
_: {
  flake.modules.homeManager.xdg =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      xdg = {
        enable = true;
        userDirs = lib.mkIf pkgs.stdenv.isLinux {
          enable = true;
          createDirectories = true;
          setSessionVariables = true;
          desktop = "${config.home.homeDirectory}/Desktop";
          documents = "${config.home.homeDirectory}/Documents";
          download = "${config.home.homeDirectory}/Downloads";
          music = "${config.home.homeDirectory}/Music";
          pictures = "${config.home.homeDirectory}/Pictures";
          videos = "${config.home.homeDirectory}/Videos";
          publicShare = "${config.home.homeDirectory}/Public";
          templates = "${config.home.homeDirectory}/Templates";
        };
      };
    };
}
