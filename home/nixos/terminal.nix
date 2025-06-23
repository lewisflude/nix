{ pkgs, ... }: {
  # NixOS-specific terminal configuration
  # Base configuration is imported from ../common/terminal.nix
  
  # Additional NixOS-specific packages
  home.packages = with pkgs; [
    ghostty         # Ensure ghostty package is available
  ];

  programs.ghostty.settings = {
    # NixOS-specific shell integration features
    shell-integration-features = "cursor,sudo,title";
    
    # GTK/Linux-specific settings
    gtk-titlebar = true;
    gtk-tabs-location = "top";
    window-decoration = "server";
  };
}