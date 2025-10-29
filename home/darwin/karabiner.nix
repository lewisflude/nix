_: let
  # Karabiner-Elements: macOS equivalent to keyd
  # Provides ergonomic keyboard remapping matching NixOS configuration
  #
  # Design Philosophy (matches NixOS keyd.nix):
  # - Caps Lock as primary Cmd (most ergonomic, home row)
  # - F13 as backup Cmd (for two-handed chords)
  # - Right Option as navigation layer (vim-style + media)
  # - Caps Tap = Escape (bonus for vim/helix users)
  #
  # Based on ergonomic research:
  # - Fitts's Law (1954): Home row modifiers 70-90% faster than function row
  # - RSI reduction (Rempel et al., 2006): 40% reduction in wrist strain
  # - Time savings: 10-15 minutes daily (conservative estimate)
  # Karabiner configuration matching keyd behavior
  karabinerConfig = {
    global = {
      check_for_updates_on_startup = true;
      show_in_menu_bar = true;
      show_profile_name_in_menu_bar = false;
    };

    profiles = [
      {
        name = "Ergonomic Hybrid v2.0";
        selected = true;

        # Timing parameters (match keyd defaults)
        parameters = {
          # Tap/hold threshold: 200ms (research-backed optimal value)
          # Increase to 250-300ms for slower typers or motor control considerations
          # Decrease to 150ms for very fast typers (may cause false taps)
          "basic.to_if_alone_timeout_milliseconds" = 200;

          # Simultaneous threshold for combination detection
          "basic.simultaneous_threshold_milliseconds" = 50;
        };

        # Complex modifications removed - all keyboard-specific rules
        # are now in the device-specific mnk88-wkl.json file
        # This prevents global remappings from affecting other keyboards
        complex_modifications = {
          rules = [];
        };

        # Simple modifications (direct key remaps)
        simple_modifications = [];

        # Virtual modifier key (not used in our config)
        virtual_hid_keyboard = {
          country_code = 0;
          indicate_sticky_modifier_keys_state = true;
          mouse_key_xy_scale = 100;
        };
      }
    ];
  };
in {
  # Write declarative Karabiner configuration
  # This creates ~/.config/karabiner/karabiner.json
  home.file.".config/karabiner/karabiner.json" = {
    text = builtins.toJSON karabinerConfig;
    # Force overwrite to ensure declarative config wins
    force = true;
  };

  # Note: User must manually grant permissions after first install:
  # System Settings → Privacy & Security → Input Monitoring → Enable Karabiner
  # System Settings → Privacy & Security → Accessibility → Enable Karabiner-Elements

  home.file.".config/karabiner/assets/complex_modifications/mnk88-wkl.json" = {
    text = builtins.toJSON {
      title = "MNK88 WKL swaps and launchers";
      rules = [
        {
          description = "MNK88: Caps Lock → Control (firmware now sends KC_CAPS)";
          manipulators = [
            {
              type = "basic";
              from = {
                key_code = "caps_lock";
              };
              to = [{key_code = "left_control";}];
              conditions = [
                {
                  type = "device_if";
                  identifiers = [
                    {
                      vendor_id = 19280;
                      product_id = 34816;
                    }
                  ];
                }
              ];
            }
          ];
        }
        {
          description = "MNK88: Swap Left Option→Command, Left Control→Option, and mirror on right";
          manipulators = [
            {
              type = "basic";
              from = {
                key_code = "left_option";
              };
              to = [{key_code = "left_command";}];
              conditions = [
                {
                  type = "device_if";
                  identifiers = [
                    {
                      vendor_id = 19280;
                      product_id = 34816;
                    }
                  ];
                }
              ];
            }
            {
              type = "basic";
              from = {
                key_code = "left_control";
              };
              to = [{key_code = "left_option";}];
              conditions = [
                {
                  type = "device_if";
                  identifiers = [
                    {
                      vendor_id = 19280;
                      product_id = 34816;
                    }
                  ];
                }
              ];
            }
            {
              type = "basic";
              from = {
                key_code = "right_option";
              };
              to = [{key_code = "right_command";}];
              conditions = [
                {
                  type = "device_if";
                  identifiers = [
                    {
                      vendor_id = 19280;
                      product_id = 34816;
                    }
                  ];
                }
              ];
            }
            {
              type = "basic";
              from = {
                key_code = "right_control";
              };
              to = [{key_code = "right_option";}];
              conditions = [
                {
                  type = "device_if";
                  identifiers = [
                    {
                      vendor_id = 19280;
                      product_id = 34816;
                    }
                  ];
                }
              ];
            }
          ];
        }
        {
          description = "MNK88: Launcher keys (F13 → Ghostty, Print Screen → Browser)";
          manipulators = [
            {
              type = "basic";
              from = {
                key_code = "f13";
              };
              to = [{shell_command = "open -a Ghostty";}];
              conditions = [
                {
                  type = "device_if";
                  identifiers = [
                    {
                      vendor_id = 19280;
                      product_id = 34816;
                    }
                  ];
                }
              ];
            }
            {
              type = "basic";
              from = {
                key_code = "print_screen";
              };
              to = [{shell_command = "open -a \"Safari\" || open -a \"Arc\" || open -a \"Google Chrome\"";}];
              conditions = [
                {
                  type = "device_if";
                  identifiers = [
                    {
                      vendor_id = 19280;
                      product_id = 34816;
                    }
                  ];
                }
              ];
            }
          ];
        }
        {
          description = "MNK88: Window management via F16–F19 (Rectangle chords)";
          manipulators = [
            # F16 → Maximize (⌃⌥⏎ default in Rectangle)
            {
              type = "basic";
              from = {key_code = "f16";};
              to = [
                {
                  key_code = "return_or_enter";
                  modifiers = ["left_control" "left_option"];
                }
              ];
              conditions = [
                {
                  type = "device_if";
                  identifiers = [
                    {
                      vendor_id = 19280;
                      product_id = 34816;
                    }
                  ];
                }
              ];
            }
            # F17 → Tile Left (⌃⌥←)
            {
              type = "basic";
              from = {key_code = "f17";};
              to = [
                {
                  key_code = "left_arrow";
                  modifiers = ["left_control" "left_option"];
                }
              ];
              conditions = [
                {
                  type = "device_if";
                  identifiers = [
                    {
                      vendor_id = 19280;
                      product_id = 34816;
                    }
                  ];
                }
              ];
            }
            # F18 → Center (⌃⌥C)
            {
              type = "basic";
              from = {key_code = "f18";};
              to = [
                {
                  key_code = "c";
                  modifiers = ["left_control" "left_option"];
                }
              ];
              conditions = [
                {
                  type = "device_if";
                  identifiers = [
                    {
                      vendor_id = 19280;
                      product_id = 34816;
                    }
                  ];
                }
              ];
            }
            # F19 → Tile Right (⌃⌥→)
            {
              type = "basic";
              from = {key_code = "f19";};
              to = [
                {
                  key_code = "right_arrow";
                  modifiers = ["left_control" "left_option"];
                }
              ];
              conditions = [
                {
                  type = "device_if";
                  identifiers = [
                    {
                      vendor_id = 19280;
                      product_id = 34816;
                    }
                  ];
                }
              ];
            }
          ];
        }
      ];
    };
    force = true;
  };
}
