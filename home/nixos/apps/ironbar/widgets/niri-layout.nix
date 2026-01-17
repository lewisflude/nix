{
  pkgs,
  ...
}:
{
  type = "script";
  class = "niri-layout";
  mode = "watch"; # Stream mode: event-driven, not polling
  format = "{} ";

  # Listen to Niri event stream, update only when layout changes
  cmd = ''
    # 1. Get initial state (cold start fix)
    ${pkgs.niri}/bin/niri msg --json focused-window 2>/dev/null | ${pkgs.jq}/bin/jq -r '
      if .is_fullscreen then "󰊓"
      elif .is_maximized then "󰹑"
      elif .is_floating then "󰖲"
      else if .column_width == 1.0 then "󰖯" else "󰕰" end
      end
    ' || echo "󰕰"

    # 2. Stream future changes
    ${pkgs.niri}/bin/niri msg --json event-stream | ${pkgs.jq}/bin/jq --unbuffered -r '
      select(.WindowFocusChanged != null or .WindowOpenedOrChanged != null)
      | (.WindowOpenedOrChanged // .WindowFocusChanged)
      | if .is_fullscreen then "󰊓"
        elif .is_maximized then "󰹑"
        elif .is_floating then "󰖲"
        else if .column_width == 1.0 then "󰖯" else "󰕰" end
        end
    ' 2>/dev/null || echo "󰕰"
  '';

  tooltip = "Window Layout Mode";
}
