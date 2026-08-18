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

    # Disable USB autosuspend for Apogee Symphony Desktop (vendor 0c60, product 002a).
    # power/control=on already pins the device awake; autosuspend=-1 would be redundant.
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0c60", ATTR{idProduct}=="002a", ATTR{power/control}="on"
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
      #
      # The card offers no stereo profile — only `multichannel-*` and
      # `pro-audio`, both of which expose all 10 channels as AUX0..AUX9 (ACP
      # does not trust the driver chmap, so positions are unnamed). Stereo
      # apps therefore need a virtual FL/FR endpoint bridged to AUX0/AUX1.
      #
      # A single loopback module *is* the virtual device: setting
      # `media.class = "Audio/Sink"` on capture.props (or "Audio/Source" on
      # playback.props) makes the user-facing side appear under Sinks/Sources,
      # with the other side targeting the Apogee. No null-audio-sink needed.
      # https://docs.pipewire.org/page_module_loopback.html
      extraConfig.pipewire."91-virtual-sink" = {
        "context.modules" = [
          {
            # Main Output (stereo sink) → Apogee playback channels 1-2
            name = "libpipewire-module-loopback";
            args = {
              "node.description" = "Main Output";
              "capture.props" = {
                "node.name" = "Main-Output";
                "media.class" = "Audio/Sink";
                "audio.position" = [
                  "FL"
                  "FR"
                ];
                # 1400 stays under the upstream 1500 ceiling while beating the
                # Apogee multichannel sink (1300), so this wins as initial
                # default. Once `wpctl set-default` runs, WirePlumber persists
                # the choice in ~/.local/state/wireplumber/default-nodes and
                # that overrides priority.session permanently — clear it with
                # `wpctl settings --delete default.configured.audio.sink`.
                "priority.session" = 1400;
              };
              "playback.props" = {
                "node.name" = "Main-Output-Playback";
                "audio.position" = [
                  "AUX0"
                  "AUX1"
                ];
                "stream.dont-remix" = true;
                "target.object" = "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.multichannel-output";
                # Passive so this link alone never keeps the Apogee busy,
                # letting it idle-suspend. dont-fallback + linger make the node
                # wait silently for the Apogee instead of spilling into the
                # default sink when the KVM takes the device away.
                "node.passive" = true;
                "node.dont-fallback" = true;
                "node.linger" = true;
              };
            };
          }
          {
            # Apogee capture channels 1-2 → Main Input (stereo source)
            name = "libpipewire-module-loopback";
            args = {
              "node.description" = "Main Input";
              "capture.props" = {
                "node.name" = "Main-Input-Capture";
                "audio.position" = [
                  "AUX0"
                  "AUX1"
                ];
                "stream.dont-remix" = true;
                "target.object" = "alsa_input.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.multichannel-input";
                "node.passive" = true;
                "node.dont-fallback" = true;
                "node.linger" = true;
              };
              "playback.props" = {
                "node.name" = "Main-Input";
                "media.class" = "Audio/Source";
                "audio.position" = [
                  "FL"
                  "FR"
                ];
                # Top of the documented source range (1600-2000), so this wins
                # over the raw Apogee multichannel source.
                "priority.session" = 1900;
              };
            };
          }
        ];
      };

      wireplumber.extraConfig = {
        # Apogee: top driver priority (drives the graph clock) and a session
        # priority just under Main-Output (1400) so the Apogee is the
        # runner-up default if Main-Output goes away. priority.driver is not
        # subject to the 1500 ceiling — that cap only applies to session
        # priority for default-node selection.
        #
        # Idle suspend is deliberately left at the 5s default: it is the only
        # mechanism that closes and reopens the ALSA PCM, which is how the
        # device recovers from a wedged state after the KVM re-enumerates it.
        "10-apogee"."monitor.alsa.rules" = [
          {
            matches = [
              { "node.name" = "~alsa_output.usb-Apogee_Electronics*"; }
              { "node.name" = "~alsa_input.usb-Apogee_Electronics*"; }
            ];
            actions.update-props = {
              "priority.driver" = 2000;
              "priority.session" = 1300;
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
      inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;
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
          LowPriorityIO = true;
          ProcessType = "Background";
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
