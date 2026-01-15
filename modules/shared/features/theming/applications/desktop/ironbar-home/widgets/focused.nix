{
  pkgs,
  ...
}:
{
  type = "script";
  class = "label focused";
  mode = "watch"; # Stream mode: event-driven, not polling

  # Direct Niri IPC: frame-accurate updates (<16ms latency)
  # CRITICAL: Query initial state BEFORE event-stream to avoid blank bar on boot
  cmd = ''
    # 1. Get Initial State immediately (cold start fix)
    ${pkgs.niri}/bin/niri msg --json focused-window | ${pkgs.jq}/bin/jq -r '.title // "Desktop"'

    # 2. Then listen for changes
    ${pkgs.niri}/bin/niri msg --json event-stream | ${pkgs.jq}/bin/jq --unbuffered -r '
      select(.WindowFocusChanged != null) 
      | .WindowFocusChanged.title // "Desktop"
    '
  '';

  truncate = {
    mode = "end";
    max_length = 50;
  };
}
