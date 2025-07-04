{ config, pkgs, ... }:

let
  home-llm = pkgs.callPackage ./home-assistant/custom-components/home-llm.nix { inherit pkgs; };
in
{
  environment.systemPackages = with pkgs; [
    gcc
    libgcc
    gnumake
    cmake
    extra-cmake-modules

  ];

  sops.templates."hass-secrets.yaml" = {
    content = ''
      latitude: ${config.sops.placeholder.LATITUDE}
      longitude: ${config.sops.placeholder.LONGITUDE}
      base_url: ${config.sops.placeholder.HOME_ASSISTANT_BASE_URL}
    '';
    owner = "hass";
    group = "hass";
    mode = "0400";
  };

  services.home-assistant = {
    enable = true;
    configDir = "/var/lib/hass";

    blueprints = {
      script = [
        (pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/music-assistant/voice-support/main/llm-script-blueprint/llm_voice_script.yaml";
          sha256 = "sha256-qu+dQWBke5hGJL8+FTj0ghxeao4LjAPFMIckLXnn3eg=";
        })
      ];
    };
    extraComponents = [
      # Components required to complete the onboarding
      "analytics"
      "google_translate"
      "met"
      "radio_browser"
      "shopping_list"
      "music_assistant"
      "default_config"
      "lovelace"
      "mqtt"
      "esphome"
      "denonavr"
      "apple_tv"
      "ollama"
      "ipp"
      "mjpeg"
      "mpd"
      "snapcast"
      "spotify"
      "media_player"
      "vacuum"
      "weather"
      "prusalink"
      "upnp"
      "wled"
      "zha"

      # Recommended for fast zlib compression
      # https://www.home-assistant.io/integrations/isal
      "isal"
    ];
    customComponents = with pkgs; [
      home-assistant-custom-components.localtuya
      home-llm

    ];
    openFirewall = true;

    config = {
      lovelace.mode = "yaml";
      homeassistant = {
        latitude = "!secret latitude";
        longitude = "!secret longitude";
        elevation = 0;
        unit_system = "metric";
        time_zone = "Europe/London";
      };
      script = [
        {
          llm_script_for_music_assistant_voice_requests = {
            alias = "LLM Script for Music Assistant voice requests";
            use_blueprint = {
              path = "llm_voice_script.yaml";
              input = {
                default_player = "media_player.office";
              };
            };
          };
        }
      ];
      http = {
        base_url = "!secret base_url";
        server_host = [ "0.0.0.0" ];
        server_port = 8123;
        use_x_forwarded_for = true;
        trusted_proxies = [ "192.168.1.0/24" ];
      };
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };
    };
  };

  systemd.services.hass-secrets-link = {
    description = "Link Home Assistant secrets file";
    wantedBy = [ "home-assistant.service" ];
    before = [ "home-assistant.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "/run/current-system/sw/bin/ln -sf ${
        config.sops.templates."hass-secrets.yaml".path
      } /var/lib/hass/secrets.yaml";
      User = "hass";
      Group = "hass";
    };
  };

  networking.firewall.allowedTCPPorts = [ 8123 ];
}
