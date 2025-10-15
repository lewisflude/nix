{
  config,
  pkgs,
  ...
}: let
  home-llm = pkgs.callPackage ./home-assistant/custom-components/home-llm.nix {inherit pkgs;};
  intent_script_yaml = ./home-assistant/intent-scripts/intent_script.yaml;
in {
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
    extraPackages = python3Packages:
      with python3Packages; [
        pychromecast
      ];
    extraComponents = [
      "analytics"
      "google_translate"
      "met"
      "radio_browser"
      "shopping_list"
      "music_assistant"
      "default_config"
      "homekit_controller"
      "linkplay"
      "unifi"
      "unifiprotect"
      "unifi_direct"
      "lovelace"
      "mqtt"
      "esphome"
      "denonavr"
      "tado"
      "apple_tv"
      "ollama"
      "ipp"
      "mjpeg"
      "mpd"
      "brother"
      "snapcast"
      "hue"
      "spotify"
      "media_player"
      "vacuum"
      "weather"
      "prusalink"
      "upnp"
      "wled"
      "zha"
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
      intent_script = "!include intent_script.yaml";
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
          systemd.services.home-assistant.path = [
            pkgs.gnumake
            pkgs.cmake
            pkgs.extra-cmake-modules
          ];
        }
        {
          play_music = {
            alias = "Play Music";
            description = "Plays music via music assistant";
            sequence = [
              {
                variables = {
                  media_player = ''
                    {% set media_players = integration_entities('music_assistant') %}
                    {% set area_entities = area_entities(area) %}
                    {% for player in media_players %}
                      {% if player in area_entities %}
                        {{ player }}
                      {% endif %}
                    {% endfor %}
                  '';
                };
              }
              {
                choose = [
                  {
                    conditions = [
                      {
                        condition = "template";
                        value_template = "{{ 'album' in query.lower() }}";
                      }
                    ];
                    sequence = [
                      {
                        data = {
                          media_type = "album";
                          enqueue = "replace";
                          media_id = "{{ query }}";
                          entity_id = "{{ media_player }}";
                        };
                        action = "music_assistant.play_media";
                      }
                    ];
                  }
                  {
                    conditions = [
                      {
                        condition = "template";
                        value_template = "{{ 'playlist' in query.lower() }}";
                      }
                    ];
                    sequence = [
                      {
                        data = {
                          media_type = "playlist";
                          enqueue = "replace";
                          media_id = "{{ query }}";
                          entity_id = "{{ media_player }}";
                        };
                        action = "music_assistant.play_media";
                      }
                    ];
                  }
                ];
                default = [
                  {
                    data = {
                      media_type = "track";
                      enqueue = "replace";
                      media_id = "{{ query }}";
                      radio_mode = true;
                      entity_id = "{{ media_player }}";
                    };
                    action = "music_assistant.play_media";
                  }
                ];
              }
            ];
            fields = {
              query = {
                description = "The title of the song, album, artist, or playlist to play.";
                example = "Greatest Hits album";
                required = true;
              };
              area = {
                example = "Living Room";
                description = "The area";
                required = true;
              };
            };
          };
        }
        {
          weather_forecast = {
            alias = "Weather Forecast";
            description = "Fetches and returns the forecast dictionary with day names.";
            sequence = [
              {
                action = "weather.get_forecasts";
                metadata = {};
                data = {
                  type = "daily";
                };
                response_variable = "forecast_daily";
                target = {
                  entity_id = "weather.pirateweather";
                };
              }
              {
                action = "weather.get_forecasts";
                metadata = {};
                data = {
                  type = "hourly";
                };
                response_variable = "forecast_hourly";
                target = {
                  entity_id = "weather.pirateweather";
                };
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
                  forecast_data_dict = {
                    forecast_daily = ''
                      {% set forecasts = forecast_daily['weather.pirateweather']['forecast'] %}
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
                      {% set forecasts = forecast_hourly['weather.pirateweather']['forecast'] %}
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
        }
        {
          get_entity_attributes = {
            alias = "Get Entity Attributes";
            description = "Fetches and returns the attributes of the entity.";
            sequence = [
              {
                variables = {
                  entity_id = ''
                    {% set matched_entity = states | selectattr('name', 'equalto', entity_name) | map(attribute='entity_id') | first %}
                    {{ matched_entity if matched_entity else entity }}
                  '';
                  attr = {
                    entity_attr = "{{ states[entity_id].attributes }}";
                  };
                };
              }
              {
                stop = "\"\"";
                response_variable = "attr";
              }
            ];
            fields = {
              entity_name = {
                example = "Kids Light";
                description = "Name of the entity";
              };
            };
          };
        }
      ];
      http = {
        base_url = "!secret base_url";
        server_host = ["0.0.0.0"];
        server_port = 8123;
        use_x_forwarded_for = true;
        trusted_proxies = ["192.168.1.0/24"];
      };
      default_config = {};
    };
  };
  systemd.services.hass-secrets-link = {
    description = "Link Home Assistant secrets file";
    wantedBy = ["home-assistant.service"];
    before = ["home-assistant.service"];
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
  systemd.services.hass-intent-script-link = {
    description = "Link intent_script.yaml for Home Assistant";
    wantedBy = ["home-assistant.service"];
    before = ["home-assistant.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "/run/current-system/sw/bin/ln -sf ${intent_script_yaml} /var/lib/hass/intent_script.yaml";
      User = "hass";
      Group = "hass";
    };
  };
  networking.firewall.allowedTCPPorts = [8123];
}
