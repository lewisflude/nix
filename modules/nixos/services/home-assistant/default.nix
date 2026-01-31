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

    llmIntegration = mkEnableOption "Home LLM integration for local AI assistant";

    intentScripts = mkEnableOption "Intent scripts for voice assistant" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
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
      ++ cfg.extraComponents;

      customComponents = [
        pkgs.home-assistant-custom-components.localtuya
      ]
      ++ lib.optional cfg.llmIntegration home-llm;

      config = {
        lovelace.mode = cfg.lovelaceMode;
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
            weather_forecast = {
              alias = "Weather Forecast";
              description = "Fetches and returns the forecast dictionary with day names.";
              sequence = [
                {
                  action = "weather.get_forecasts";
                  metadata = { };
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
                  metadata = { };
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
          server_host = [ constants.networks.all.ipv4 ];
          server_port = constants.ports.services.homeAssistant;
          use_x_forwarded_for = true;
          trusted_proxies = [ constants.networks.lan.primary ];
        };
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
