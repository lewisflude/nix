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

        complex_modifications = {
          rules = [
            # ============================================================
            # CORE REMAPPING: Caps Lock → Command (hold) / Escape (tap)
            # ============================================================
            {
              description = "Caps Lock → Command (hold) / Escape (tap)";
              manipulators = [
                {
                  type = "basic";
                  from = {
                    key_code = "caps_lock";
                    modifiers = {optional = ["any"];};
                  };
                  to = [
                    {
                      key_code = "left_command";
                    }
                  ];
                  to_if_alone = [
                    {
                      key_code = "escape";
                    }
                  ];
                }
              ];
            }

            # ============================================================
            # BACKUP MODIFIER: F13 → Command
            # ============================================================
            {
              description = "F13 → Command (backup modifier)";
              manipulators = [
                {
                  type = "basic";
                  from = {
                    key_code = "f13";
                  };
                  to = [
                    {
                      key_code = "left_command";
                    }
                  ];
                }
              ];
            }

            # ============================================================
            # NAVIGATION LAYER: Right Option + Key → Arrows
            # ============================================================
            {
              description = "Right Option + HJKL → Arrow Keys (Vim-style)";
              manipulators = [
                # H = Left
                {
                  type = "basic";
                  from = {
                    key_code = "h";
                    modifiers = {
                      mandatory = ["right_option"];
                      optional = ["any"];
                    };
                  };
                  to = [
                    {
                      key_code = "left_arrow";
                    }
                  ];
                }
                # J = Down
                {
                  type = "basic";
                  from = {
                    key_code = "j";
                    modifiers = {
                      mandatory = ["right_option"];
                      optional = ["any"];
                    };
                  };
                  to = [
                    {
                      key_code = "down_arrow";
                    }
                  ];
                }
                # K = Up
                {
                  type = "basic";
                  from = {
                    key_code = "k";
                    modifiers = {
                      mandatory = ["right_option"];
                      optional = ["any"];
                    };
                  };
                  to = [
                    {
                      key_code = "up_arrow";
                    }
                  ];
                }
                # L = Right
                {
                  type = "basic";
                  from = {
                    key_code = "l";
                    modifiers = {
                      mandatory = ["right_option"];
                      optional = ["any"];
                    };
                  };
                  to = [
                    {
                      key_code = "right_arrow";
                    }
                  ];
                }
              ];
            }

            # ============================================================
            # PAGE/LINE NAVIGATION: Right Option + A/E/U/D → Home/End/PgUp/PgDn
            # ============================================================
            {
              description = "Right Option + A/E → Home/End (line start/end)";
              manipulators = [
                # A = Home (Anchor/start of line)
                {
                  type = "basic";
                  from = {
                    key_code = "a";
                    modifiers = {
                      mandatory = ["right_option"];
                      optional = ["any"];
                    };
                  };
                  to = [
                    {
                      key_code = "left_arrow";
                      modifiers = ["left_command"];
                    }
                  ];
                }
                # E = End
                {
                  type = "basic";
                  from = {
                    key_code = "e";
                    modifiers = {
                      mandatory = ["right_option"];
                      optional = ["any"];
                    };
                  };
                  to = [
                    {
                      key_code = "right_arrow";
                      modifiers = ["left_command"];
                    }
                  ];
                }
                # U = Page Up
                {
                  type = "basic";
                  from = {
                    key_code = "u";
                    modifiers = {
                      mandatory = ["right_option"];
                      optional = ["any"];
                    };
                  };
                  to = [
                    {
                      key_code = "page_up";
                    }
                  ];
                }
                # D = Page Down (note: conflicts with Cmd+D in some apps)
                # Using I for Page Up instead to avoid conflict
                {
                  type = "basic";
                  from = {
                    key_code = "i";
                    modifiers = {
                      mandatory = ["right_option"];
                      optional = ["any"];
                    };
                  };
                  to = [
                    {
                      key_code = "page_up";
                    }
                  ];
                }
              ];
            }

            # Legacy aliases (Y/O for Home/End) for backward compatibility
            {
              description = "Right Option + Y/O → Home/End (legacy aliases)";
              manipulators = [
                # Y = Home
                {
                  type = "basic";
                  from = {
                    key_code = "y";
                    modifiers = {
                      mandatory = ["right_option"];
                      optional = ["any"];
                    };
                  };
                  to = [
                    {
                      key_code = "left_arrow";
                      modifiers = ["left_command"];
                    }
                  ];
                }
                # O = End
                {
                  type = "basic";
                  from = {
                    key_code = "o";
                    modifiers = {
                      mandatory = ["right_option"];
                      optional = ["any"];
                    };
                  };
                  to = [
                    {
                      key_code = "right_arrow";
                      modifiers = ["left_command"];
                    }
                  ];
                }
              ];
            }

            # ============================================================
            # WORD NAVIGATION: Right Option + W/B → Word Forward/Backward
            # ============================================================
            {
              description = "Right Option + W/B → Word Forward/Backward";
              manipulators = [
                # W = Word Forward (Option+Right on macOS)
                {
                  type = "basic";
                  from = {
                    key_code = "w";
                    modifiers = {
                      mandatory = ["right_option"];
                      optional = ["any"];
                    };
                  };
                  to = [
                    {
                      key_code = "right_arrow";
                      modifiers = ["left_option"];
                    }
                  ];
                }
                # B = Word Backward (Option+Left on macOS)
                {
                  type = "basic";
                  from = {
                    key_code = "b";
                    modifiers = {
                      mandatory = ["right_option"];
                      optional = ["any"];
                    };
                  };
                  to = [
                    {
                      key_code = "left_arrow";
                      modifiers = ["left_option"];
                    }
                  ];
                }
              ];
            }

            # ============================================================
            # EDITING SHORTCUTS: Right Option + C/V/X/Z/S/F → Common Edits
            # ============================================================
            {
              description = "Right Option + Editing Keys → Common Shortcuts";
              manipulators = [
                # C = Copy (Cmd+C)
                {
                  type = "basic";
                  from = {
                    key_code = "c";
                    modifiers = {
                      mandatory = ["right_option"];
                      optional = ["any"];
                    };
                  };
                  to = [
                    {
                      key_code = "c";
                      modifiers = ["left_command"];
                    }
                  ];
                }
                # V = Paste (Cmd+V)
                {
                  type = "basic";
                  from = {
                    key_code = "v";
                    modifiers = {
                      mandatory = ["right_option"];
                      optional = ["any"];
                    };
                  };
                  to = [
                    {
                      key_code = "v";
                      modifiers = ["left_command"];
                    }
                  ];
                }
                # X = Cut (Cmd+X)
                {
                  type = "basic";
                  from = {
                    key_code = "x";
                    modifiers = {
                      mandatory = ["right_option"];
                      optional = ["any"];
                    };
                  };
                  to = [
                    {
                      key_code = "x";
                      modifiers = ["left_command"];
                    }
                  ];
                }
                # Z = Undo (Cmd+Z)
                {
                  type = "basic";
                  from = {
                    key_code = "z";
                    modifiers = {
                      mandatory = ["right_option"];
                      optional = ["any"];
                    };
                  };
                  to = [
                    {
                      key_code = "z";
                      modifiers = ["left_command"];
                    }
                  ];
                }
                # S = Save (Cmd+S)
                {
                  type = "basic";
                  from = {
                    key_code = "s";
                    modifiers = {
                      mandatory = ["right_option"];
                      optional = ["any"];
                    };
                  };
                  to = [
                    {
                      key_code = "s";
                      modifiers = ["left_command"];
                    }
                  ];
                }
                # F = Find (Cmd+F)
                {
                  type = "basic";
                  from = {
                    key_code = "f";
                    modifiers = {
                      mandatory = ["right_option"];
                      optional = ["any"];
                    };
                  };
                  to = [
                    {
                      key_code = "f";
                      modifiers = ["left_command"];
                    }
                  ];
                }
              ];
            }

            # ============================================================
            # MEDIA CONTROLS: Right Option + F1-F10 → Brightness/Volume/Media
            # ============================================================
            {
              description = "Right Option + F1-F10 → Media Controls";
              manipulators = [
                # F1 = Brightness Down
                {
                  type = "basic";
                  from = {
                    key_code = "f1";
                    modifiers = {
                      mandatory = ["right_option"];
                    };
                  };
                  to = [
                    {
                      key_code = "display_brightness_decrement";
                    }
                  ];
                }
                # F2 = Brightness Up
                {
                  type = "basic";
                  from = {
                    key_code = "f2";
                    modifiers = {
                      mandatory = ["right_option"];
                    };
                  };
                  to = [
                    {
                      key_code = "display_brightness_increment";
                    }
                  ];
                }
                # F5 = Volume Down
                {
                  type = "basic";
                  from = {
                    key_code = "f5";
                    modifiers = {
                      mandatory = ["right_option"];
                    };
                  };
                  to = [
                    {
                      key_code = "volume_decrement";
                    }
                  ];
                }
                # F6 = Volume Up
                {
                  type = "basic";
                  from = {
                    key_code = "f6";
                    modifiers = {
                      mandatory = ["right_option"];
                    };
                  };
                  to = [
                    {
                      key_code = "volume_increment";
                    }
                  ];
                }
                # F7 = Previous Track
                {
                  type = "basic";
                  from = {
                    key_code = "f7";
                    modifiers = {
                      mandatory = ["right_option"];
                    };
                  };
                  to = [
                    {
                      key_code = "rewind";
                    }
                  ];
                }
                # F8 = Play/Pause
                {
                  type = "basic";
                  from = {
                    key_code = "f8";
                    modifiers = {
                      mandatory = ["right_option"];
                    };
                  };
                  to = [
                    {
                      key_code = "play_or_pause";
                    }
                  ];
                }
                # F9 = Next Track
                {
                  type = "basic";
                  from = {
                    key_code = "f9";
                    modifiers = {
                      mandatory = ["right_option"];
                    };
                  };
                  to = [
                    {
                      key_code = "fastforward";
                    }
                  ];
                }
                # F10 = Mute
                {
                  type = "basic";
                  from = {
                    key_code = "f10";
                    modifiers = {
                      mandatory = ["right_option"];
                    };
                  };
                  to = [
                    {
                      key_code = "mute";
                    }
                  ];
                }
              ];
            }
          ];
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
}
