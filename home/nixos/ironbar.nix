{
  pkgs,
  ...
}:
{
  programs.ironbar = {
    enable = true;
    systemd = true;
    package = pkgs.ironbar;

    config = {
      monitors = {
        DP-1 = {
          anchor_to_edges = true;
          position = "top";
          height = 16;
          start = [
            { type = "clock"; }
          ];
          end = [
            {
              type = "tray";
              icon_size = 16;
            }
          ];
        };
      };
    };
  };
}
