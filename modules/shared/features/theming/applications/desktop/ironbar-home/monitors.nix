{
  pkgs,
  ...
}:
let
  widgets = import ./widgets/default.nix { inherit pkgs; };
in
{
  monitors = {
    "DP-3" = {
      position = "top";
      height = 44;
      layer = "top";
      exclusive_zone = true;
      popup_gap = 10;
      popup_autohide = false;
      start_hidden = false;
      anchor_to_edges = false;
      icon_theme = "Papirus";
      margin = {
        top = 8;
        bottom = 0;
        left = 0;
        right = 0;
      };
      start = widgets.start;
      center = widgets.center;
      end = widgets.end;
    };
  };
}
