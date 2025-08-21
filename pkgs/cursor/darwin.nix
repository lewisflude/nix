{
  pkgs,
  cursorInfo, # attrset with .darwin.aarch64.url/.sha256 and .darwin.x86_64.url/.sha256 (or a single .darwin)
  cursorVersion,
}: let
  inherit
    (pkgs)
    stdenvNoCC
    undmg
    lib
    fetchurl
    ;
  pname = "cursor";

  # Select the per-arch source if available; otherwise fall back to a flat .darwin
  host = stdenvNoCC.hostPlatform;
  darwinInfo =
    if cursorInfo ? darwin && cursorInfo.darwin ? "${host.arch}"
    then cursorInfo.darwin.${host.arch}
    else cursorInfo.darwin;

  src = fetchurl {
    inherit (darwinInfo) url sha256; # SRI hash
  };
in
  stdenvNoCC.mkDerivation {
    inherit pname src;
    version = cursorVersion;

    nativeBuildInputs = [undmg];
    dontUnpack = true;

    installPhase = ''
      set -euo pipefail

      mkdir -p "$out/Applications"

      # Extract the DMG contents into the current working directory
      undmg "$src"

      # Find exactly one .app bundle (handle nested layouts)
      mapfile -d $'\0' appPaths < <(find . -maxdepth 4 -type d -name "*.app" -print0)
      if [ "''${#appPaths[@]}" -eq 0 ]; then
        echo "error: no .app bundle found after undmg"
        exit 1
      elif [ "''${#appPaths[@]}" -gt 1 ]; then
        echo "error: multiple .app bundles found:"
        printf '  %s\n' "''${appPaths[@]}"
        exit 1
      fi

      appPath="''${appPaths[0]}"
      appName="$(basename "$appPath")"
      echo "Found app: $appName"

      # Copy the bundle into $out/Applications
      cp -R "$appPath" "$out/Applications/$appName"

      # Optional: tighten permissions to avoid stray write bits
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
      # The main executable lives inside the app bundle; keeping this for UX:
      mainProgram = "Cursor";
      sourceProvenance = with sourceTypes; [binaryNativeCode];
    };
  }
