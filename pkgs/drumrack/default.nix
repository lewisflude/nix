# drumrack — generate Ableton Drum Rack .adg files from samples.
#
# Engine lives in drumrack.py (stdlib Python). The Sewer Drums template is
# vendored at sewer.adg; the wrapper pins its store path via DRUMRACK_TEMPLATE
# so the script always finds it.
{
  lib,
  stdenvNoCC,
  python3,
  makeWrapper,
}:
stdenvNoCC.mkDerivation {
  pname = "drumrack";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./drumrack.py
      ./sewer.adg
    ];
  };

  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 drumrack.py $out/share/drumrack/drumrack.py
    install -Dm644 sewer.adg   $out/share/drumrack/sewer.adg

    makeWrapper ${python3}/bin/python3 $out/bin/drumrack \
      --add-flags "$out/share/drumrack/drumrack.py" \
      --set DRUMRACK_TEMPLATE "$out/share/drumrack/sewer.adg"

    runHook postInstall
  '';

  meta = {
    description = "Generate Ableton Drum Rack .adg files from samples";
    mainProgram = "drumrack";
    platforms = lib.platforms.all;
    license = lib.licenses.mit;
  };
}
