{
  pkgs,
  lib,
  cursorInfo,
  cursorVersion,
}: let
  inherit
    (pkgs)
    appimageTools
    fetchurl
    makeDesktopItem
    makeWrapper
    ;

  pname = "cursor";

  src = fetchurl {
    inherit (cursorInfo.linux) url;
    inherit (cursorInfo.linux) sha256; # SRI
  };

  # Extract only for assets (icons etc.)
  contents = appimageTools.extract {
    inherit pname src;
    version = cursorVersion;
  };

  # Only actual runtime libs that the ELF loader will search
  runtimeLibs = with pkgs; [
    # GL / windowing / input
    libglvnd
    vulkan-loader
    libdrm
    wayland
    libxkbcommon
    xorg.libX11
    xorg.libXext
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
    xorg.libXdamage
    xorg.libXcomposite
    xorg.libXfixes
    xorg.libXrender
    xorg.libXxf86vm
    xorg.libxcb
    xorg.libxkbfile

    # Audio
    alsa-lib
    pipewire
    libpulseaudio

    # Crypto / networking / printing / ids
    nss
    nspr
    libkrb5
    cups
    libuuid

    # Secret service
    libsecret
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

    # Build dependencies
    nativeBuildInputs = [makeWrapper];

    # Libraries only; wrapType2 sets LD_LIBRARY_PATH to these
    extraPkgs = _pkgs: runtimeLibs;

    extraInstallCommands = ''
      # Install our clean desktop file
      install -Dm644 ${desktopItem}/share/applications/cursor.desktop \
        "$out/share/applications/cursor.desktop"

      # Icons: copy every available hicolor size from the AppImage payload
      if [ -d "${contents}/usr/share/icons/hicolor" ]; then
        mkdir -p "$out/share/icons"
        cp -r "${contents}/usr/share/icons/hicolor" "$out/share/icons/"
      fi

      # Set up wrapper script environment for Wayland support
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
      sourceProvenance = with sourceTypes; [binaryNativeCode];
    };
  }
