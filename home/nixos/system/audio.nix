{pkgs, ...}: {
  home.packages = with pkgs; [
    pwvucontrol
    pulsemixer
    pamixer
    playerctl
  ];
  systemd.user.services.setup-audio-routing = {
    Unit = {
      Description = "Set up custom PipeWire audio routing for Symphony Desktop";
      After = ["pipewire.socket"];
      Wants = ["pipewire.socket"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = let
        script = pkgs.writeShellScript "setup-audio-routing" ''
          ${pkgs.pipewire}/bin/pw-link \
            "Main-Output-Proxy:monitor_FL" \
            "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX0"
          ${pkgs.pipewire}/bin/pw-link \
            "Main-Output-Proxy:monitor_FR" \
            "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX1"
        '';
      in "${script}";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
