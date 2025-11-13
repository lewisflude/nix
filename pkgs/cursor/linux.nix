{
  pkgs,
  lib,
  cursorInfo,
  cursorVersion,
}:
let
  inherit (pkgs)
    appimageTools
    fetchurl
    makeDesktopItem
    makeWrapper
    ;
  pname = "cursor";
  src = fetchurl {
    inherit (cursorInfo.linux) url;
    inherit (cursorInfo.linux) sha256;
  };
  contents = appimageTools.extract {
    inherit pname src;
    version = cursorVersion;
  };
  runtimeLibs = [
    pkgs.libglvnd
    pkgs.vulkan-loader
    pkgs.libdrm
    pkgs.wayland
    pkgs.libxkbcommon
    pkgs.xorg.libX11
    pkgs.xorg.libXext
    pkgs.xorg.libXcursor
    pkgs.xorg.libXi
    pkgs.xorg.libXrandr
    pkgs.xorg.libXdamage
    pkgs.xorg.libXcomposite
    pkgs.xorg.libXfixes
    pkgs.xorg.libXrender
    pkgs.xorg.libXxf86vm
    pkgs.xorg.libxcb
    pkgs.xorg.libxkbfile
    pkgs.alsa-lib
    pkgs.pipewire
    pkgs.libpulseaudio
    pkgs.nss
    pkgs.nspr
    pkgs.libkrb5
    pkgs.cups
    pkgs.libuuid
    pkgs.libsecret
  ];
  desktopItem = makeDesktopItem {
    name = "cursor";
    desktopName = "Cursor";
    genericName = "Code Editor";
    comment = "Cursor — AI-first code editor";
    exec = "cursor %F";
    icon = "cursor";
    categories = [
      "Development"
      "IDE"
    ];
    startupWMClass = "cursor";
    terminal = false;
    type = "Application";
    mimeTypes = [
      "text/plain"
      "text/x-csrc"
      "text/x-chdr"
      "text/x-python"
      "text/x-shellscript"
    ];
  };
in
appimageTools.wrapType2 rec {
  inherit pname src;
  version = cursorVersion;
  nativeBuildInputs = [ makeWrapper ];
  extraPkgs = _pkgs: runtimeLibs;
  extraInstallCommands = ''
    install -Dm644 ${desktopItem}/share/applications/cursor.desktop \
      "$out/share/applications/cursor.desktop"
    if [ -d "${contents}/usr/share/icons/hicolor" ]; then
      mkdir -p "$out/share/icons"
      cp -r "${contents}/usr/share/icons/hicolor" "$out/share/icons/"
    fi
    wrapProgram "$out/bin/${pname}" \
      --set NIXOS_OZONE_WL 1 \
      --set ELECTRON_OZONE_PLATFORM_HINT "auto" \
      --set GTK_USE_PORTAL 1 \
      --add-flags "--ozone-platform-hint=auto"
  '';
  meta = with lib; {
    description = "Cursor — AI-first code editor (AppImage wrapped for Nix/NixOS)";
    homepage = "https://www.cursor.com/";
    license = licenses.unfree;
    platforms = platforms.linux;
    mainProgram = "cursor";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
