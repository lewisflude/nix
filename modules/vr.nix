# VR Module - WiVRn + xrizer for Quest headsets
# References:
# - https://lvra.gitlab.io/docs/distros/nixos/
# - https://wiki.nixos.org/wiki/VR
#
# NOTE: VR also requires Steam integration configured in gaming.nix
# (PRESSURE_VESSEL env vars, xrizer in extraPkgs)
_: {
  flake.modules.nixos.vr =
    { pkgs, ... }:
    {
      services.wivrn = {
        enable = true;
        defaultRuntime = true;
        openFirewall = true;
        autoStart = true;
        highPriority = true;
        steam.importOXRRuntimes = true;

        # NVIDIA VR environment from LVRA wiki
        monadoEnvironment = {
          XRT_COMPOSITOR_USE_PRESENT_WAIT = "1";
          U_PACING_COMP_TIME_FRACTION_PERCENT = "90";
          U_PACING_COMP_MIN_TIME_MS = "5";
          XRT_COMPOSITOR_FORCE_WAYLAND_DIRECT = "1";
          IPC_EXIT_ON_DISCONNECT = "1";
        };

        # Dual NVENC AV1 encoding: splits left/right eyes across RTX 4090's
        # two NVENC engines for concurrent encoding. AV1 10-bit gives best
        # quality per bit; Quest 3 has native AV1 HW decode.
        config = {
          enable = true;
          json = {
            application = [ pkgs.wayvr ];
            bit-depth = 10;
            encoder =
              let
                eye = offset_x: group: {
                  encoder = "nvenc";
                  codec = "av1";
                  width = 0.5;
                  height = 1.0;
                  inherit offset_x group;
                  offset_y = 0.0;
                };
              in
              [
                (eye 0.0 0)
                (eye 0.5 1)
              ];
          };
        };
      };

      environment.systemPackages = [ pkgs.android-tools ];
    };

  flake.modules.homeManager.vr =
    {
      config,
      lib,
      pkgs,
      osConfig ? { },
      ...
    }:
    lib.mkIf (osConfig.services.wivrn.enable or false) {
      # xrizer OpenVR paths - points to nix store (accessible via PRESSURE_VESSEL_FILESYSTEMS_RO)
      xdg.configFile."openvr/openvrpaths.vrpath" = {
        force = true;
        text = builtins.toJSON {
          version = 1;
          jsonid = "vrpathreg";
          external_drivers = null;
          config = [ "${config.xdg.dataHome}/Steam/config" ];
          log = [ "${config.xdg.dataHome}/Steam/logs" ];
          runtime = [ "${pkgs.xrizer}/lib/xrizer" ];
        };
      };

      # Custom xrizer bindings for Quest Touch controllers
      # Fixes: handgrip pose (unsupported) → raw, grab input mode → click
      # See: https://github.com/Supreeeme/xrizer/issues/266
      xdg.dataFile."xrizer/bindings/oculustouch.json" =
        let
          # xrizer doesn't support SteamVR grab mode, use click with thresholds instead
          gripParams = {
            click_activate_threshold = "0.8";
            click_deactivate_threshold = "0.8";
            haptic_amplitude = "0";
          };
          hand = side: "/user/hand/${side}";
          lr = f: [
            (f "left")
            (f "right")
          ];
        in
        {
          text = builtins.toJSON {
            action_manifest_version = 0;
            alias_info = { };
            bindings = {
              "/actions/default" = {
                haptics = lr (side: {
                  output = "/actions/default/in/hapticvibration";
                  path = "${hand side}/output/haptic";
                });
                poses =
                  lr (side: {
                    output = "/actions/default/in/handpose${side}";
                    path = "${hand side}/pose/raw";
                  })
                  ++ lr (side: {
                    output = "/actions/default/in/handpointer${side}";
                    path = "${hand side}/pose/tip";
                  });
                skeleton = lr (side: {
                  output = "/actions/default/in/handskeleton${side}";
                  path = "${hand side}/input/skeleton/${side}";
                });
                sources =
                  lr (side: {
                    inputs.pull.output = "/actions/default/in/triggerpull";
                    mode = "trigger";
                    path = "${hand side}/input/trigger";
                  })
                  ++ lr (side: {
                    inputs.pull.output = "/actions/default/in/handcurl";
                    mode = "trigger";
                    path = "${hand side}/input/grip";
                  });
              };
              "/actions/menu" = {
                sources = [
                  {
                    inputs.click.output = "/actions/menu/in/togglemenu";
                    mode = "button";
                    path = "${hand "left"}/input/y";
                  }
                ]
                ++ lr (side: {
                  inputs.click.output = "/actions/menu/in/press";
                  mode = "button";
                  path = "${hand side}/input/trigger";
                });
              };
              "/actions/interact" = {
                sources =
                  lr (side: {
                    inputs.click.output = "/actions/interact/in/use";
                    mode = "button";
                    parameters = gripParams;
                    path = "${hand side}/input/trigger";
                  })
                  ++ lr (side: {
                    inputs.click.output = "/actions/interact/in/grab";
                    mode = "button";
                    parameters = gripParams;
                    path = "${hand side}/input/grip";
                  });
              };
              "/actions/move" = {
                sources = [
                  {
                    inputs.position.output = "/actions/move/in/move";
                    mode = "joystick";
                    parameters.exponent = "2";
                    path = "${hand "left"}/input/joystick";
                  }
                  {
                    inputs = {
                      east.output = "/actions/move/in/turnright";
                      west.output = "/actions/move/in/turnleft";
                    };
                    mode = "dpad";
                    parameters = {
                      deadzone_pct = "75";
                      overlap_pct = "0";
                      sticky = "true";
                      sub_mode = "touch";
                    };
                    path = "${hand "right"}/input/joystick";
                  }
                  {
                    inputs.position.output = "/actions/move/in/continuousturn";
                    mode = "joystick";
                    parameters = {
                      deadzone_pct = "25";
                      exponent = "2";
                      sticky_click = "false";
                    };
                    path = "${hand "right"}/input/joystick";
                  }
                ];
              };
              "/actions/ground" = {
                sources = [
                  {
                    inputs = {
                      north.output = "/actions/ground/in/jump";
                      south.output = "/actions/ground/in/crouch";
                    };
                    mode = "dpad";
                    parameters = {
                      deadzone_pct = "80";
                      overlap_pct = "0";
                      sticky = "true";
                      sub_mode = "touch";
                    };
                    path = "${hand "right"}/input/joystick";
                  }
                  {
                    inputs.click.output = "/actions/ground/in/sprint";
                    mode = "joystick";
                    parameters.sticky_click = "true";
                    path = "${hand "left"}/input/joystick";
                  }
                  {
                    inputs.click.output = "/actions/ground/in/commandsquad";
                    mode = "button";
                    path = "${hand "left"}/input/x";
                  }
                ];
              };
              "/actions/vehicle" = {
                sources = [
                  {
                    inputs.pull.output = "/actions/vehicle/in/accelerate";
                    mode = "trigger";
                    path = "${hand "right"}/input/trigger";
                  }
                  {
                    inputs.pull.output = "/actions/vehicle/in/brake";
                    mode = "trigger";
                    path = "${hand "left"}/input/trigger";
                  }
                  {
                    inputs.click.output = "/actions/vehicle/in/leave";
                    mode = "button";
                    path = "${hand "left"}/input/x";
                  }
                  {
                    inputs.click.output = "/actions/vehicle/in/handbrake";
                    mode = "button";
                    path = "${hand "right"}/input/a";
                  }
                  {
                    inputs.click.output = "/actions/vehicle/in/attack";
                    mode = "button";
                    path = "${hand "right"}/input/b";
                  }
                  {
                    inputs.click.output = "/actions/vehicle/in/attack2";
                    mode = "button";
                    parameters = gripParams;
                    path = "${hand "right"}/input/grip";
                  }
                  {
                    inputs.click.output = "/actions/vehicle/in/boost";
                    mode = "joystick";
                    parameters.sticky_click = "true";
                    path = "${hand "left"}/input/joystick";
                  }
                  {
                    inputs.click.output = "/actions/vehicle/in/lights";
                    mode = "button";
                    parameters.touchy_click = "false";
                    path = "${hand "right"}/input/joystick";
                  }
                ];
              };
              "/actions/weapon" = {
                sources =
                  lr (side: {
                    inputs.click.output = "/actions/weapon/in/attack";
                    mode = "button";
                    parameters.haptic_amplitude = "0";
                    path = "${hand side}/input/trigger";
                  })
                  ++ [
                    {
                      inputs.click.output = "/actions/weapon/in/select";
                      mode = "button";
                      path = "${hand "right"}/input/joystick";
                    }
                    {
                      inputs.click.output = "/actions/weapon/in/eject";
                      mode = "button";
                      path = "${hand "right"}/input/a";
                    }
                    {
                      inputs.click.output = "/actions/weapon/in/attack2";
                      mode = "button";
                      path = "${hand "right"}/input/b";
                    }
                    {
                      inputs.click.output = "/actions/weapon/in/bugbaitsqueeze";
                      mode = "button";
                      path = "${hand "right"}/input/grip";
                    }
                  ];
              };
            };
            category = "steamvr_input";
            controller_type = "oculus_touch";
            description = "Quest Touch bindings with xrizer compatibility fixes";
            name = "Quest Touch (xrizer)";
            options = { };
            simulated_actions = [ ];
          };
        };

      home.packages = [ pkgs.wayvr ];
    };
}
