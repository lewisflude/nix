# Audio - Simple PipeWire configuration
# Following NixOS wiki best practices: https://wiki.nixos.org/wiki/PipeWire
{ ... }:
{
  # NixOS audio configuration
  flake.modules.nixos.audio =
    { pkgs, ... }:
    {
      # RTKit for realtime scheduling
      security.rtkit.enable = true;

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;

        wireplumber.extraConfig = {
          # Disable device suspension to prevent audio popping/delay
          "10-disable-suspend"."monitor.alsa.rules" = [
            {
              matches = [
                { "node.name" = "~alsa_input.*"; }
                { "node.name" = "~alsa_output.*"; }
              ];
              actions.update-props."session.suspend-timeout-seconds" = 0;
            }
          ];

          # Bluetooth codecs
          "10-bluez"."monitor.bluez.properties" = {
            "bluez5.enable-sbc-xq" = true;
            "bluez5.enable-msbc" = true;
            "bluez5.enable-hw-volume" = true;
            "bluez5.roles" = [ "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag" ];
          };
        };

      };
    };

  # Darwin audio (macOS uses CoreAudio natively)
  flake.modules.darwin.audio =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.ffmpeg-full
        pkgs.flac
        pkgs.lame
      ];
    };

  # Home-manager audio tools
  flake.modules.homeManager.audio =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.pwvucontrol
        pkgs.pavucontrol
        pkgs.playerctl
      ];
      services.playerctld.enable = true;
    };

  flake.modules.homeManager.audioDarwin =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.lame pkgs.flac ];
    };
}
