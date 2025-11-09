{ stdenvNoCC, lib }:

stdenvNoCC.mkDerivation {
  pname = "scientific-theme";
  version = "0.1.0";

  src = lib.cleanSource ./.;

  installPhase = ''
    mkdir -p $out/share/themes/Scientific
    cp -r ${./scientific}/* $out/share/themes/Scientific/
  '';

  meta = with lib; {
    description = "A scientific theme for GTK.";
    license = licenses.mit; # Assuming MIT, update if needed
    platforms = platforms.all;
  };
}
