# GIMP with PhotoGIMP Photoshop-style keyboard shortcuts
{ inputs, ... }:
{
  flake.modules.homeManager.gimp =
    { lib, pkgs, ... }:
    let
      gimpVersion = lib.versions.majorMinor pkgs.gimp.version;
    in
    lib.mkIf pkgs.stdenv.isLinux {
      home.packages = [ pkgs.gimp-with-plugins ];

      # Symlink PhotoGIMP shortcuts — the main value of the patch.
      # Read-only is fine; GIMP only writes here if you change shortcuts in the UI.
      xdg.configFile."GIMP/${gimpVersion}/shortcutsrc" = {
        source = "${inputs.photogimp}/.config/GIMP/3.0/shortcutsrc";
        force = true;
      };
    };
}
