# VR Module - WiVRn + xrizer for Quest headsets
# References:
# - https://lvra.gitlab.io/docs/distros/nixos/
_: {
  flake.modules.nixos.vr =
    { pkgs, ... }:
    {
      # xrizer OpenVR-on-OpenXR layer for Steam/Proton VR games
      # Non-VR games that break with VR detection need per-game launch options:
      #   PROTON_VR_RUNTIME="" %command%
      programs.steam.extraPackages = [ pkgs.xrizer ];

      services.wivrn = {
        enable = true;
        openFirewall = true;
        autoStart = true;
        highPriority = true; # CAP_SYS_NICE for async reprojection

        steam.importOXRRuntimes = true; # PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1

        monadoEnvironment = {
          U_PACING_COMP_MIN_TIME_MS = "5";
          IPC_EXIT_ON_DISCONNECT = "1";
          XRT_COMPOSITOR_USE_PRESENT_WAIT = "1"; # NVIDIA head tracking latency reduction
          U_PACING_COMP_TIME_FRACTION_PERCENT = "90"; # NVIDIA head tracking latency reduction
        };

        config = {
          enable = true;
          json = {
            application = [ pkgs.wayvr ];
          };
        };
      };

      # ADB for Quest headset setup/sideloading
      environment.systemPackages = [ pkgs.android-tools ];
    };

  flake.modules.homeManager.vr =
    {
      config,
      lib,
      pkgs,
      osConfig ? { },
      ...
    }:
    lib.mkIf (osConfig.services.wivrn.enable or false) {
      xdg.configFile."openvr/openvrpaths.vrpath" = {
        force = true;
        text = builtins.toJSON {
          version = 1;
          jsonid = "vrpathreg";
          external_drivers = null;
          config = [ "${config.xdg.dataHome}/Steam/config" ];
          log = [ "${config.xdg.dataHome}/Steam/logs" ];
          runtime = [ "${pkgs.xrizer}/lib/xrizer" ];
        };
      };

      # Auto-switch default audio sink/source when WiVRn headset connects.
      # Watches PipeWire for wivrn.sink appearing/disappearing and calls
      # pactl to switch between WiVRn and Main-Output/Main-Input.
      # Node names from WiVRn source: wivrn.sink / wivrn.source
      systemd.user.services.wivrn-audio-switch = {
        Unit = {
          Description = "Auto-switch audio to WiVRn headset";
          After = [ "pipewire-pulse.service" ];
          Requires = [ "pipewire-pulse.service" ];
        };
        Service = {
          ExecStart = toString (
            pkgs.writeShellScript "wivrn-audio-switch" ''
              pactl=${pkgs.pulseaudio}/bin/pactl
              grep=${pkgs.gnugrep}/bin/grep
              state_file=$(mktemp)
              echo "" > "$state_file"
              trap 'rm -f "$state_file"' EXIT
              $pactl subscribe | $grep --line-buffered "'new'\|'remove'" | while read -r _; do
                state=$(cat "$state_file")
                if $pactl list sinks short 2>/dev/null | $grep -q "wivrn.sink"; then
                  if [ "$state" != "wivrn" ]; then
                    $pactl set-default-sink wivrn.sink
                    $pactl set-default-source wivrn.source 2>/dev/null
                    echo "wivrn" > "$state_file"
                  fi
                else
                  if [ "$state" != "main" ]; then
                    $pactl set-default-sink Main-Output
                    $pactl set-default-source Main-Input
                    echo "main" > "$state_file"
                  fi
                fi
              done
            ''
          );
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "pipewire-pulse.service" ];
      };
    };
}
