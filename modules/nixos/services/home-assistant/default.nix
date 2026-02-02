{
  config,
  lib,
  pkgs,
  constants,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;

  cfg = config.host.services.homeAssistant;
  home-llm = pkgs.callPackage ./custom-components/home-llm.nix { };
  intent_script_yaml = ./intent-scripts/intent_script.yaml;
in
{
  options.host.services.homeAssistant = {
    enable = mkEnableOption "Home Assistant home automation";

    openFirewall = mkEnableOption "Open firewall for Home Assistant" // {
      default = true;
    };

    lovelaceMode = mkOption {
      type = types.enum [
        "yaml"
        "storage"
      ];
      default = "yaml";
      description = "Dashboard mode for Lovelace UI";
    };

    extraComponents = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional Home Assistant components to enable";
    };

    customLovelaceModules = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Custom Lovelace UI modules";
    };

    llmIntegration = mkEnableOption "Home LLM integration for local AI assistant";

    intentScripts = mkEnableOption "Intent scripts for voice assistant" // {
      default = true;
    };

    enableTemplates = mkEnableOption "Template sensors for device aggregation" // {
      default = true;
    };

    enableInputHelpers = mkEnableOption "Input helpers (booleans, numbers, selects)" // {
      default = true;
    };

    recorderPurgeDays = mkOption {
      type = types.int;
      default = 7;
      description = "Number of days to keep in database history (1-365)";
    };

    automations = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      description = "Declarative automations (merged with UI-created automations)";
      example = [
        {
          alias = "Turn on lights at sunset";
          trigger = [
            {
              platform = "sun";
              event = "sunset";
            }
          ];
          action = [
            {
              service = "light.turn_on";
              target.entity_id = "light.living_room";
            }
          ];
        }
      ];
    };

    scenes = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      description = "Declarative scenes";
      example = [
        {
          name = "Movie Time";
          entities = {
            "light.living_room".state = "on";
            "light.living_room".brightness = 50;
          };
        }
      ];
    };

    # Weather configuration
    weather = {
      entity = mkOption {
        type = types.str;
        default = "weather.pirateweather";
        description = "Weather entity ID for forecast scripts";
        example = "weather.met";
      };
    };

    # Temperature sensor configuration
    temperatureSensors = mkOption {
      type = types.listOf types.str;
      default = [
        "sensor.bedroom_temperature"
        "sensor.living_room_temperature"
        "sensor.kitchen_temperature"
        "sensor.office_temperature"
      ];
      description = "Temperature sensor entity IDs for average calculation";
      example = [
        "sensor.bedroom_temperature"
        "sensor.living_room_temperature"
      ];
    };

    # Music player configuration
    musicPlayer = {
      enable = mkEnableOption "Music playback integration";

      defaultMediaPlayer = mkOption {
        type = types.str;
        default = "media_player.music_assistant";
        description = "Default media player entity for music playback";
        example = "media_player.spotify";
      };

      searchBackend = mkOption {
        type = types.enum [
          "music_assistant"
          "spotify"
          "ytmusic"
        ];
        default = "music_assistant";
        description = "Backend service for music search and playback";
      };
    };

    # Validation configuration
    validation = {
      checkDependencies = mkEnableOption "Validate required integrations and dependencies" // {
        default = true;
      };
    };
  };

  config = mkIf cfg.enable {
    # Assertions for configuration validation
    assertions = lib.optionals cfg.validation.checkDependencies [
      {
        assertion = cfg.recorderPurgeDays >= 1 && cfg.recorderPurgeDays <= 365;
        message = "homeAssistant.recorderPurgeDays must be between 1 and 365 days (got ${toString cfg.recorderPurgeDays})";
      }
      {
        assertion = cfg.enableTemplates -> (cfg.temperatureSensors != [ ]);
        message = "homeAssistant.temperatureSensors cannot be empty when enableTemplates is true";
      }
      {
        assertion = lib.hasPrefix "weather." cfg.weather.entity;
        message = "homeAssistant.weather.entity must start with 'weather.' (got '${cfg.weather.entity}')";
      }
      {
        assertion =
          cfg.llmIntegration
          -> (
            lib.elem "ollama" (config.services.home-assistant.extraComponents)
            || lib.elem "ollama" (config.services.home-assistant.config.extraComponents or [ ])
          );
        message = "homeAssistant.llmIntegration requires 'ollama' component to be enabled in extraComponents";
      }
      {
        assertion =
          (cfg.musicPlayer.enable && cfg.musicPlayer.searchBackend == "music_assistant")
          -> (
            lib.elem "music_assistant" (config.services.home-assistant.extraComponents)
            || lib.elem "music_assistant" (config.services.home-assistant.config.extraComponents or [ ])
          );
        message = "homeAssistant.musicPlayer with 'music_assistant' backend requires Music Assistant integration to be configured";
      }
      {
        assertion =
          cfg.musicPlayer.enable -> (lib.hasPrefix "media_player." cfg.musicPlayer.defaultMediaPlayer);
        message = "homeAssistant.musicPlayer.defaultMediaPlayer must start with 'media_player.' (got '${cfg.musicPlayer.defaultMediaPlayer}')";
      }
    ];

    sops.templates."hass-secrets.yaml" = {
      content = ''
        latitude: ${config.sops.placeholder.LATITUDE}
        longitude: ${config.sops.placeholder.LONGITUDE}
      '';
      owner = "hass";
      group = "hass";
      mode = "0400";
    };

    services.home-assistant = {
      enable = true;
      configDir = "/var/lib/hass";
      openFirewall = cfg.openFirewall;

      extraComponents = [
        # Core components
        "analytics"
        "default_config"
        "esphome"
        "google_translate"
        "isal"
        "lovelace"
        "met"
        "radio_browser"
        "shopping_list"

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
        "unifiprotect"
        "unifi_direct"
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
      ]
      ++ lib.optional (cfg.musicPlayer.enable && cfg.musicPlayer.searchBackend == "music_assistant") "music_assistant"
      ++ cfg.extraComponents;

      customComponents = [
        pkgs.home-assistant-custom-components.localtuya
        pkgs.home-assistant-custom-components.adaptive_lighting
      ]
      ++ lib.optional cfg.llmIntegration home-llm;

      customLovelaceModules = cfg.customLovelaceModules;

      config = {
        # Lovelace dashboard configuration
        lovelace = {
          mode = cfg.lovelaceMode;
          resources = [ ];
        };

        # Core Home Assistant configuration
        homeassistant = {
          name = "Home";
          latitude = "!secret latitude";
          longitude = "!secret longitude";
          elevation = 0;
          unit_system = "metric";
          time_zone = constants.defaults.timezone;
          country = "GB";
          currency = "GBP";
          internal_url = "http://localhost:${toString constants.ports.services.homeAssistant}";
          allowlist_external_dirs = [
            "/var/lib/hass"
          ];
        };

        # Default integrations
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

        # Frontend configuration
        frontend = {
          themes = "!include_dir_merge_named themes";
        };

        # Text-to-speech
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
          purge_keep_days = cfg.recorderPurgeDays;
          commit_interval = 1;
          exclude = {
            domains = [
              "automation"
              "updater"
            ];
            entity_globs = [
              "sensor.weather_*"
            ];
            entities = [
              "sun.sun"
            ];
          };
        };

        # History
        history = {
          exclude = {
            domains = [
              "automation"
              "updater"
            ];
          };
        };

        # Logbook
        logbook = {
          exclude = {
            domains = [
              "automation"
            ];
          };
        };

        # Logger configuration
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
          # Weather forecast script - fetches daily and hourly forecasts with day names
          weather_forecast = {
            alias = "Weather Forecast";
            description = "Fetches and returns the forecast dictionary with day names.";
            fields = {
              weather_entity = {
                description = "Weather entity to fetch forecast from (overrides default)";
                example = "weather.met";
                default = cfg.weather.entity;
              };
            };
            sequence = [
              {
                action = "weather.get_forecasts";
                data.type = "daily";
                response_variable = "forecast_daily";
                target.entity_id = "{{ weather_entity | default('${cfg.weather.entity}') }}";
              }
              {
                action = "weather.get_forecasts";
                data.type = "hourly";
                response_variable = "forecast_hourly";
                target.entity_id = "{{ weather_entity | default('${cfg.weather.entity}') }}";
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
                  weather_entity_used = "{{ weather_entity | default('${cfg.weather.entity}') }}";
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

          # Get entity attributes script - fetches entity state and attributes
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
                    {{ matched_entity if matched_entity else entity }}
                  '';
                };
              }
              # Validate entity exists and is available
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
        }
        # Music playback script - conditionally enabled
        // lib.optionalAttrs cfg.musicPlayer.enable {
          play_music = {
            alias = "Play Music";
            description = "Search and play music using configured backend";
            fields = {
              query = {
                description = "Search query for music (artist, song, album, genre)";
                example = "play some jazz";
                required = true;
              };
              area = {
                description = "Area name for playback location (optional)";
                example = "living room";
                required = false;
              };
              media_player = {
                description = "Media player entity (defaults to configured player)";
                example = "media_player.spotify";
                default = cfg.musicPlayer.defaultMediaPlayer;
              };
            };
            sequence = [
              {
                variables = {
                  player_entity = "{{ media_player | default('${cfg.musicPlayer.defaultMediaPlayer}') }}";
                };
              }
              # Validate media player exists and is available
              {
                condition = "template";
                value_template = "{{ states(player_entity) not in ['unavailable', 'unknown'] }}";
                alias = "Check media player is available";
              }
              # Route to appropriate backend based on configuration
              {
                choose = [
                  # Music Assistant backend
                  {
                    conditions = [
                      {
                        condition = "template";
                        value_template = "{{ '${cfg.musicPlayer.searchBackend}' == 'music_assistant' }}";
                      }
                    ];
                    sequence = [
                      {
                        action = "media_player.play_media";
                        target.entity_id = "{{ player_entity }}";
                        data = {
                          media_content_type = "music";
                          media_content_id = "{{ query }}";
                        };
                      }
                    ];
                  }
                  # Spotify backend
                  {
                    conditions = [
                      {
                        condition = "template";
                        value_template = "{{ '${cfg.musicPlayer.searchBackend}' == 'spotify' }}";
                      }
                    ];
                    sequence = [
                      {
                        action = "spotcast.start";
                        data = {
                          uri = "spotify:search:{{ query }}";
                          device_name = "{{ player_entity.split('.')[1] }}";
                        };
                      }
                    ];
                  }
                  # YouTube Music backend
                  {
                    conditions = [
                      {
                        condition = "template";
                        value_template = "{{ '${cfg.musicPlayer.searchBackend}' == 'ytmusic' }}";
                      }
                    ];
                    sequence = [
                      {
                        action = "ytube_music_player.call_method";
                        data = {
                          entity_id = "{{ player_entity }}";
                          command = "search";
                          parameters = {
                            query = "{{ query }}";
                          };
                        };
                      }
                    ];
                  }
                ];
                # Fallback error handling
                default = [
                  {
                    action = "system_log.write";
                    data = {
                      level = "error";
                      message = "Unsupported music backend: ${cfg.musicPlayer.searchBackend}";
                    };
                  }
                ];
              }
            ];
          };
        };

        # Adaptive Lighting - Circadian rhythm lighting automation
        adaptive_lighting = [
          # Office - Optimized for productivity with cooler temps during work hours
          {
            name = "Office Adaptive Lighting";
            lights = [
              "light.office" # Group controlling all office lights
              # Individual lights (controlled by group):
              # - light.hue_iris_1 (accent)
              # - light.hue_play_1, light.hue_play_2 (play bars)
              # - light.hue_surimu_panel_1 (panel)
              # - light.hue_gradient_lightstrip_1, light.hue_gradient_lightstrip_2 (LED strips)
            ];
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
            sunset_time = null; # Use automatic sunset
            take_over_control = true;
            detect_non_ha_changes = true;
          }

          # Living Room - Balanced comfort throughout the day
          {
            name = "Living Room Adaptive Lighting";
            lights = [
              "light.living_room" # Group controlling living room lights
              "light.living_room_pendant"
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
            sunrise_time = null; # Use automatic sunrise
            sunset_time = null; # Use automatic sunset
            take_over_control = true;
            detect_non_ha_changes = true;
          }

          # Kitchen - Bright and functional, adapts in evening
          # NOTE: No dedicated kitchen lights found in Home Assistant
          # Only light.home_assistant_voice_0949ed_led_ring in kitchen area
          # Skipping kitchen adaptive lighting until proper lights are added

          # Dining Room - Task lighting that adapts in evening
          {
            name = "Dining Room Adaptive Lighting";
            lights = [
              "light.dining_room" # Group controlling dining room lights
              "light.dining_room_pendant"
            ];
            prefer_rgb_color = false;
            initial_transition = 1;
            transition = 30;
            interval = 90;
            min_brightness = 50;
            max_brightness = 100;
            min_color_temp = 2200;
            max_color_temp = 5500;
            sleep_brightness = 10;
            sleep_color_temp = 2200;
            sunrise_time = "06:30:00";
            sunset_time = null;
            take_over_control = true;
            detect_non_ha_changes = true;
          }

          # NOTE: Bedroom, Guest Bedroom, Hallway, and Kitchen do not have lights assigned in Home Assistant yet
          # Add adaptive lighting configurations for these rooms once lights are added
        ];

        # Automations: use Nix-defined automations if provided, otherwise include UI file
        # Note: Home Assistant's automations.yaml contains UI-created automations
        automation = if cfg.automations == [ ] then "!include automations.yaml" else cfg.automations;

        # Declarative scenes
        scene = cfg.scenes;

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
      }
      // lib.optionalAttrs cfg.enableInputHelpers {
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
      }
      // lib.optionalAttrs cfg.enableTemplates {
        # Template sensors for device aggregation and status
        template = [
          {
            sensor = [
              # Average house temperature - aggregates all configured temperature sensors
              {
                name = "Average House Temperature";
                unit_of_measurement = "°C";
                device_class = "temperature";
                state = ''
                  {% set temps = [
                    ${lib.concatMapStringsSep ",\n                    " (
                      sensor: "states('${sensor}') | float(0)"
                    ) cfg.temperatureSensors}
                  ] %}
                  {% set valid_temps = temps | select('>', 0) | list %}
                  {{ (valid_temps | sum / (valid_temps | length)) | round(1) if valid_temps | length > 0 else 0 }}
                '';
                # Only available when at least one sensor is available
                availability = ''
                  {{ [
                    ${lib.concatMapStringsSep ",\n                    " (
                      sensor: "states('${sensor}')"
                    ) cfg.temperatureSensors}
                  ] | select('in', ['unknown', 'unavailable']) | list | length == 0 }}
                '';
              }
              # Home occupancy status - derived from house mode
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

        # Customize entities for better UI display
        homeassistant.customize = {
          "sensor.average_house_temperature" = {
            friendly_name = "Average Temperature";
          };
        };
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

    systemd.services.hass-intent-script-link = mkIf cfg.intentScripts {
      description = "Link intent_script.yaml for Home Assistant";
      wantedBy = [ "home-assistant.service" ];
      before = [ "home-assistant.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "/run/current-system/sw/bin/ln -sf ${intent_script_yaml} /var/lib/hass/intent_script.yaml";
        User = "hass";
        Group = "hass";
      };
    };
  };
}
