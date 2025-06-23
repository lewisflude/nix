{ pkgs, ... }:
{
  # Environment variables for browsers
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1"; # Enable Wayland for Firefox
    CHROME_EXECUTABLE = "${pkgs.google-chrome}/bin/google-chrome-stable";
  };

  programs.firefox = {
    enable = true;
  };

  # Chrome for bleeding-edge development
  home.packages = with pkgs; [
    google-chrome
  ];
}
