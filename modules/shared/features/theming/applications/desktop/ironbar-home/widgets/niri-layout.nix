{
  pkgs,
  ...
}:
{
  type = "script";
  class = "niri-layout";
  mode = "poll";
  format = "{} ";
  cmd = ''
    ${pkgs.niri}/bin/niri msg focused-window | ${pkgs.jq}/bin/jq -r '
      if .is_fullscreen then "󰊓"
      elif .is_maximized then "󰹑"
      elif .is_floating then "󰖲"
      else if .column_width == 1.0 then "󰖯" else "󰕰" end
      end
    ' 2>/dev/null || echo "󰕰"
  '';
  interval = 500;
  tooltip = "Window Layout Mode";
}
