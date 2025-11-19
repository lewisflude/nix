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
    # This combines split AUX channels into a standard stereo sink for games
    systemd.user.services.apogee-speakers-loopback = {
      Unit = {
        Description = "Apogee Symphony Speakers Loopback";
        After = [
          "pipewire.service"
          "wireplumber.service"
        ];
        Wants = [
          "pipewire.service"
          "wireplumber.service"
        ];
        PartOf = [ "pipewire.service" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.pipewire}/bin/pw-loopback --capture-props='media.class=Audio/Sink node.name=Speakers node.description=Speakers audio.position=[FL,FR]' --playback-props='node.name=playback.Speakers audio.position=[AUX0,AUX1] target.object=alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0 stream.dont-remix=true node.passive=true'";
        Restart = "on-failure";
        RestartSec = "3s";
      };
      Install = {
        WantedBy = [ "pipewire.service" ];
      };
    };

    services.udev.extraRules = ''
      SUBSYSTEM=="usb", ATTRS{idVendor}=="0c60", ATTRS{idProduct}=="002a", TAG+="uaccess", TAG+="udev-acl"
      KERNEL=="hw:*", SUBSYSTEM=="sound", ATTRS{idVendor}=="0c60", ATTRS{idProduct}=="002a", TAG+="uaccess", GROUP="audio", MODE="0660"
    '';
  };
}
