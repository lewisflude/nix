{ stdenvNoCC, lib }:

stdenvNoCC.mkDerivation {
  pname = "signal-theme";
  version = "0.1.0";

  src = lib.cleanSource ./.;

  installPhase = ''
    mkdir -p $out/share/themes/Signal
    cp -r ${./scientific}/* $out/share/themes/Signal/
  '';

  meta = with lib; {
    description = "Signal theme for GTK: Perception, engineered.";
    license = licenses.mit; # Assuming MIT, update if needed
    platforms = platforms.all;
  };
}
