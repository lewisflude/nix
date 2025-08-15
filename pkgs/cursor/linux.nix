{
  pkgs,
  cursorInfo,
  cursorVersion,
}:
let
  inherit (pkgs) appimageTools fetchurl lib;
  pname = "cursor";
  src = fetchurl {
    url = cursorInfo.linux.url;
    sha256 = cursorInfo.linux.sha256; # SRI
  };
  contents = appimageTools.extract {
    inherit pname src;
    version = cursorVersion;
  };
in
appimageTools.wrapType2 {
  inherit pname src;
  version = cursorVersion;

  extraInstallCommands = ''
    # Desktop file: prefer upstream if present; otherwise fallback
    if [ -f "${contents}/cursor.desktop" ]; then
      install -Dm444 "${contents}/cursor.desktop" "$out/share/applications/cursor.desktop"
    else
      install -Dm444 ${./cursor.desktop} "$out/share/applications/cursor.desktop"
    fi
    substituteInPlace "$out/share/applications/cursor.desktop" \
      --replace "Exec=AppRun" "Exec=cursor" \
      --replace "Icon=cursor" "Icon=cursor"

    # Icons from AppImage payload if available
    for size in 16 24 32 48 64 128 256 512; do
      iconPath="${contents}/usr/share/icons/hicolor/$${size}x$${size}/apps/cursor.png"
      if [ -f "$iconPath" ]; then
        install -Dm444 "$iconPath" "$out/share/icons/hicolor/$${size}x$${size}/apps/cursor.png"
      fi
    done
  '';

  meta = with lib; {
    description = "Cursor — AI-first code editor";
    homepage = "https://www.cursor.com/";
    license = licenses.unfree; # Cursor is not free software
    platforms = platforms.linux;
    mainProgram = "cursor";
  };
}
