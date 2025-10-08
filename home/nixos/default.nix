{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    # System integration
    ./system

    # Desktop environment
    ./browser.nix
    ./launcher.nix
    ./swaync.nix
    ./waybar.nix
    ./desktop-apps.nix
    ./yazi.nix
    ./niri.nix
    # Services
    ./mcp.nix
    ./apps/thunderbird.nix
    ./apps/gtklock.nix
    ./apps/swayidle.nix
    ./apps/swappy.nix
  ];

  # Required for Nautilus to function correctly with GVfs
  home.sessionVariables = {
    GIO_EXTRA_MODULES = "${inputs.nixpkgs.legacyPackages.${pkgs.system}.gnome.gvfs}/lib/gio/modules";
  };
}
