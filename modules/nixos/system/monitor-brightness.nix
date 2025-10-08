{ pkgs
, username
, ...
}:
let
  restoreBrightness = pkgs.writeShellScript "restore-external-brightness" ''
    #!/usr/bin/env bash
    sleep 2
    CACHE_FILE="/home/${username}/.config/niri/last_brightness"
    if [ -f "$CACHE_FILE" ]; then
      value=$(cat "$CACHE_FILE")
      ${pkgs.ddcutil}/bin/ddcutil setvcp 10 "$value" --display 1 --brief >/dev/null 2>&1
    fi
  '';
in
{
  environment.systemPackages = with pkgs; [ ddcutil ];
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card0-DP-1", ACTION=="change", RUN+="${restoreBrightness}"
  '';
}
