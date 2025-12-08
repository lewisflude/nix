{ pkgs, ... }:
{
  # NixOS-specific audio utilities for PipeWire/PulseAudio

  home.packages = [
    # PipeWire control and utilities
    pkgs.pwvucontrol # Modern PipeWire volume control (GTK4)
    pkgs.helvum # PipeWire patchbay for audio routing

    # PulseAudio compatibility tools
    pkgs.pavucontrol # PulseAudio volume control (works with PipeWire)
    pkgs.paprefs # PulseAudio preferences

    # Media control
    pkgs.playerctl # MPRIS media player controller

    # Audio utilities
    pkgs.easyeffects # Audio effects for PipeWire
    pkgs.qpwgraph # Qt-based PipeWire graph manager
  ];

  # Playerctl configuration for media key bindings
  services.playerctld.enable = true;

  # Auto-link Proton Stereo Bridge monitor to loopback
  # This ensures game audio routes from the bridge → loopback → Apogee speakers
  systemd.user.services.proton-bridge-autolink = {
    Unit = {
      Description = "Auto-link Proton Stereo Bridge to loopback";
      After = [
        "pipewire.service"
        "pipewire-pulse.service"
        "wireplumber.service"
      ];
      Wants = [
        "pipewire.service"
        "wireplumber.service"
      ];
    };

    Service = {
      Type = "oneshot";
      RemainAfterExit = false;
      # Wait for nodes to be available, then create links
      ExecStart = pkgs.writeShellScript "link-proton-bridge" ''
        # Wait up to 5 seconds for both nodes to exist
        for i in {1..10}; do
          if ${pkgs.pipewire}/bin/pw-cli ls Node | ${pkgs.gnugrep}/bin/grep -q "proton_stereo_bridge" && \
             ${pkgs.pipewire}/bin/pw-cli ls Node | ${pkgs.gnugrep}/bin/grep -q "proton_bridge_loopback.capture"; then
            # Disconnect any existing mic connections to loopback
            ${pkgs.pipewire}/bin/pw-link -d \
              alsa_input.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.multichannel-input:capture_AUX0 \
              proton_bridge_loopback.capture:input_FL 2>/dev/null || true
            ${pkgs.pipewire}/bin/pw-link -d \
              alsa_input.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.multichannel-input:capture_AUX1 \
              proton_bridge_loopback.capture:input_FR 2>/dev/null || true

            # Link bridge monitor to loopback
            ${pkgs.pipewire}/bin/pw-link \
              proton_stereo_bridge:monitor_FL \
              proton_bridge_loopback.capture:input_FL
            ${pkgs.pipewire}/bin/pw-link \
              proton_stereo_bridge:monitor_FR \
              proton_bridge_loopback.capture:input_FR

            exit 0
          fi
          ${pkgs.coreutils}/bin/sleep 0.5
        done
        echo "Timeout waiting for nodes to appear"
        exit 1
      '';
    };

    Install = {
      WantedBy = [ "pipewire.service" ];
    };
  };
}
