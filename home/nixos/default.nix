{pkgs, ...}: {
  imports = [
    ./system
    ./browser.nix
    ./launcher.nix
    ./swaync.nix
    ./waybar.nix
    ./desktop-apps.nix
    ./yazi.nix
    ./niri.nix
    ./mcp.nix
    ./apps/thunderbird.nix
    ./apps/gtklock.nix
    ./apps/swayidle.nix
    ./apps/swappy.nix
    ./apps/wofi.nix
    ./apps/gaming.nix
  ];
  home.sessionVariables = {
    GIO_EXTRA_MODULES = "${pkgs.gnome.gvfs}/lib/gio/modules";
  };
}
