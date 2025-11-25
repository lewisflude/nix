{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.host.features.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # Create Speakers virtual sink for Apogee Symphony Desktop pro-audio routing
    # Using systemd service with proper ordering to prevent race conditions
    systemd.user.services.apogee-speakers-loopback = {
      description = "Apogee Symphony Speakers Loopback";
      # Must start after PipeWire/WirePlumber AND before graphical session
      after = [
        "pipewire.service"
        "wireplumber.service"
      ];
      before = [ "graphical-session.target" ];
      wants = [
        "pipewire.service"
        "wireplumber.service"
      ];
      wantedBy = [ "pipewire.service" ];
      serviceConfig = {
        Type = "simple";
        # Add small delay to ensure WirePlumber is fully ready
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 0.5";
        ExecStart = "${pkgs.pipewire}/bin/pw-loopback --capture-props='media.class=Audio/Sink node.name=Speakers node.description=\"Speakers (Default)\" audio.position=[FL,FR] media.role=Music priority.session=3000' --playback-props='node.name=playback.Speakers audio.position=[AUX0,AUX1] target.object=alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0 stream.dont-remix=true node.passive=true'";
        Restart = "on-failure";
        RestartSec = "3s";
      };
    };

    services.udev.extraRules = ''
      SUBSYSTEM=="usb", ATTRS{idVendor}=="0c60", ATTRS{idProduct}=="002a", TAG+="uaccess", TAG+="udev-acl"
      KERNEL=="hw:*", SUBSYSTEM=="sound", ATTRS{idVendor}=="0c60", ATTRS{idProduct}=="002a", TAG+="uaccess", GROUP="audio", MODE="0660"
    '';
  };
}
