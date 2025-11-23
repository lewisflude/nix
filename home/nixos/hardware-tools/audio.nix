{ pkgs, ... }:
{
  home.packages = [
    pkgs.pwvucontrol
    pkgs.pulsemixer
    pkgs.pamixer
    pkgs.playerctl
  ];
  systemd.user.services.setup-audio-routing = {
    Unit = {
      Description = "Set up custom PipeWire audio routing for Symphony Desktop";
      After = [
        "pipewire.service"
        "wireplumber.service"
        "apogee-speakers-loopback.service"
      ];
      Wants = [
        "pipewire.service"
        "wireplumber.service"
        "apogee-speakers-loopback.service"
      ];
    };
    Service = {
      Type = "oneshot";
      # Wait a moment for PipeWire nodes to be fully registered
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
      ExecStart =
        let
          script = pkgs.writeShellScript "setup-audio-routing" ''
            set -euo pipefail

            # Wait for Speakers node to be available (max 10 seconds)
            MAX_WAIT=10
            ELAPSED=0
            while ! ${pkgs.pipewire}/bin/pw-cli list-objects 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "node.name.*Speakers"; do
              if [ $ELAPSED -ge $MAX_WAIT ]; then
                echo "ERROR: Speakers node not found after $MAX_WAIT seconds" >&2
                exit 1
              fi
              sleep 0.5
              ELAPSED=$((ELAPSED + 1))
            done

            # Link Speakers monitor ports to Apogee AUX outputs
            # These links route audio from the Speakers virtual sink to the Apogee hardware
            ${pkgs.pipewire}/bin/pw-link \
              "Speakers:monitor_FL" \
              "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX0" || true
            ${pkgs.pipewire}/bin/pw-link \
              "Speakers:monitor_FR" \
              "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX1" || true
          '';
        in
        "${script}";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
