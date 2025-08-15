{
  pkgs,
  cursorInfo,
  cursorVersion,
}: let
  inherit
    (pkgs)
    stdenvNoCC
    undmg
    lib
    ;
  pname = "cursor";
in
  stdenvNoCC.mkDerivation {
    inherit pname;
    version = cursorVersion;
    nativeBuildInputs = [undmg];
    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/Applications
      undmg "$src"
      cp -R "Cursor.app" "$out/Applications/Cursor.app"
    '';

    meta = with lib; {
      description = "Cursor — AI-first code editor";
      homepage = "https://www.cursor.com/";
      license = licenses.unfree;
      platforms = platforms.darwin;
    };
  }
