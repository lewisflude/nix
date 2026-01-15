{
  stdenvNoCC,
  lib,
  sassc,
}:

stdenvNoCC.mkDerivation {
  pname = "signal-theme";
  version = "0.1.0";

  src = lib.cleanSource ./signal-theme-src;

  nativeBuildInputs = [ sassc ];

  buildPhase = ''
    # Compile GTK 3
    mkdir -p gtk-3.0
    sassc -M -t expanded src/gtk-3.0/gtk.scss gtk-3.0/gtk.css

    # Compile GTK 4
    mkdir -p gtk-4.0
    sassc -M -t expanded src/gtk-4.0/gtk.scss gtk-4.0/gtk.css
  '';

  installPhase = ''
        mkdir -p $out/share/themes/Signal

        # Copy GTK 3 files
        mkdir -p $out/share/themes/Signal/gtk-3.0
        cp gtk-3.0/gtk.css $out/share/themes/Signal/gtk-3.0/

        # Copy GTK 4 files
        mkdir -p $out/share/themes/Signal/gtk-4.0
        cp gtk-4.0/gtk.css $out/share/themes/Signal/gtk-4.0/

        # Create index.theme file for theme recognition
        cat > $out/share/themes/Signal/index.theme << EOF
    [Desktop Entry]
    Type=X-GNOME-Metatheme
    Name=Signal
    Comment=Signal: Perception, engineered.
    Encoding=UTF-8

    [X-GNOME-Metatheme]
    GtkTheme=Signal
    MetacityTheme=Signal
    IconTheme=Adwaita
    CursorTheme=Adwaita
    ButtonLayout=close,minimize,maximize:menu
    EOF
  '';

  meta = {
    description = "Signal theme for GTK: Perception, engineered.";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
