{ ... }: {
  # Enable Wayland for Firefox
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };

  programs.firefox = {
    enable = true;
  };
}