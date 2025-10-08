{
  pkgs,
  cursorInfo,
  # attrset with .darwin.aarch64.url/.sha256 and .darwin.x86_64.url/.sha256 (or a single .darwin)
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
  darwinInfo = cursorInfo.darwin;

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

      # 1) Prefer shallow, canonical locations for the main app bundle
      selected=""
      for candidate in "./Cursor.app" ./*/Cursor.app ./*/*/Cursor.app; do
        if [ -d "$candidate" ]; then
          selected="$candidate"
          break
        fi
      done

      # 2) If not found, fall back to a filtered find:
      if [ -z "$selected" ]; then
        # Exclude Electron Helper apps inside Contents/Frameworks
        mapfile -d $'\0' appPaths < <(
          find . -maxdepth 3 -type d -name "Cursor.app" \
            -not -path "*/Contents/Frameworks/*" -print0
        )
        if [ "''${#appPaths[@]}" -eq 1 ]; then
          selected="''${appPaths[0]}"
        elif [ "''${#appPaths[@]}" -eq 0 ]; then
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
