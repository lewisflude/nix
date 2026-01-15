# Immersed VR Desktop Productivity
# Workarounds: XWayland (Niri wl_output bug), VAAPI disabled (NVIDIA), DPI scaling
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.host.features.vr;
  constants = import ../../../../lib/constants.nix;
in
lib.mkIf (cfg.enable && cfg.immersed.enable) {
  programs.immersed = {
    enable = true;
    # Wrapper for Niri + NVIDIA compatibility
    # - XWayland: Immersed has wl_output protocol bug on Niri
    # - VAAPI disabled: NVIDIA uses NVDEC/NVENC, not VAAPI
    # - DPI scaling: 1.25x via GDK_SCALE=2 + GDK_DPI_SCALE=0.625
    package = pkgs.symlinkJoin {
      name = "immersed-xwayland-nvidia";
      paths = [ pkgs.immersed ]; # Uses overlay version
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/immersed \
          --unset WAYLAND_DISPLAY \
          --set XDG_SESSION_TYPE "x11" \
          --set LIBVA_DRIVER_NAME "none" \
          --set GDK_SCALE "2" \
          --set GDK_DPI_SCALE "0.625" \
          --set GTK_USE_PORTAL "1" \
          --add-flags "--force-device-scale-factor=1.25" \
          --prefix XDG_DATA_DIRS : "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}" \
          --prefix XDG_DATA_DIRS : "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}" \
          --prefix LD_LIBRARY_PATH : "${
            lib.makeLibraryPath [
              pkgs.webkitgtk_4_1
              pkgs.libsecret
              pkgs.glib
              pkgs.gtk3
              pkgs.libsoup_3
              pkgs.glib-networking
            ]
          }"
      '';
    };
  };

  # OAuth authentication requires keyring
  services.gnome.gnome-keyring.enable = lib.mkDefault true;
  security.pam.services.login.enableGnomeKeyring = lib.mkDefault true;

  # Firewall for PC-headset communication
  networking.firewall = lib.mkIf cfg.immersed.openFirewall {
    allowedTCPPorts = [
      constants.ports.vr.immersed.tcp.start
      (constants.ports.vr.immersed.tcp.start + 1)
      (constants.ports.vr.immersed.tcp.start + 2)
    ];
    allowedUDPPorts = [
      constants.ports.vr.immersed.udp.start
      (constants.ports.vr.immersed.udp.start + 1)
      (constants.ports.vr.immersed.udp.start + 2)
    ];
  };
}
