{ pkgs, ... }:
let

  vialJson = (pkgs.formats.json { }).generate "mnk88-vial.json" {
    name = "MNK88";
    vendorId = 19280;
    productId = 34816;
    matrix = {
      rows = 6;
      cols = 17;
    };
    lighting = {
      supported = false;
    };

  };
in
{
  home.packages = with pkgs; [
    vial
    via
  ];

  xdg.enable = true;
  xdg.dataFile."vial/definitions/mnk88.json".source = vialJson;
}
