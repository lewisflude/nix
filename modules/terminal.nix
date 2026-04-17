# Terminal configuration (Ghostty + CLI tools)
# Dendritic pattern: Full implementation as flake.modules.homeManager.terminal
_: {
  flake.modules.homeManager.terminal =
    { lib, pkgs, ... }:
    {
      home.packages = [ pkgs.clipse ] ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.wtype ];

      # Ghostty configuration
      # Linux: install from nixpkgs
      # macOS: package = null (installed via Homebrew), but config managed by home-manager
      programs.ghostty = {
        enable = true;
        package = if pkgs.stdenv.isLinux then pkgs.ghostty else null;
        enableZshIntegration = true;
        settings = {
          window-decoration = "server";
          font-family = "Iosevka Nerd Font Mono";
          font-feature = "+calt,+liga,+dlig";
          font-size = 14;
          font-synthetic-style = true;
          scrollback-limit = 100000;
          clipboard-read = "allow";
          clipboard-write = "allow";
          clipboard-paste-protection = false;
          clipboard-paste-bracketed-safe = false;
          image-storage-limit = 320000000;
          keybind = [ ''shift+enter=text:\n'' ];
          window-padding-x = 20;
          window-padding-y = 16;
          window-padding-balance = true;
        };
      };
    };
}
