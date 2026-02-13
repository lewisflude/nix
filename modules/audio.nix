# Audio - Simple PipeWire configuration
# Following NixOS wiki best practices: https://wiki.nixos.org/wiki/PipeWire
_: {
  # NixOS audio configuration
  flake.modules.nixos.audio = _: {
    # RTKit for realtime scheduling
    security.rtkit.enable = true;

    # Threaded IRQs for lower worst-case audio latency
    boot.kernelParams = [ "threadirqs" ];

    # Disable USB autosuspend for Apogee Symphony Desktop (vendor 0c60, product 002a)
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0c60", ATTR{idProduct}=="002a", ATTR{power/autosuspend}="-1", ATTR{power/control}="on"
    '';

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;

      # Allow PipeWire to switch graph sample rate to match content,
      # avoiding unnecessary resampling with the Apogee.
      # https://wiki.archlinux.org/title/PipeWire#Changing_the_allowed_sample_rate(s)
      extraConfig.pipewire."90-clock-rates" = {
        "context.properties" = {
          "default.clock.allowed-rates" = [
            44100
            48000
            88200
            96000
          ];
        };
      };

      # Virtual stereo sink/source for apps that crash with multichannel/pro-audio
      # devices (e.g. Apogee Symphony Desktop). Loopback modules present simple
      # stereo endpoints while routing to/from the Apogee's multichannel ALSA nodes.
      # https://docs.pipewire.org/page_module_loopback.html
      extraConfig.pipewire."91-virtual-sink" = {
        "context.objects" = [
          {
            # Virtual stereo source visible to PulseAudio clients (browsers, etc).
            # The loopback module's nodes have object.register=false which hides them,
            # so we use a null-audio-sink with Audio/Source/Virtual instead.
            factory = "adapter";
            args = {
              "factory.name" = "support.null-audio-sink";
              "node.name" = "Main-Input";
              "node.description" = "Main Input";
              "media.class" = "Audio/Source/Virtual";
              "audio.position" = "FL,FR";
              "monitor.channel-volumes" = true;
            };
          }
        ];
        "context.modules" = [
          {
            name = "libpipewire-module-loopback";
            args = {
              "capture.props" = {
                "node.name" = "Main-Output";
                "node.description" = "Main Output";
                "media.class" = "Audio/Sink";
                "audio.position" = "FL,FR";
              };
              "playback.props" = {
                "node.name" = "Main-Output-Playback";
                "audio.position" = "AUX0,AUX1";
                "stream.dont-remix" = true;
                "node.dont-reconnect" = false;
                "node.target" = "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.multichannel-output";
              };
            };
          }
          {
            # Route Apogee input channels 1-2 into the Main-Input virtual source
            name = "libpipewire-module-loopback";
            args = {
              "capture.props" = {
                "node.name" = "Main-Input-Capture";
                "audio.position" = "AUX0,AUX1";
                "stream.dont-remix" = true;
                "node.dont-reconnect" = false;
                "node.target" = "alsa_input.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.multichannel-input";
              };
              "playback.props" = {
                "node.name" = "Main-Input-Loopback";
                "audio.position" = "FL,FR";
                "stream.dont-remix" = true;
                "node.dont-reconnect" = false;
                "node.target" = "Main-Input";
              };
            };
          }
        ];
      };

      wireplumber.extraConfig = {
        # Give the Apogee highest priority so WirePlumber prefers it on reconnect
        "10-apogee-priority"."monitor.alsa.rules" = [
          {
            matches = [
              { "node.name" = "~alsa_output.usb-Apogee_Electronics*"; }
              { "node.name" = "~alsa_input.usb-Apogee_Electronics*"; }
            ];
            actions.update-props = {
              "priority.driver" = 2000;
              "priority.session" = 2000;
            };
          }
        ];
        # Disable device suspension to prevent audio popping/delay
        "10-disable-suspend"."monitor.alsa.rules" = [
          {
            matches = [ { "node.name" = "~alsa_*"; } ];
            actions.update-props."session.suspend-timeout-seconds" = 0;
          }
        ];

        # Bluetooth codecs (roles left at WirePlumber defaults to include A2DP)
        "10-bluez"."monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
        };

        # Set the virtual stereo sink/source as defaults
        "10-default-sink"."wireplumber.settings"."default.configured.audio.sink" = {
          name = "Main-Output";
        };
        "10-default-source"."wireplumber.settings"."default.configured.audio.source" = {
          name = "Main-Input";
        };
      };

    };
  };

  # Darwin audio (macOS uses CoreAudio natively)
  flake.modules.darwin.audio =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.ffmpeg-full
        pkgs.flac
        pkgs.lame
      ];
    };

  # Home-manager audio tools
  flake.modules.homeManager.audio =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.pwvucontrol
        pkgs.pavucontrol
        pkgs.playerctl
        pkgs.helvum
      ];
      services.playerctld.enable = true;
    };

  flake.modules.homeManager.audioDarwin =
    { pkgs, ... }:
    let
      audioKvmRecovery = pkgs.writeShellScript "audio-kvm-recovery" ''
        # Auto-switch to Apogee Symphony Desktop after KVM switch
        PREFERRED="Symphony Desktop"
        SWITCH="/opt/homebrew/bin/SwitchAudioSource"

        # Exit silently if SwitchAudioSource isn't installed yet
        [ -x "$SWITCH" ] || exit 0

        # Check if preferred device is available and switch if needed
        if "$SWITCH" -a -t output | /usr/bin/grep -q "$PREFERRED"; then
          CURRENT=$("$SWITCH" -c -t output)
          if [ "$CURRENT" != "$PREFERRED" ]; then
            "$SWITCH" -s "$PREFERRED" -t output
            /usr/bin/logger -t audio-kvm "Switched output to $PREFERRED"
          fi
        fi

        if "$SWITCH" -a -t input | /usr/bin/grep -q "$PREFERRED"; then
          CURRENT=$("$SWITCH" -c -t input)
          if [ "$CURRENT" != "$PREFERRED" ]; then
            "$SWITCH" -s "$PREFERRED" -t input
            /usr/bin/logger -t audio-kvm "Switched input to $PREFERRED"
          fi
        fi
      '';
    in
    {
      home.packages = [
        pkgs.lame
        pkgs.flac
      ];

      # Poll for Apogee reconnection after KVM switch
      launchd.agents.audio-kvm-recovery = {
        enable = true;
        config = {
          ProgramArguments = [ "${audioKvmRecovery}" ];
          StartInterval = 5;
          RunAtLoad = true;
          StandardOutPath = "/tmp/audio-kvm-recovery.log";
          StandardErrorPath = "/tmp/audio-kvm-recovery.err";
        };
      };
    };
}
