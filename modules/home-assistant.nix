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
      lib,
      pkgs,
      config,
      ...
    }:
    let

      # home-llm is disabled until the package is updated for current nixpkgs
      # (buildHomeAssistantComponent moved). Use native Ollama integration instead.
      intent_script_yaml = ../pkgs/home-assistant/intent-scripts/intent_script.yaml;

      weatherEntity = "weather.pirateweather";

      temperatureSensors = [
        "sensor.bedroom_temperature"
        "sensor.guest_bedroom_temperature"
        "sensor.living_room_temperature"
        "sensor.kitchen_temperature"
        "sensor.office_temperature"
      ];

      automations = [
        {
          alias = "Turn off lights when Apple TV is playing";
          id = "apple_tv_lights_off";
          description = "Turn off living room and dining room lights when Apple TV starts playing after dark";
          trigger = [
            {
              platform = "state";
              entity_id = "media_player.apple_tv";
              to = "playing";
            }
          ];
          condition = [
            {
              condition = "state";
              entity_id = "sun.sun";
              state = "below_horizon";
            }
          ];
          action = [
            {
              action = "light.turn_off";
              target.entity_id = [
                "light.living_room"
                "light.living_room_pendant"
                "light.dining_room"
                "light.dining_room_pendant"
              ];
            }
          ];
        }
        {
          alias = "Activate Sleep Mode Lighting";
          id = "sleep_mode_lighting";
          description = "Switch all adaptive lighting to sleep mode";
          trigger = [
            {
              platform = "state";
              entity_id = "input_boolean.sleep_mode";
              to = "on";
            }
          ];
          action = [
            {
              action = "switch.turn_on";
              target.entity_id = [
                "switch.adaptive_lighting_sleep_mode_office_adaptive_lighting"
                "switch.adaptive_lighting_sleep_mode_living_dining_room_adaptive_lighting"
                "switch.adaptive_lighting_sleep_mode_bedroom_adaptive_lighting"
                "switch.adaptive_lighting_sleep_mode_kitchen_adaptive_lighting"
                "switch.adaptive_lighting_sleep_mode_hallway_adaptive_lighting"
              ];
            }
          ];
        }
        {
          alias = "Deactivate Sleep Mode Lighting";
          id = "sleep_mode_lighting_off";
          description = "Switch all adaptive lighting back to normal";
          trigger = [
            {
              platform = "state";
              entity_id = "input_boolean.sleep_mode";
              to = "off";
            }
          ];
          action = [
            {
              action = "switch.turn_off";
              target.entity_id = [
                "switch.adaptive_lighting_sleep_mode_office_adaptive_lighting"
                "switch.adaptive_lighting_sleep_mode_living_dining_room_adaptive_lighting"
                "switch.adaptive_lighting_sleep_mode_bedroom_adaptive_lighting"
                "switch.adaptive_lighting_sleep_mode_kitchen_adaptive_lighting"
                "switch.adaptive_lighting_sleep_mode_hallway_adaptive_lighting"
              ];
            }
          ];
        }
      ];
    in
    {
      # SOPS secrets configuration
      sops.templates."hass-secrets.yaml" = {
        content = ''
          latitude: ${config.sops.placeholder.LATITUDE}
          longitude: ${config.sops.placeholder.LONGITUDE}
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

        customLovelaceModules = [ ];

        config = {
          # Lovelace dashboard configuration
          lovelace = {
            mode = "yaml";
            resources = [ ];
          };

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
          intent_script = "!include intent_script.yaml";

          # Scripts
          script = {
            # Weather forecast script
            weather_forecast = {
              alias = "Weather Forecast";
              description = "Fetches and returns the forecast dictionary with day names.";
              fields = {
                weather_entity = {
                  description = "Weather entity to fetch forecast from (overrides default)";
                  example = "weather.met";
                  default = weatherEntity;
                };
              };
              sequence = [
                {
                  action = "weather.get_forecasts";
                  data.type = "daily";
                  response_variable = "forecast_daily";
                  target.entity_id = "{{ weather_entity | default('${weatherEntity}') }}";
                }
                {
                  action = "weather.get_forecasts";
                  data.type = "hourly";
                  response_variable = "forecast_hourly";
                  target.entity_id = "{{ weather_entity | default('${weatherEntity}') }}";
                }
                {
                  variables = {
                    days_of_week = [
                      "Sunday"
                      "Monday"
                      "Tuesday"
                      "Wednesday"
                      "Thursday"
                      "Friday"
                      "Saturday"
                    ];
                    today = "{{ now().strftime('%A') }}";
                    start_index = "{{ days_of_week.index(today) }}";
                    weather_entity_used = "{{ weather_entity | default('${weatherEntity}') }}";
                    forecast_data_dict = {
                      forecast_daily = ''
                        {% set forecasts = forecast_daily[weather_entity_used]['forecast'] %}
                        [{% for i in range(forecasts | length) %}
                          {
                            {% for key, value in forecasts[i].items() %}
                            {% if key == 'datetime' %}
                              {% set local_datetime = (forecasts[i]['datetime'] | as_datetime | as_local) %}
                              "datetime": "{{ local_datetime.strftime('%Y-%m-%d') }}",
                            {% else %}
                              "day_of_the_week": "{{ days_of_week[(start_index + i) % days_of_week | length] }}",
                              "{{ key }}": {{ value | tojson }},
                            {% endif %}
                            {% endfor %}
                          }
                          {% if not loop.last %},{% endif %}
                        {% endfor %}]
                      '';
                      forecast_hourly = ''
                        {% set forecasts = forecast_hourly[weather_entity_used]['forecast'] %}
                        [{% for i in range(0, 24) %}
                          {
                            {% for key, value in forecasts[i].items() %}
                            {% if key == 'datetime' %}
                              {% set local_datetime = (forecasts[i]['datetime'] | as_datetime | as_local) %}
                              "datetime": "{{ local_datetime.strftime('%Y-%m-%d %H:%M') }}",
                            {% else %}
                              "{{ key }}": {{ value | tojson }},
                            {% endif %}
                            {% endfor %}
                          }
                          {% if not loop.last %},{% endif %}
                        {% endfor %}]
                      '';
                    };
                  };
                }
                {
                  stop = "Returning complete forecast dictionary with days";
                  response_variable = "forecast_data_dict";
                }
              ];
            };

            # Get entity attributes script
            get_entity_attributes = {
              alias = "Get Entity Attributes";
              description = "Fetches and returns the state and attributes of an entity.";
              fields = {
                entity_name = {
                  description = "Name of the entity";
                  example = "Kids Light";
                };
              };
              sequence = [
                {
                  variables = {
                    entity_id = ''
                      {% set matched_entity = states | selectattr('name', 'equalto', entity_name) | map(attribute='entity_id') | first %}
                      {{ matched_entity if matched_entity else entity_name }}
                    '';
                  };
                }
                {
                  condition = "template";
                  value_template = "{{ entity_id is defined and states(entity_id) not in ['unavailable', 'unknown'] }}";
                  alias = "Check entity exists and is available";
                }
                {
                  variables = {
                    attr = {
                      entity_id = "{{ entity_id }}";
                      state = "{{ states(entity_id) }}";
                      attributes = "{{ states[entity_id].attributes }}";
                    };
                  };
                }
                {
                  stop = "Returning entity state and attributes";
                  response_variable = "attr";
                }
              ];
            };

            # Play music via Music Assistant
            play_music = {
              alias = "Play Music";
              description = "Search and play music using Music Assistant";
              fields = {
                query = {
                  description = "Search query for music (artist, song, album, genre)";
                  example = "play some jazz";
                  required = true;
                };
                area = {
                  description = "Area name for playback location";
                  example = "living room";
                  required = false;
                };
                media_player = {
                  description = "Media player entity for playback";
                  example = "media_player.music_assistant";
                  default = "media_player.music_assistant";
                };
              };
              sequence = [
                {
                  condition = "template";
                  value_template = "{{ states(media_player) not in ['unavailable', 'unknown'] }}";
                  alias = "Check media player is available";
                }
                {
                  action = "media_player.play_media";
                  target = {
                    entity_id = "{{ media_player }}";
                    area_id = "{{ area | default('') }}";
                  };
                  data = {
                    media_content_type = "music";
                    media_content_id = "{{ query }}";
                  };
                }
              ];
            };
          };

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

          automation = automations;
          scene = [ ];

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

          # Template sensors
          template = [
            {
              sensor = [
                {
                  name = "Average House Temperature";
                  unit_of_measurement = "°C";
                  device_class = "temperature";
                  state = ''
                    {% set temps = [
                      ${lib.concatMapStringsSep ",\n                      " (
                        sensor: "states('${sensor}') | float(0)"
                      ) temperatureSensors}
                    ] %}
                    {% set valid_temps = temps | select('>', 0) | list %}
                    {{ (valid_temps | sum / (valid_temps | length)) | round(1) if valid_temps | length > 0 else 0 }}
                  '';
                  availability = ''
                    {{ [
                      ${lib.concatMapStringsSep ",\n                      " (
                        sensor: "states('${sensor}')"
                      ) temperatureSensors}
                    ] | reject('in', ['unknown', 'unavailable']) | list | length > 0 }}
                  '';
                }
                {
                  name = "Home Occupied";
                  state = ''
                    {{ is_state('input_select.house_mode', 'Home') or
                       is_state('input_select.house_mode', 'Guest') }}
                  '';
                }
              ];
            }
          ];

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
            config.sops.templates."hass-secrets.yaml".path
          } /var/lib/hass/secrets.yaml";
          User = "hass";
          Group = "hass";
        };
      };

      systemd.services.hass-intent-script-link = {
        description = "Link intent_script.yaml for Home Assistant";
        wantedBy = [ "home-assistant.service" ];
        before = [ "home-assistant.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.coreutils}/bin/ln -sf ${intent_script_yaml} /var/lib/hass/intent_script.yaml";
          User = "hass";
          Group = "hass";
        };
      };
    };
}
