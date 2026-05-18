# Home Assistant Service Module - Dendritic Pattern
# Home automation platform with extensive integrations
# Usage: Import flake.modules.nixos.homeAssistant in host definition
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.homeAssistant =
    {
      pkgs,
      ...
    }@nixosArgs:
    let
      intentScriptYaml = ../pkgs/home-assistant/intent-scripts/intent_script.yaml;
      automationsDir = ../pkgs/home-assistant/automations;
      scriptsDir = ../pkgs/home-assistant/scripts;
      templatesDir = ../pkgs/home-assistant/templates;

      nixosConfig = nixosArgs.config;
    in
    {
      # SOPS secrets configuration
      sops.templates."hass-secrets.yaml" = {
        content = ''
          latitude: ${nixosConfig.sops.placeholder.LATITUDE}
          longitude: ${nixosConfig.sops.placeholder.LONGITUDE}
        '';
        owner = "hass";
        group = "hass";
        mode = "0400";
      };

      # Home Assistant service
      services.home-assistant = {
        enable = true;
        configDir = "/var/lib/hass";
        openFirewall = true;

        extraComponents = [
          # Core
          "analytics"
          "default_config"
          "esphome"
          "google_translate"
          "isal"
          "lovelace"
          "met"
          "music_assistant"
          "radio_browser"
          "shopping_list"
          "wyoming"

          # Device integrations
          "apple_tv"
          "brother"
          "denonavr"
          "homekit_controller"
          "hue"
          "linkplay"
          "prusalink"
          "tado"
          "unifi"
          "vacuum"
          "wled"

          # Media
          "cast"
          "media_player"
          "mjpeg"
          "spotify"

          # Utilities
          "ipp"
          "mqtt"
          "ollama"
          "upnp"
          "weather"
        ];

        customComponents = [
          pkgs.home-assistant-custom-components.localtuya
          pkgs.home-assistant-custom-components.adaptive_lighting
        ];

        config = {
          # Core Home Assistant configuration
          homeassistant = {
            name = "Home";
            latitude = "!secret latitude";
            longitude = "!secret longitude";
            elevation = 50;
            unit_system = "metric";
            time_zone = constants.defaults.timezone;
            country = "GB";
            currency = "GBP";
            internal_url = "http://localhost:${toString constants.ports.services.homeAssistant}";
            allowlist_external_dirs = [ "/var/lib/hass" ];
          };

          default_config = { };

          # HTTP configuration for reverse proxy
          http = {
            server_host = [
              "::1"
              "127.0.0.1"
            ];
            server_port = constants.ports.services.homeAssistant;
            use_x_forwarded_for = true;
            trusted_proxies = [
              "::1"
              "127.0.0.1"
            ];
          };

          frontend = {
            themes = "!include_dir_merge_named themes";
          };

          tts = [
            {
              platform = "google_translate";
              language = "en";
            }
          ];

          # Recorder - optimize database size
          recorder = {
            db_url = "sqlite:////var/lib/hass/home-assistant_v2.db";
            auto_purge = true;
            purge_keep_days = 7;
            commit_interval = 5;
            exclude = {
              domains = [
                "automation"
                "updater"
              ];
              entity_globs = [ "sensor.weather_*" ];
              entities = [ "sun.sun" ];
            };
          };

          history = {
            exclude = {
              domains = [
                "automation"
                "updater"
              ];
            };
          };

          logbook = {
            exclude = {
              domains = [ "automation" ];
            };
          };

          logger = {
            default = "info";
            logs = {
              "homeassistant.core" = "warning";
              "homeassistant.components.http" = "warning";
            };
          };

          # Intent scripts for voice assistant
          intent_script = "!include ${intentScriptYaml}";

          # Automations, scripts, and templates loaded from YAML files
          automation = "!include_dir_merge_list ${automationsDir}";
          script = "!include_dir_merge_named ${scriptsDir}";
          template = "!include_dir_merge_list ${templatesDir}";

          # Adaptive Lighting - Circadian rhythm lighting
          adaptive_lighting = [
            # Office - Productivity-optimized
            {
              name = "Office Adaptive Lighting";
              lights = [ "light.office" ];
              prefer_rgb_color = false;
              initial_transition = 1;
              transition = 45;
              interval = 90;
              min_brightness = 45;
              max_brightness = 100;
              min_color_temp = 2000;
              max_color_temp = 5500;
              sleep_brightness = 5;
              sleep_color_temp = 2000;
              sunrise_time = "07:00:00";
              sunset_time = null;
              take_over_control = true;
              detect_non_ha_changes = true;
            }

            # Living & Dining Room (open plan) - Balanced comfort
            {
              name = "Living Dining Room Adaptive Lighting";
              lights = [
                "light.living_room"
                "light.living_room_pendant"
                "light.dining_room"
                "light.dining_room_pendant"
              ];
              prefer_rgb_color = false;
              initial_transition = 1;
              transition = 60;
              interval = 90;
              min_brightness = 30;
              max_brightness = 85;
              min_color_temp = 2000;
              max_color_temp = 5000;
              sleep_brightness = 3;
              sleep_color_temp = 2000;
              sunrise_time = null;
              sunset_time = null;
              take_over_control = true;
              detect_non_ha_changes = true;
            }

            # Bedroom - Warm, relaxed
            {
              name = "Bedroom Adaptive Lighting";
              lights = [ "light.bedroom" ];
              prefer_rgb_color = false;
              initial_transition = 1;
              transition = 60;
              interval = 90;
              min_brightness = 20;
              max_brightness = 80;
              min_color_temp = 2000;
              max_color_temp = 4000;
              sleep_brightness = 1;
              sleep_color_temp = 2000;
              sunrise_time = "07:30:00";
              sunset_time = null;
              take_over_control = true;
              detect_non_ha_changes = true;
            }

            # Kitchen - Bright task lighting
            {
              name = "Kitchen Adaptive Lighting";
              lights = [ "light.kitchen" ];
              prefer_rgb_color = false;
              initial_transition = 1;
              transition = 30;
              interval = 90;
              min_brightness = 50;
              max_brightness = 100;
              min_color_temp = 2200;
              max_color_temp = 5500;
              sleep_brightness = 5;
              sleep_color_temp = 2200;
              sunrise_time = "06:30:00";
              sunset_time = null;
              take_over_control = true;
              detect_non_ha_changes = true;
            }

            # Hallway - Functional, short transitions
            {
              name = "Hallway Adaptive Lighting";
              lights = [ "light.hallway" ];
              prefer_rgb_color = false;
              initial_transition = 1;
              transition = 15;
              interval = 90;
              min_brightness = 30;
              max_brightness = 90;
              min_color_temp = 2200;
              max_color_temp = 5000;
              sleep_brightness = 3;
              sleep_color_temp = 2200;
              sunrise_time = null;
              sunset_time = null;
              take_over_control = true;
              detect_non_ha_changes = true;
            }
          ];

          # Home zone
          zone = [
            {
              name = "Home";
              latitude = "!secret latitude";
              longitude = "!secret longitude";
              radius = 100;
              icon = "mdi:home";
            }
          ];

          # Input helpers for automations
          input_boolean = {
            guest_mode = {
              name = "Guest Mode";
              icon = "mdi:account-multiple";
            };
            vacation_mode = {
              name = "Vacation Mode";
              icon = "mdi:beach";
            };
            sleep_mode = {
              name = "Sleep Mode";
              icon = "mdi:sleep";
            };
          };

          input_number = {
            heating_offset = {
              name = "Heating Temperature Offset";
              min = -5;
              max = 5;
              step = 0.5;
              unit_of_measurement = "°C";
              icon = "mdi:thermometer";
            };
          };

          input_select = {
            house_mode = {
              name = "House Mode";
              options = [
                "Home"
                "Away"
                "Sleep"
                "Guest"
              ];
              icon = "mdi:home-variant";
            };
          };

          homeassistant.customize = {
            "sensor.average_house_temperature" = {
              friendly_name = "Average Temperature";
            };
          };
        };
      };

      # Systemd services for secrets and intent scripts linking
      systemd.services.hass-secrets-link = {
        description = "Link Home Assistant secrets file";
        wantedBy = [ "home-assistant.service" ];
        before = [ "home-assistant.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.coreutils}/bin/ln -sf ${
            nixosConfig.sops.templates."hass-secrets.yaml".path
          } /var/lib/hass/secrets.yaml";
          User = "hass";
          Group = "hass";
        };
      };

    };
}
