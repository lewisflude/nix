{ pkgs, ... }:
{

  programs.firefox = {
    enable = true;
  };

  # Chrome for bleeding-edge development
  home.packages = with pkgs; [
    google-chrome
  ];
}
