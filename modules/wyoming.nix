# Wyoming Voice Services Module - Dendritic Pattern
# Local speech-to-text (faster-whisper) and text-to-speech (piper) for Home Assistant Voice
# Usage: Import flake.modules.nixos.wyoming in host definition
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.wyoming = _: {
    # Speech-to-Text: faster-whisper via Wyoming protocol
    services.wyoming.faster-whisper.servers.assist = {
      enable = true;
      model = "distil-medium.en";
      uri = "tcp://127.0.0.1:${toString constants.ports.services.wyoming.whisper}";
      language = "en";
    };

    # Text-to-Speech: piper via Wyoming protocol
    services.wyoming.piper.servers.assist = {
      enable = true;
      uri = "tcp://127.0.0.1:${toString constants.ports.services.wyoming.piper}";
      voice = "en_GB-southern_english_female-low";
    };

    # No firewall rules needed — services listen on localhost only
  };
}
