_:
let

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

        parameters = {

          "basic.to_if_alone_timeout_milliseconds" = 200;

          "basic.simultaneous_threshold_milliseconds" = 50;
        };

        complex_modifications = {
          rules = [ ];
        };

        simple_modifications = [ ];

        virtual_hid_keyboard = {
          country_code = 0;
          indicate_sticky_modifier_keys_state = true;
          mouse_key_xy_scale = 100;
        };
      }
    ];
  };
in
{

  home.file.".config/karabiner/karabiner.json" = {
    text = builtins.toJSON karabinerConfig;

    force = true;
  };

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
              to = [ { key_code = "left_control"; } ];
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
              to = [ { key_code = "left_command"; } ];
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
              to = [ { key_code = "left_option"; } ];
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
              to = [ { key_code = "right_command"; } ];
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
              to = [ { key_code = "right_option"; } ];
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
              to = [ { shell_command = "open -a Ghostty"; } ];
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
              to = [ { shell_command = "open -a \"Safari\" || open -a \"Arc\" || open -a \"Google Chrome\""; } ];
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

            {
              type = "basic";
              from = {
                key_code = "f16";
              };
              to = [
                {
                  key_code = "return_or_enter";
                  modifiers = [
                    "left_control"
                    "left_option"
                  ];
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

            {
              type = "basic";
              from = {
                key_code = "f17";
              };
              to = [
                {
                  key_code = "left_arrow";
                  modifiers = [
                    "left_control"
                    "left_option"
                  ];
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

            {
              type = "basic";
              from = {
                key_code = "f18";
              };
              to = [
                {
                  key_code = "c";
                  modifiers = [
                    "left_control"
                    "left_option"
                  ];
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

            {
              type = "basic";
              from = {
                key_code = "f19";
              };
              to = [
                {
                  key_code = "right_arrow";
                  modifiers = [
                    "left_control"
                    "left_option"
                  ];
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
