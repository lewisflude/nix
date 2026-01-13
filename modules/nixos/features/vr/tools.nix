# VR Tools and Packages Configuration
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.host.features.vr;
in
lib.mkIf cfg.enable {
  # VR user applications and tools
  environment.systemPackages =
    # SideQuest for Quest device sideloading
    # Wrapped with compiled GTK schemas to fix file chooser crashes
    lib.optionals cfg.sidequest [
      (pkgs.runCommand "sidequest-with-gtk"
        {
          nativeBuildInputs = [
            pkgs.makeWrapper
            pkgs.glib
          ];
          inherit (pkgs.sidequest) meta;
        }
        ''
          mkdir -p $out/bin $out/share/gsettings-schemas/sidequest-with-gtk/glib-2.0/schemas

          # Copy all schema files
          cp ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/*/glib-2.0/schemas/*.xml \
             $out/share/gsettings-schemas/sidequest-with-gtk/glib-2.0/schemas/ 2>/dev/null || true
          cp ${pkgs.gtk3}/share/gsettings-schemas/*/glib-2.0/schemas/*.xml \
             $out/share/gsettings-schemas/sidequest-with-gtk/glib-2.0/schemas/ 2>/dev/null || true

          # Compile the schemas
          glib-compile-schemas $out/share/gsettings-schemas/sidequest-with-gtk/glib-2.0/schemas

          # Create wrapper
          makeWrapper ${pkgs.sidequest}/bin/sidequest $out/bin/sidequest \
            --prefix XDG_DATA_DIRS : "$out/share/gsettings-schemas/sidequest-with-gtk"
        ''
      )
    ]
    # Quest 3 Core Tooling (nixpkgs-xr packages)
    # xrizer: Modern SteamVR->OpenXR translation (replaces OpenComposite)
    # Use as Steam launch option: xrizer %command%
    ++ [ pkgs.xrizer ]
    # Resonite Tools
    # resolute: Mod manager for Resonite
    # oscavmgr: Face/Eye/Avatar tracking data manager (OSC protocol)
    ++ [
      pkgs.resolute
      pkgs.oscavmgr
    ]
    # Note: proton-ge-rtsp-bin is not added to systemPackages as it's a single binary
    # If needed for VRChat/Resonite video streams, install it as a Steam compatibility tool
    # Advanced VR Tools (nixpkgs-xr)
    # kaon: UEVR manager for flat-to-VR game injection
    # vapor: Lightweight VR home/launcher
    # xrbinder: Controller remapping utility
    # lovr: Lua-based VR development engine
    ++ [
      pkgs.kaon
      pkgs.vapor
      pkgs.xrbinder
      pkgs.lovr
    ]
    # Legacy OpenComposite support (optional, prefer xrizer)
    # OpenComposite - OpenVR to OpenXR translation layer
    # Note: xrizer is the modern replacement and should be preferred
    ++ lib.optionals cfg.opencomposite [ pkgs.opencomposite ];
}
