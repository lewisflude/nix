{ pkgs, ... }: {
  # NixOS-specific terminal configuration
  # Base configuration is imported from ../common/terminal.nix

  # Additional NixOS-specific packages
  # Note: ghostty package is provided by programs.ghostty in common/terminal.nix
  home.packages = with pkgs; [
    # Add other NixOS-specific terminal packages here if needed
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
