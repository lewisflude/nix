# Karabiner-Elements configuration (Darwin only)
# Dendritic pattern: nix-darwin service + home-manager config files
_:
{
  # ==========================================================================
  # Darwin System Configuration
  # ==========================================================================
  # NOTE: services.karabiner-elements.enable is disabled due to a bug in
  # nix-darwin where the launchd plist files are missing from the derivation.
  # Install Karabiner-Elements via Homebrew Cask instead:
  #   brew install --cask karabiner-elements
  # The home-manager config below still manages the JSON configuration.
  flake.modules.darwin.karabiner =
    _:
    {
      # services.karabiner-elements.enable = true;  # Disabled - use Homebrew
    };

  # ==========================================================================
  # Home-Manager Configuration
  # ==========================================================================
  # Provides the JSON configuration files for Karabiner-Elements
  flake.modules.homeManager.karabiner =
    { lib, pkgs, ... }:
    let
      mnk88Condition = {
        type = "device_if";
        identifiers = [
          {
            vendor_id = 19280;
            product_id = 34816;
          }
        ];
      };
      mapKey = from: to: {
        type = "basic";
        inherit from;
        to = [ to ];
        conditions = [ mnk88Condition ];
      };
      keyToKey = fromKey: toKey: mapKey { key_code = fromKey; } { key_code = toKey; };
      keyToShell = fromKey: cmd: mapKey { key_code = fromKey; } { shell_command = cmd; };
      keyToMod =
        fromKey: toKey: mods:
        mapKey { key_code = fromKey; } {
          key_code = toKey;
          modifiers = mods;
        };

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
            complex_modifications.rules = [ ];
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
    lib.mkIf pkgs.stdenv.isDarwin {
      home.file.".config/karabiner/karabiner.json" = {
        text = builtins.toJSON karabinerConfig;
        force = true;
      };

      home.file.".config/karabiner/assets/complex_modifications/mnk88-wkl.json" = {
        text = builtins.toJSON {
          title = "MNK88 WKL swaps and launchers";
          rules = [
            {
              description = "MNK88: Caps Lock → Control";
              manipulators = [ (keyToKey "caps_lock" "left_control") ];
            }
            {
              description = "MNK88: Swap Option↔Command, Control↔Option";
              manipulators = [
                (keyToKey "left_option" "left_command")
                (keyToKey "left_control" "left_option")
                (keyToKey "right_option" "right_command")
                (keyToKey "right_control" "right_option")
              ];
            }
            {
              description = "MNK88: Launcher keys (F13 → Ghostty, Print Screen → Browser)";
              manipulators = [
                (keyToShell "f13" "open -a Ghostty")
                (keyToShell "print_screen" "open -a \"Safari\" || open -a \"Arc\" || open -a \"Google Chrome\"")
              ];
            }
            {
              description = "MNK88: Window management via F16–F19 (Rectangle chords)";
              manipulators = [
                (keyToMod "f16" "return_or_enter" [
                  "left_control"
                  "left_option"
                ])
                (keyToMod "f17" "left_arrow" [
                  "left_control"
                  "left_option"
                ])
                (keyToMod "f18" "c" [
                  "left_control"
                  "left_option"
                ])
                (keyToMod "f19" "right_arrow" [
                  "left_control"
                  "left_option"
                ])
              ];
            }
          ];
        };
        force = true;
      };
    };
}
