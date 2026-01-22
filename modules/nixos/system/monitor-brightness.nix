{
  pkgs,
  username,
  ...
}:
let
  restoreBrightness = pkgs.writeShellScript "restore-external-brightness" ''
    sleep 2
    CACHE_FILE="/home/${username}/.config/niri/last_brightness"
    if [ -f "$CACHE_FILE" ]; then
      value=$(cat "$CACHE_FILE")
      ${pkgs.ddcutil}/bin/ddcutil setvcp 10 "$value" --display 1 --brief >/dev/null 2>&1
    fi
  '';
in
{
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card1-DP-3", ACTION=="change", RUN+="${restoreBrightness}"
  '';
}
