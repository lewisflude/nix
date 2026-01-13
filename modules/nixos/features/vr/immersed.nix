# Immersed VR Desktop Productivity Configuration
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
  # Immersed VR desktop productivity application
  # Provides virtual monitors in VR for working in mixed reality
  # Use native NixOS module for Immersed
  # Wrapped to use XWayland on Niri (workaround for wl_output protocol bug)
  programs.immersed = {
    enable = true;
    # Force XWayland for compatibility with Niri compositor
    # Immersed has a bug where it binds to wl_output version 1 but doesn't
    # handle the 'done' event (opcode 2) added in version 2, causing:
    # "listener function for opcode 2 of wl_output is NULL"
    # This is fixed in Immersed on GNOME Wayland but not Niri yet.
    #
    # Also disable VAAPI (Intel/AMD video acceleration) which:
    # 1. Doesn't work on NVIDIA GPUs anyway
    # 2. Causes GStreamer gst_util_floor_log2 symbol errors
    # NVIDIA uses NVDEC/NVENC for hardware acceleration, not VAAPI
    #
    # Additional fixes for OAuth sign-in and rendering:
    # - webkit2gtk-4.1: Embedded browser for OAuth authentication
    # - libsecret: Credential storage (AppImages need system libsecret)
    # - gnome-keyring: Keyring daemon for secure credential storage
    # - LD_LIBRARY_PATH: Make system libraries available to AppImage
    #
    # Force XWayland due to wl_output protocol bug:
    # - Immersed binds to wl_output version 1 but doesn't handle the 'done' event (opcode 2)
    #   added in version 2, causing: "listener function for opcode 2 of wl_output is NULL"
    # - Fixed in Immersed on GNOME Wayland but NOT on Niri as of 2026-01-12
    # - Must use XWayland until Immersed fixes wl_output protocol handling
    #
    # DPI/Scaling fixes for XWayland with fractional scaling (1.25x):
    # - GDK_SCALE=2: GTK base scaling (2x for HiDPI)
    # - GDK_DPI_SCALE=0.625: Fine-tune to 1.25x total (2 * 0.625 = 1.25)
    # - ELECTRON_OZONE_PLATFORM_HINT: Tell Electron to use Ozone (even via XWayland)
    # - --force-device-scale-factor=1.25: Explicitly set Electron's UI scaling
    # - --enable-features=UseOzonePlatform: Enable Ozone platform layer
    # - --ozone-platform-hint=auto: Let Electron choose best platform (X11 via Ozone)
    # Alternative if above doesn't work: Use GDK_SCALE=1 + --force-device-scale-factor=1.5
    #
    # VAAPI disabled for NVIDIA compatibility:
    # - NVIDIA uses NVDEC/NVENC, not VAAPI
    # - Prevents GStreamer symbol errors
    package =
      let
        # Explicitly override Immersed to use latest version
        # The overlay should handle this, but we're being explicit here
        immersedLatest = pkgs.immersed.overrideAttrs (_: {
          version = "11.0.0-latest";
          src = pkgs.fetchurl {
            url = "https://static.immersed.com/dl/Immersed-x86_64.AppImage";
            hash = "sha256-GbckZ/WK+7/PFQvTfUwwePtufPKVwIwSPh+Bo/cG7ko=";
          };
        });
      in
      pkgs.symlinkJoin {
        name = "immersed-xwayland-nvidia";
        paths = [ immersedLatest ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/immersed \
            --unset WAYLAND_DISPLAY \
            --set ELECTRON_OZONE_PLATFORM_HINT "auto" \
            --set LIBVA_DRIVER_NAME "none" \
            --set LIBVA_DRIVERS_PATH "/nonexistent" \
            --set XDG_SESSION_TYPE "x11" \
            --set GDK_SCALE "2" \
            --set GDK_DPI_SCALE "0.625" \
            --set GTK_THEME "Adwaita:dark" \
            --set GTK_USE_PORTAL "1" \
            --add-flags "--force-device-scale-factor=1.25" \
            --add-flags "--enable-features=UseOzonePlatform" \
            --add-flags "--ozone-platform-hint=auto" \
            --prefix XDG_DATA_DIRS : "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}" \
            --prefix XDG_DATA_DIRS : "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}" \
            --prefix LD_LIBRARY_PATH : "${
              pkgs.lib.makeLibraryPath [
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

  # Ensure gnome-keyring is available for Immersed authentication
  # Immersed uses OAuth which requires secure credential storage
  services.gnome.gnome-keyring.enable = lib.mkDefault true;
  security.pam.services.login.enableGnomeKeyring = lib.mkDefault true;

  # Firewall configuration for Immersed
  # Immersed uses these ports for communication between PC and headset
  networking.firewall = lib.mkIf cfg.immersed.openFirewall {
    allowedTCPPorts = [
      constants.ports.vr.immersed.tcp.start # 5230
      (constants.ports.vr.immersed.tcp.start + 1) # 5231
      (constants.ports.vr.immersed.tcp.start + 2) # 5232
    ];
    allowedUDPPorts = [
      constants.ports.vr.immersed.udp.start # 5230
      (constants.ports.vr.immersed.udp.start + 1) # 5231
      (constants.ports.vr.immersed.udp.start + 2) # 5232
    ];
  };
}
