# Bluetooth Audio Configuration
# High-quality codecs and device priority settings
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.host.features.media.audio;
in
{
  config = mkIf cfg.enable {
    services.pipewire.wireplumber.extraConfig = {
      # Bluetooth: Enable high-quality codecs
      # Bluetooth devices get priority 200 when connected (higher than Apogee for auto-selection)
      "10-bluez"."monitor.bluez.properties" = {
        "bluez5.enable-sbc-xq" = true;
        "bluez5.enable-msbc" = true;
        "bluez5.enable-hw-volume" = true;
        "bluez5.roles" = [
          "hsp_hs"
          "hsp_ag"
          "hfp_hf"
          "hfp_ag"
        ];
        "bluez5.codecs" = [
          "sbc"
          "sbc_xq"
          "aac"
          "ldac"
          "aptx"
          "aptx_hd"
          "aptx_ll"
          "lc3"
        ];
        "bluez5.default.rate" = 48000;
        "bluez5.default.channels" = 2;
        "bluez5.a2dp.ldac.quality" = "hq";
      };

      # Set Bluetooth device priority
      # Lowered from 200 to 80 - manual device selection preferred over auto-switching
      # Prevents accidental switches when Bluetooth devices connect
      "10-bluetooth-priority"."monitor.rules" = [
        {
          matches = [ { "node.name" = "~bluez_output.*"; } ];
          actions.update-props = {
            "priority.session" = 80; # Below Apogee (100) - manual selection required
          };
        }
      ];
    };
  };
}
