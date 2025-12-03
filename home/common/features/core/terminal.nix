{
  pkgs,
  lib,
  ...
}:
{
  home.packages = [
    pkgs.clipse
    pkgs.comma
    pkgs.devenv
    # Note: eza is handled via programs.eza in apps/eza.nix
    pkgs.rsync
    pkgs.trash-cli
    pkgs.fd
    pkgs.dust
    pkgs.procs
    pkgs.gping
    # Note: tldr is handled via programs.tealdeer in apps/tealdeer.nix
    pkgs.p7zip
    pkgs.pigz
    pkgs.git-extras
  ]
  # Linux-only packages
  ++ lib.optionals pkgs.stdenv.isLinux [
    pkgs.networkmanager
    pkgs.lsof
    pkgs.wtype
  ];

  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isLinux then pkgs.ghostty else null;
    enableZshIntegration = true;
    settings = {
      font-family = "Iosevka Nerd Font";
      font-feature = "+calt,+liga,+dlig";
      font-size = 12;
      font-synthetic-style = true;
      scrollback-limit = 100000;

      # Shift+Enter inserts a newline (multiline input)
      # Note: The literal backslash-n must be preserved in the output
      keybind = [ ''shift+enter=text:\n'' ];
    };
  };
}
