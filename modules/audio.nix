# Audio — PipeWire/WirePlumber configuration for the Apogee Symphony Desktop.
# Stereo "Main Output" / "Main Input" virtual sinks loopback to specific
# multichannel ports (AUX0/AUX1) on the Apogee. macOS uses CoreAudio with a
# launchd USB-reconnect helper.
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
      pulse.enable = true;

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

      # Virtual stereo endpoints for the Apogee Symphony Desktop.
      # null-audio-sinks provide user-facing stereo devices that appear
      # under Sinks/Sources (not Filters). Loopback modules route audio
      # to/from the Apogee's multichannel ALSA nodes in the background.
      extraConfig.pipewire."91-virtual-sink" = {
        "context.objects" = [
          {
            # User-facing stereo output — appears under Sinks in wpctl.
            # priority.session above the Apogee (2000) so it wins as the
            # initial default; user selections via DMS still take precedence.
            factory = "adapter";
            args = {
              "factory.name" = "support.null-audio-sink";
              "node.name" = "Main-Output";
              "node.description" = "Main Output";
              "media.class" = "Audio/Sink";
              "audio.position" = "FL,FR";
              "monitor.channel-volumes" = true;
              "monitor.passthrough" = true;
              "priority.session" = 3000;
            };
          }
          {
            # User-facing stereo input — appears under Sources in wpctl
            factory = "adapter";
            args = {
              "factory.name" = "support.null-audio-sink";
              "node.name" = "Main-Input";
              "node.description" = "Main Input";
              "media.class" = "Audio/Source/Virtual";
              "audio.position" = "FL,FR";
              "monitor.channel-volumes" = true;
              "priority.session" = 3000;
            };
          }
        ];
        "context.modules" = [
          {
            # Route Main-Output monitor → Apogee multichannel output (AUX0,AUX1)
            name = "libpipewire-module-loopback";
            args = {
              "capture.props" = {
                "node.name" = "Main-Output-Route-Capture";
                "audio.position" = "FL,FR";
                "stream.dont-remix" = true;
                "node.passive" = true;
                "target.object" = "Main-Output";
                "stream.capture.sink" = true;
              };
              "playback.props" = {
                "node.name" = "Main-Output-Route-Playback";
                "audio.position" = "AUX0,AUX1";
                "stream.dont-remix" = true;
                "node.passive" = true;
                "node.dont-fallback" = true;
                "node.linger" = true;
                "target.object" = "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.multichannel-output";
              };
            };
          }
          {
            # Route Apogee input channels 1-2 → Main-Input virtual source
            name = "libpipewire-module-loopback";
            args = {
              "capture.props" = {
                "node.name" = "Main-Input-Capture";
                "audio.position" = "AUX0,AUX1";
                "stream.dont-remix" = true;
                "node.passive" = true;
                "node.dont-fallback" = true;
                "node.linger" = true;
                "target.object" = "alsa_input.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.multichannel-input";
              };
              "playback.props" = {
                "node.name" = "Main-Input-Loopback";
                "audio.position" = "FL,FR";
                "stream.dont-remix" = true;
                "node.linger" = true;
                "target.object" = "Main-Input";
              };
            };
          }
        ];
      };

      wireplumber.extraConfig = {
        # Apogee: highest session/driver priority so WirePlumber prefers it on
        # reconnect, and disable suspend on it specifically to avoid pop/delay
        # on resume. Suspend stays default (5s) for any other ALSA node.
        "10-apogee"."monitor.alsa.rules" = [
          {
            matches = [
              { "node.name" = "~alsa_output.usb-Apogee_Electronics*"; }
              { "node.name" = "~alsa_input.usb-Apogee_Electronics*"; }
            ];
            actions.update-props = {
              "priority.driver" = 2000;
              "priority.session" = 2000;
              "session.suspend-timeout-seconds" = 0;
            };
          }
        ];
      };

    };
  };

  # Darwin audio (macOS uses CoreAudio natively)
  flake.modules.darwin.audio = _: {
    homebrew.brews = [ "bwfmetaedit" ];
    homebrew.casks = [
      "kid3"
      "ableton-live-suite"
    ];
  };

  # Home-manager audio tools
  flake.modules.homeManager.audio =
    { pkgs, lib, ... }:
    let
      inherit (pkgs.stdenv) isLinux isDarwin;
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
      home.packages =
        lib.optionals isLinux [
          pkgs.kid3
          pkgs.pwvucontrol
          pkgs.playerctl
          pkgs.crosspipe
        ]
        ++ lib.optionals isDarwin [
          pkgs.ffmpeg
          pkgs.lame
          pkgs.flac
        ];

      services.playerctld.enable = isLinux;

      # Poll for Apogee reconnection after KVM switch (macOS only)
      launchd.agents.audio-kvm-recovery = lib.mkIf isDarwin {
        enable = true;
        config = {
          ProgramArguments = [ "${audioKvmRecovery}" ];
          # launchd ThrottleInterval floors re-launch at 10s; 30s is the
          # least-wasteful polling cadence here. For event-driven, swap to
          # Hammerspoon's hs.usb.watcher.
          StartInterval = 30;
          RunAtLoad = true;
          StandardOutPath = "/tmp/audio-kvm-recovery.log";
          StandardErrorPath = "/tmp/audio-kvm-recovery.err";
        };
      };
    };
}
