{pkgs, ...}: let
  # Reuse the same Vial JSON generated on macOS by duplicating its shape here if needed.
  # If you want to source from the Darwin file, we can factor it into a shared module later.
  vialJson = (pkgs.formats.json {}).generate "mnk88-vial.json" {
    name = "MNK88";
    vendorId = 0 x4B50;
    productId = 0 x8800;
    matrix = {
      rows = 6;
      cols = 17;
    };
    lighting = {
      supported = false;
    };
    # Layout omitted here for brevity — Vial firmware embeds definitions; JSON is optional on Linux.
  };
in {
  home.packages = with pkgs; [
    vial
    via
  ];

  # Provide JSON in an XDG-friendly place (some tools may look here)
  xdg.enable = true;
  xdg.dataFile."vial/definitions/mnk88.json".source = vialJson;
}
