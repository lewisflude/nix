{
  username = "lewisflude";
  useremail = "lewis@lewisflude.com";
  system = "x86_64-linux";
  hostname = "jupiter";

  # Hardware configuration
  hardware = {
    gpuID = "10de:2684"; # RTX 4090
    renderDevice = "/dev/dri/renderD129"; # Force NVIDIA as primary render device
  };

  features = {
    security = {
      enable = true;
      yubikey = true;
      fail2ban = true;
    };

    development = {
      lua = true;
      # Moved to devShells to reduce system size (~2-4GB savings)
      # Use: nix develop .#rust or direnv with .envrc
      rust = false; # Use: nix develop .#rust
      python = false; # Use: nix develop .#python
      node = false; # Use: nix develop .#node
    };

    gaming = {
      enable = true;
      steam = true;
      performance = true;
      lutris = true;
    };

    flatpak.enable = true;

    vr = {
      enable = true;
      wivrn = {
        enable = true;
        autoStart = true;
        defaultRuntime = true;
        openFirewall = true;
      };
      immersed = {
        enable = true;
        openFirewall = true;
      };
      steamvr = true; # Required for 32-bit games
      performance = true; # NVIDIA optimizations
    };

    virtualisation = {
      enable = true;
      podman = true;
    };

    homeServer = {
      enable = true;
      fileSharing = true;
    };

    desktop = {
      niri = true;
      utilities = true;
    };

    restic = {
      enable = true;
      restServer.enable = true;
    };

    media = {
      enable = true;

      audio = {
        enable = true;

        # Real-time audio (CURRENTLY DISABLED for stability)
        # RT kernel causes issues with NVIDIA RTX 4090 drivers
        # XanMod provides excellent latency (~5.3ms) for gaming/desktop use
        # Re-enable only if you need ultra-low latency for professional recording
        realtime = false;

        # Ultra-low latency mode (requires realtime = true)
        # Current: false for stable gaming (256 frames = ~5.3ms latency)
        # Professional: true for recording (64 frames = ~1.3ms, requires RT kernel)
        ultraLowLatency = false;

        # USB audio interface optimization
        # Auto-detects any USB audio class device (Apogee, Focusrite, etc.)
        # Currently detects: Apogee Symphony Desktop
        usbAudioInterface = {
          enable = true;
          pciId = "00:14.0"; # Intel USB controller for IRQ optimization
        };

        # musnix tools (only active when realtime = true)
        rtirq = true; # IRQ priority management
        dasWatchdog = true; # Kills runaway RT processes
        rtcqs = true; # RT analysis tool (run: rtcqs)

        # audio.nix flake packages (Bitwig Studio and plugins)
        # Temporarily disabling due to webkitgtk compatibility issue
        audioNix = {
          enable = false;
          bitwig = false;
          plugins = false;
        };
      };
    };

    productivity = {
      enable = true;
      notes = true;
      email = true;
      calendar = true;
    };

    mediaManagement = {
      enable = true;

      unpackerr.enable = false;
      listenarr.enable = true;

      qbittorrent = {
        enable = true;

        # IP Protocol: Use IPv4 only (IPv6 port forwarding not supported by ProtonVPN NAT-PMP)
        ipProtocol = "IPv4";

        # Storage optimization: NVMe (ZFS root pool) for incomplete downloads, HDD for final storage
        incompleteDownloadPath = "/var/lib/qbittorrent/incomplete";

        # OPTIMIZED SETTINGS (balanced for stability and performance)
        # Based on 8,216 KB/s upload via VPN, but tuned to prevent packet drops
        # Upload speed: 8,216 KB/s (82.16 Mbit/s measured via VPN)
        # Priority: Stability with good performance
        uploadSpeedLimit = 8216; # KB/s - 80% of measured VPN upload (leaves 20% for ACKs)

        # Connection settings (reduced to prevent WireGuard interface overload)
        maxConnections = 300; # Global max connections (reduced from 600 for stability)
        maxConnectionsPerTorrent = 100; # Peer diversity maintained

        # Upload slot optimization (balanced for concurrent seeding without bursts)
        maxUploads = 200; # Upload slots - reduced from 1643 to prevent traffic bursts
        maxUploadsPerTorrent = 10; # Per-torrent slots (optimal)

        # Active torrent limits (balanced for performance without overwhelming interface)
        maxActiveTorrents = 150; # Reduced from 547 to prevent HDD thrashing
        maxActiveDownloads = 5; # Concurrent downloads (5 for faster grabbing, 3 for HDD protection)
        maxActiveUploads = 50; # Reduced from 273 to prevent packet drops

        defaultSavePath = "/mnt/storage/torrents";

        # Share limits (ratio and seeding time)
        maxRatio = 3.0;
        maxInactiveSeedingTime = 43200; # 30 days in minutes (43200 = 30 * 24 * 60)
        shareLimitAction = "Stop"; # Pause torrent when limits reached

        # VPN Configuration
        vpn = {
          enable = true;
          namespace = "qbt";
          torrentPort = 62000; # Initial placeholder - dynamically updated by protonvpn-portforward.service every 45s
          webUIBindAddress = "*"; # Accessible from any interface
        };

        # WebUI Configuration
        webUI = {
          bindAddress = "*"; # Accessible from any interface (192.168.10.210:8080)
          username = "lewisflude";
          password = "@ByteArray(J5lri+TddZR2AJqNVPndng==:no5T50n4CD9peISk6jZQ+Cb8qzv6DoV2MtOxE2oErywXVFngVDq/eySGpoNjUCFOHFdbifjwwHI4jlV2LH4ocQ==)";
          alternativeUIEnabled = true;
          # rootFolder will default to vuetorrent package path when alternativeUIEnabled is true
        };

        # Category Mappings (final download destinations on HDD)
        categories = {
          radarr = "/mnt/storage/movies";
          sonarr = "/mnt/storage/tv";
          lidarr = "/mnt/storage/music";
          readarr = "/mnt/storage/books";
          listenarr = "/mnt/storage/audiobooks";
          pc = "/mnt/storage/pc";
          movies = "/mnt/storage/movies";
          tv = "/mnt/storage/tv";
        };
      };

      transmission = {
        enable = true;

        authentication = {
          enable = true;
          useSops = true;
        };

        downloadDir = "/mnt/storage/torrents";
        incompleteDir = "/var/lib/transmission/incomplete";

        # Run on host network (not VPN) since ProtonVPN only forwards one port
        # qBittorrent gets the forwarded port and VPN, Transmission runs directly
        peerPort = 51413; # Default Transmission port

        vpn = {
          enable = false; # Run on host network, not VPN
        };
      };
    };

    aiTools = {
      enable = true;
      ollama = {
        acceleration = "cuda";
        models = [ "llama2" ];
      };
      openWebui.enable = false;
    };
  };

  services = {
    homeAssistant = {
      enable = true;
      lovelaceMode = "yaml";
      llmIntegration = true;
      intentScripts = true;

      # Weather service - Met.no is best for UK (free, accurate, community favorite)
      weather.entity = "weather.met";

      # Temperature sensors for averaging
      # Tado thermostats provide room-specific temperature readings
      # Combined with Hue motion sensor for comprehensive home temperature
      temperatureSensors = [
        "sensor.bedroom_temperature" # Tado bedroom thermostat
        "sensor.guest_bedroom_temperature" # Tado guest bedroom thermostat
        "sensor.hallway_temperature" # Tado hallway thermostat
        "sensor.kitchen_temperature" # Tado kitchen thermostat
        "sensor.hue_motion_sensor_1_temperature" # Hue motion sensor
      ];

      # Music playback integration
      # Available speakers:
      #   - media_player.living_room (WiiM Mini via LinkPlay)
      #   - media_player.kitchen_speaker (WiiM Pro via Google Cast)
      musicPlayer = {
        enable = true;
        # Fallback player (always specify media_player in script calls for best control)
        defaultMediaPlayer = "media_player.kitchen_speaker"; # WiiM Pro
        searchBackend = "music_assistant"; # Requires Music Assistant server
      };

      # Database history retention (default: 7 days)
      recorderPurgeDays = 7;

      # Declarative scenes - Enhanced with Adaptive Lighting integration
      scenes = [
        {
          name = "Movie Time";
          icon = "mdi:movie";
          entities = {
            # Dim living room lights for cinema ambiance
            "light.living_room" = {
              state = "on";
              brightness = 26; # 10%
              color_temp_kelvin = 2200;
            };
            "light.dining_room" = {
              state = "off"; # Turn off dining room for movies
            };
            # Adaptive lighting will be manually disabled for this scene
          };
        }
        {
          name = "Focus Mode";
          icon = "mdi:brain";
          entities = {
            # Bright, cool white for deep work in office
            "light.office" = {
              state = "on";
              brightness = 255; # 100%
              color_temp_kelvin = 5000;
            };
          };
        }
        {
          name = "Bedtime";
          icon = "mdi:bed";
          entities = {
            # Turn off all lights and enable sleep mode
            "light.office".state = "off";
            "light.living_room".state = "off";
            "light.dining_room".state = "off";
            # Sleep mode input boolean will trigger adaptive lighting sleep mode
            "input_boolean.sleep_mode".state = "on";
            # TODO: Add bedroom light with minimal warm setting when bedroom lights are added
          };
        }
        {
          name = "Welcome Home";
          icon = "mdi:home";
          entities = {
            # Comfortable adaptive lighting when arriving
            # Uses adaptive lighting - just turn on lights
            "light.living_room".state = "on";
            "light.dining_room".state = "on";
            # Brightness and color handled by adaptive lighting
            "input_select.house_mode".state = "Home";
            # TODO: Add hallway and kitchen when lights are added
          };
        }
        {
          name = "Relaxing Evening";
          icon = "mdi:weather-sunset";
          entities = {
            # Warm, dim lighting for unwinding
            "light.living_room" = {
              state = "on";
              brightness = 128; # 50%
              color_temp_kelvin = 2500;
            };
            "light.dining_room" = {
              state = "on";
              brightness = 102; # 40%
              color_temp_kelvin = 2300;
            };
          };
        }
        {
          name = "Morning Energize";
          icon = "mdi:weather-sunny";
          entities = {
            # Bright, cool lighting to wake up and energize
            "light.office" = {
              state = "on";
              brightness = 255; # 100%
              color_temp_kelvin = 5000;
            };
            "light.living_room" = {
              state = "on";
              brightness = 204; # 80%
              color_temp_kelvin = 4500;
            };
            "input_boolean.sleep_mode".state = "off";
            "input_select.house_mode".state = "Home";
            # TODO: Add bedroom and kitchen when lights are added
          };
        }
        {
          name = "All Off";
          icon = "mdi:lightbulb-off";
          entities = {
            # Turn off all lights
            "light.office".state = "off";
            "light.living_room".state = "off";
            "light.dining_room".state = "off";
            "light.home".state = "off"; # Master light group
          };
        }
      ];

      # Declarative automations
      automations = [
        # ==================== LIGHTING AUTOMATIONS ====================
        {
          id = "lights_on_at_sunset";
          alias = "Turn on lights at sunset";
          description = "Gradually turn on living area lights 30 min before sunset (adaptive lighting handles color/brightness)";
          mode = "single";
          trigger = [
            {
              platform = "sun";
              event = "sunset";
              offset = "-00:30:00"; # 30 minutes before sunset
            }
          ];
          condition = [
            {
              condition = "state";
              entity_id = "person.lewis";
              state = "home";
            }
            {
              condition = "state";
              entity_id = "input_boolean.sleep_mode";
              state = "off";
            }
          ];
          action = [
            {
              service = "input_select.select_option";
              target.entity_id = "input_select.house_mode";
              data.option = "Home";
            }
            {
              # Turn on lights - adaptive lighting will set appropriate color/brightness
              service = "light.turn_on";
              target.entity_id = [
                "light.living_room"
                "light.dining_room"
                # Note: kitchen and hallway don't have smart lights yet
              ];
              data = {
                transition = 300; # 5 minute gentle transition
              };
            }
          ];
        }
        {
          id = "lights_off_at_night";
          alias = "Turn off lights late at night";
          description = "Automatically turn off lights if still on after midnight";
          mode = "single";
          trigger = [
            {
              platform = "time";
              at = "00:30:00";
            }
          ];
          condition = [
            {
              condition = "state";
              entity_id = "input_boolean.sleep_mode";
              state = "off";
            }
          ];
          action = [
            {
              service = "input_boolean.turn_on";
              target.entity_id = "input_boolean.sleep_mode";
            }
            # Uncomment once lights connected:
            # {
            #   service = "light.turn_off";
            #   target.entity_id = "all";
            # }
          ];
        }
        {
          id = "lights_on_when_arriving_dark";
          alias = "Turn on lights when arriving home after dark";
          description = "Welcome home with lights if arriving when it's dark";
          mode = "single";
          trigger = [
            {
              platform = "state";
              entity_id = "person.lewis";
              from = "not_home";
              to = "home";
            }
          ];
          condition = [
            {
              condition = "sun";
              after = "sunset";
              before = "sunrise";
            }
          ];
          action = [
            {
              service = "input_select.select_option";
              target.entity_id = "input_select.house_mode";
              data.option = "Home";
            }
            # Uncomment once lights connected:
            # {
            #   service = "scene.turn_on";
            #   target.entity_id = "scene.welcome_home";
            # }
          ];
        }

        # ==================== MOTION-BASED LIGHTING AUTOMATIONS ====================
        # Office - Motion detection with long timeout for desk work
        {
          id = "office_lights_on_motion";
          alias = "Office lights on with motion";
          description = "Turn on office lights when motion detected, using adaptive lighting";
          mode = "restart";
          trigger = [
            {
              platform = "state";
              entity_id = "binary_sensor.hue_motion_sensor_1_motion";
              to = "on";
            }
          ];
          condition = [
            {
              condition = "numeric_state";
              entity_id = "sensor.hue_motion_sensor_1_light_level";
              below = 40; # Only if ambient light is low
            }
            {
              condition = "state";
              entity_id = "input_boolean.sleep_mode";
              state = "off";
            }
          ];
          action = [
            {
              service = "light.turn_on";
              target.entity_id = [
                "light.office" # Controls all office lights
              ];
              # Adaptive lighting will handle color/brightness
            }
          ];
        }
        {
          id = "office_lights_dim_no_motion";
          alias = "Dim office lights after inactivity";
          description = "Dim lights after 10 minutes of no motion (don't turn off, might be reading)";
          mode = "restart";
          trigger = [
            {
              platform = "state";
              entity_id = "binary_sensor.hue_motion_sensor_1_motion";
              to = "off";
              for = "00:10:00";
            }
          ];
          action = [
            {
              service = "light.turn_on";
              target.entity_id = [
                "light.office"
              ];
              data = {
                brightness_pct = 30;
                transition = 5;
              };
            }
          ];
        }
        {
          id = "office_lights_off_extended_no_motion";
          alias = "Turn off office lights after extended inactivity";
          description = "Turn off lights after 30 minutes of no motion";
          mode = "restart";
          trigger = [
            {
              platform = "state";
              entity_id = "binary_sensor.hue_motion_sensor_1_motion";
              to = "off";
              for = "00:30:00";
            }
          ];
          action = [
            {
              service = "light.turn_off";
              target.entity_id = [
                "light.office"
              ];
              data = {
                transition = 10;
              };
            }
          ];
        }

        # Kitchen - No smart lights in kitchen yet (only voice assistant LED ring)
        # TODO: Uncomment these automations once kitchen lights are added to Home Assistant
        # {
        #   id = "kitchen_lights_on_motion";
        #   alias = "Kitchen lights on with motion";
        #   description = "Immediately turn on kitchen lights for safety during cooking";
        #   mode = "restart";
        #   trigger = [
        #     {
        #       platform = "state";
        #       entity_id = "binary_sensor.kitchen_motion";
        #       to = "on";
        #     }
        #   ];
        #   condition = [
        #     {
        #       condition = "numeric_state";
        #       entity_id = "sensor.kitchen_light_level";
        #       below = 50;
        #     }
        #   ];
        #   action = [
        #     {
        #       service = "light.turn_on";
        #       target.entity_id = [ "light.kitchen" ];
        #     }
        #   ];
        # }
        # {
        #   id = "kitchen_lights_off_no_motion";
        #   alias = "Turn off kitchen lights when empty";
        #   description = "Turn off lights after 5 minutes of no motion (task-based room)";
        #   mode = "restart";
        #   trigger = [
        #     {
        #       platform = "state";
        #       entity_id = "binary_sensor.kitchen_motion";
        #       to = "off";
        #       for = "00:05:00";
        #     }
        #   ];
        #   action = [
        #     {
        #       service = "light.turn_off";
        #       target.entity_id = [ "light.kitchen" ];
        #       data = {
        #         transition = 5;
        #       };
        #     }
        #   ];
        # }

        # Living Room - No motion sensor yet
        # TODO: Add motion sensor and uncomment this automation for motion-based assistance
        # {
        #   id = "living_room_prevent_auto_off_if_occupied";
        #   alias = "Prevent living room lights turning off if occupied";
        #   description = "Cancel any scheduled turn-offs if motion detected";
        #   mode = "restart";
        #   trigger = [
        #     {
        #       platform = "state";
        #       entity_id = "binary_sensor.living_room_motion";
        #       to = "on";
        #     }
        #   ];
        #   action = [
        #     # This automation serves to restart and cancel timeout automations
        #     {
        #       delay = "00:00:01";
        #     }
        #   ];
        # }

        # Hallway - No smart lights in hallway yet
        # TODO: Uncomment these automations once hallway lights are added to Home Assistant
        # {
        #   id = "hallway_night_light";
        #   alias = "Hallway night light mode";
        #   description = "Low warm light for safe nighttime navigation";
        #   mode = "restart";
        #   trigger = [
        #     {
        #       platform = "state";
        #       entity_id = "binary_sensor.hallway_motion";
        #       to = "on";
        #     }
        #   ];
        #   condition = [
        #     {
        #       condition = "state";
        #       entity_id = "input_boolean.sleep_mode";
        #       state = "on";
        #     }
        #   ];
        #   action = [
        #     {
        #       service = "light.turn_on";
        #       target.entity_id = [ "light.hallway" ];
        #       data = {
        #         brightness_pct = 5;
        #         color_temp_kelvin = 2000;
        #         transition = 1;
        #       };
        #     }
        #   ];
        # }
        # {
        #   id = "hallway_night_light_off";
        #   alias = "Turn off hallway night light";
        #   description = "Turn off night light after 2 minutes of no motion";
        #   mode = "restart";
        #   trigger = [
        #     {
        #       platform = "state";
        #       entity_id = "binary_sensor.hallway_motion";
        #       to = "off";
        #       for = "00:02:00";
        #     }
        #   ];
        #   condition = [
        #     {
        #       condition = "state";
        #       entity_id = "input_boolean.sleep_mode";
        #       state = "on";
        #     }
        #   ];
        #   action = [
        #     {
        #       service = "light.turn_off";
        #       target.entity_id = [ "light.hallway" ];
        #       data = {
        #         transition = 2;
        #       };
        #     }
        #   ];
        # }

        # ==================== SCENE INTEGRATION WITH ADAPTIVE LIGHTING ====================
        # Disable adaptive lighting for scenes with specific colors
        {
          id = "disable_adaptive_lighting_for_movie_scene";
          alias = "Disable adaptive lighting during movie time";
          description = "Put living room adaptive lighting in manual mode for movie scene";
          mode = "single";
          trigger = [
            {
              platform = "state";
              entity_id = "scene.movie_time";
              to = "on";
            }
          ];
          action = [
            {
              service = "adaptive_lighting.set_manual_control";
              target.entity_id = "switch.adaptive_lighting_living_room";
              data = {
                manual_control = true;
              };
            }
          ];
        }
        {
          id = "disable_adaptive_lighting_for_focus_scene";
          alias = "Disable adaptive lighting during focus mode";
          description = "Put office adaptive lighting in manual mode for focus scene";
          mode = "single";
          trigger = [
            {
              platform = "state";
              entity_id = "scene.focus_mode";
              to = "on";
            }
          ];
          action = [
            {
              service = "adaptive_lighting.set_manual_control";
              target.entity_id = "switch.adaptive_lighting_office";
              data = {
                manual_control = true;
              };
            }
          ];
        }
        # Re-enable adaptive lighting after 4 hours (assumes scene usage has ended)
        {
          id = "reenable_adaptive_lighting_after_scene";
          alias = "Re-enable adaptive lighting after extended scene use";
          description = "Resume adaptive lighting after 4 hours of manual control";
          mode = "restart";
          trigger = [
            {
              platform = "state";
              entity_id = [
                "switch.adaptive_lighting_living_room"
                "switch.adaptive_lighting_office"
              ];
              attribute = "manual_control";
              to = true;
              for = "04:00:00";
            }
          ];
          action = [
            {
              service = "adaptive_lighting.set_manual_control";
              target.entity_id = "{{ trigger.entity_id }}";
              data = {
                manual_control = false;
              };
            }
          ];
        }

        # ==================== ADAPTIVE LIGHTING SLEEP MODE SYNC ====================
        {
          id = "enable_adaptive_lighting_sleep_mode";
          alias = "Enable adaptive lighting sleep mode";
          description = "Activate sleep mode on all adaptive lighting instances when sleep mode is on";
          mode = "single";
          trigger = [
            {
              platform = "state";
              entity_id = "input_boolean.sleep_mode";
              to = "on";
            }
          ];
          action = [
            {
              service = "adaptive_lighting.set_manual_control";
              target.entity_id = [
                "switch.adaptive_lighting_office"
                "switch.adaptive_lighting_living_room"
                "switch.adaptive_lighting_dining_room"
              ];
              data = {
                manual_control = false;
              };
            }
            {
              service = "switch.turn_on";
              target.entity_id = [
                "switch.adaptive_lighting_sleep_mode_office"
                "switch.adaptive_lighting_sleep_mode_living_room"
                "switch.adaptive_lighting_sleep_mode_dining_room"
              ];
            }
          ];
        }
        {
          id = "disable_adaptive_lighting_sleep_mode";
          alias = "Disable adaptive lighting sleep mode";
          description = "Deactivate sleep mode on all adaptive lighting instances";
          mode = "single";
          trigger = [
            {
              platform = "state";
              entity_id = "input_boolean.sleep_mode";
              to = "off";
            }
          ];
          action = [
            {
              service = "switch.turn_off";
              target.entity_id = [
                "switch.adaptive_lighting_sleep_mode_office"
                "switch.adaptive_lighting_sleep_mode_living_room"
                "switch.adaptive_lighting_sleep_mode_dining_room"
              ];
            }
          ];
        }

        # ==================== PRESENCE AUTOMATIONS ====================
        {
          id = "set_away_mode_when_leaving";
          alias = "Set Away mode when leaving home";
          description = "Automatically switch to Away mode when everyone leaves";
          mode = "single";
          trigger = [
            {
              platform = "state";
              entity_id = "person.lewis";
              from = "home";
              to = "not_home";
              for = "00:10:00"; # Wait 10 minutes to avoid false triggers
            }
          ];
          action = [
            {
              service = "input_select.select_option";
              target.entity_id = "input_select.house_mode";
              data.option = "Away";
            }
            # Uncomment once lights connected:
            # {
            #   service = "light.turn_off";
            #   target.entity_id = "all";
            # }
          ];
        }
        {
          id = "set_home_mode_when_arriving";
          alias = "Set Home mode when arriving";
          description = "Switch to Home mode when arriving";
          mode = "single";
          trigger = [
            {
              platform = "state";
              entity_id = "person.lewis";
              from = "not_home";
              to = "home";
            }
          ];
          condition = [
            {
              condition = "not";
              conditions = [
                {
                  condition = "state";
                  entity_id = "input_select.house_mode";
                  state = "Guest";
                }
              ];
            }
          ];
          action = [
            {
              service = "input_select.select_option";
              target.entity_id = "input_select.house_mode";
              data.option = "Home";
            }
          ];
        }

        # ==================== CLIMATE AUTOMATIONS ====================
        {
          id = "climate_away_mode";
          alias = "Set heating to eco when away";
          description = "Lower heating temperature when house is in Away mode";
          mode = "single";
          trigger = [
            {
              platform = "state";
              entity_id = "input_select.house_mode";
              to = "Away";
            }
          ];
          action = [
            # Uncomment once Tado is connected:
            # {
            #   service = "climate.set_temperature";
            #   target.entity_id = "climate.tado";
            #   data.temperature = 16;
            # }
            {
              service = "input_boolean.turn_off";
              target.entity_id = "input_boolean.sleep_mode";
            }
          ];
        }
        {
          id = "climate_home_mode";
          alias = "Set comfortable temperature when home";
          description = "Raise heating when returning home";
          mode = "single";
          trigger = [
            {
              platform = "state";
              entity_id = "input_select.house_mode";
              to = "Home";
            }
          ];
          action = [
            # Uncomment once Tado is connected:
            # {
            #   service = "climate.set_temperature";
            #   target.entity_id = "climate.tado";
            #   data.temperature = 20;
            # }
            {
              service = "input_boolean.turn_off";
              target.entity_id = "input_boolean.sleep_mode";
            }
          ];
        }
        {
          id = "climate_sleep_mode";
          alias = "Lower heating at bedtime";
          description = "Reduce temperature for sleeping";
          mode = "single";
          trigger = [
            {
              platform = "state";
              entity_id = "input_boolean.sleep_mode";
              to = "on";
            }
          ];
          action = [
            {
              service = "input_select.select_option";
              target.entity_id = "input_select.house_mode";
              data.option = "Sleep";
            }
            # Uncomment once Tado is connected:
            # {
            #   service = "climate.set_temperature";
            #   target.entity_id = "climate.tado";
            #   data.temperature = 18;
            # }
          ];
        }

        # ==================== MORNING ROUTINE ====================
        {
          id = "morning_wakeup";
          alias = "Morning wake up routine";
          description = "Disable sleep mode and set house to Home mode (weekdays only)";
          mode = "single";
          trigger = [
            {
              platform = "time";
              at = "07:00:00";
            }
          ];
          condition = [
            {
              condition = "state";
              entity_id = "input_boolean.sleep_mode";
              state = "on";
            }
            {
              condition = "time";
              weekday = [
                "mon"
                "tue"
                "wed"
                "thu"
                "fri"
              ];
            }
          ];
          action = [
            # Turn off sleep mode (this disables adaptive lighting sleep mode)
            {
              service = "input_boolean.turn_off";
              target.entity_id = "input_boolean.sleep_mode";
            }
            {
              service = "input_select.select_option";
              target.entity_id = "input_select.house_mode";
              data.option = "Home";
            }
            # TODO: Add sunrise simulation when bedroom lights are added
            # TODO: Add kitchen light turn-on when kitchen lights are added
          ];
        }

        # ==================== NOTIFICATIONS ====================
        {
          id = "notify_low_phone_battery";
          alias = "Notify when phone battery is low at home";
          description = "Remind to charge phone if battery low while at home";
          mode = "single";
          trigger = [
            {
              platform = "numeric_state";
              entity_id = "sensor.lewiss_iphone_battery_level";
              below = 20;
            }
          ];
          condition = [
            {
              condition = "state";
              entity_id = "person.lewis";
              state = "home";
            }
          ];
          action = [
            {
              service = "notify.mobile_app_lewiss_iphone";
              data = {
                title = "Battery Low";
                message = "Your phone battery is below 20%. Time to charge!";
              };
            }
          ];
        }
      ];
    };

    containersSupplemental = {
      enable = true;
      uid = 985;
      gid = 976;
      termix = {
        enable = true;
      };

      janitorr = {
        enable = true;

        extraConfig = {

          clients = {
            sonarr.url = "https://sonarr.blmt.io";
            radarr.url = "https://radarr.blmt.io";
            jellyfin.url = "https://jellyfin.blmt.io";
          };

          application = {

            "dry-run" = false;

            "leaving-soon" = "21d";

            "media-deletion" = {
              enabled = true;

              "movie-expiration" = {
                "5" = "30d";
                "10" = "60d";
                "15" = "120d";
                "20" = "180d";
              };
              "season-expiration" = {
                "5" = "30d";
                "10" = "45d";
                "15" = "90d";
                "20" = "180d";
              };
            };

            "tag-based-deletion" = {
              enabled = true;
              "minimum-free-disk-percent" = 20;
              schedules = [

              ];
            };

            "episode-deletion" = {
              enabled = false;
            };
          };
        };
      };

      cleanuparr = {
        enable = true;
        dataPath = "/mnt/storage";
      };
    };
  };
}
