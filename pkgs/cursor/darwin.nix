{
  pkgs,
  cursorInfo,
  cursorVersion,
}:
let
  inherit (pkgs)
    stdenvNoCC
    undmg
    lib
    fetchurl
    ;
  pname = "cursor";
  darwinInfo = cursorInfo.darwin;
  src = fetchurl {
    inherit (darwinInfo) url sha256;
  };
in
stdenvNoCC.mkDerivation {
  inherit pname src;
  version = cursorVersion;
  nativeBuildInputs = [ undmg ];
  dontUnpack = true;
  installPhase = ''
    set -euo pipefail
    mkdir -p "$out/Applications"
    undmg "$src"
    selected=""
    for candidate in "./Cursor.app" .*/Cursor.app; do
      if [ -d "$candidate" ]; then
        selected="$candidate"
        break
      fi
    done
    if [ -z "$selected" ]; then
      mapfile -d $'\0' appPaths < <(
        find . -maxdepth 3 -type d -name "Cursor.app" \
          -not -path "*/Contents/Frameworks/*" -print0
      )
      if [ "''${
        selected="''${appPaths[0]}"
      elif [ "''${
        echo "error: no Cursor.app found after undmg"
        exit 1
      else
        echo "error: multiple candidates for Cursor.app (after filtering):"
        printf '  %s\n' "''${appPaths[@]}"
        exit 1
      fi
    fi
    appPath="$selected"
    appName="$(basename "$appPath")"
    echo "Found app: $appName -> $appPath"
    cp -R "$appPath" "$out/Applications/$appName"
    chmod -R u+rwX,go+rX "$out/Applications/$appName"
  '';
  meta = with lib; {
    description = "Cursor — AI-first code editor (macOS bundle)";
    homepage = "https://www.cursor.com/";
    license = licenses.unfree;
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    mainProgram = "Cursor";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
