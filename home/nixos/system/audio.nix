{pkgs, ...}: {
  systemd.user.services.setup-audio-routing = {
    Unit = {
      Description = "Set up custom PipeWire audio routing for Symphony Desktop";
      # Ensures this runs after the user's PipeWire socket is ready
      After = ["pipewire.socket"];
      Wants = ["pipewire.socket"];
    };

    Service = {
      # This service is a one-shot script
      Type = "oneshot";
      ExecStart = ''
        ${pkgs.pipewire}/bin/pw-link \
          "Main-Output-Proxy:monitor_FL" \
          "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX0"

        ${pkgs.pipewire}/bin/pw-link \
          "Main-Output-Proxy:monitor_FR" \
          "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX1"
      '';
    };

    Install = {
      # This makes the service start automatically when you log in
      WantedBy = ["default.target"];
    };
  };
}
