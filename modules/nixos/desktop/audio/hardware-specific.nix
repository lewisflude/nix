_: {
  # Hardware-specific audio configuration
  services = {
    pipewire.extraConfig.pipewire = {
      # Apogee Symphony Desktop specific configuration
      "20-playbook-split.conf" = {
        "context.modules" = [
          {
            name = "libpipewire-module-loopback";
            args = {
              "node.description" = "Speakers";
              "capture.props" = {
                "node.name" = "Speakers";
                "media.class" = "Audio/Sink";
                "audio.position" = [ "FL" "FR" ];
              };
              "playback.props" = {
                "node.name" = "playback.Speakers";
                "audio.position" = [ "AUX0" "AUX1" ];
                "target.object" = "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0";
                "stream.dont-remix" = true;
                "node.passive" = true;
              };
            };
          }
          {
            name = "libpipewire-module-adapter";
            args = {
              "factory.name" = "support.null-audio-sink";
              "node.name" = "game-audio-source";
              "node.description" = "Game Audio Source";
              "media.class" = "Audio/Source";
              "audio.position" = [ "FL" "FR" ];
            };
          }
        ];
      };
    };

    # Apogee Symphony Desktop USB permissions
    udev.extraRules = ''
      # Apogee Symphony Desktop (USB Vendor ID: 0c60, Product ID: 002a)
      SUBSYSTEM=="usb", ATTRS{idVendor}=="0c60", ATTRS{idProduct}=="002a", TAG+="uaccess", TAG+="udev-acl"
      KERNEL=="hw:*", SUBSYSTEM=="sound", ATTRS{idVendor}=="0c60", ATTRS{idProduct}=="002a", TAG+="uaccess", GROUP="audio", MODE="0660"
    '';
  };
}
