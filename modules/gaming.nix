# Gaming Feature Module - Dendritic Pattern
# Single file containing both NixOS system config and home-manager user config
# Usage: Import flake.modules.nixos.gaming in host definition
{ config, ... }:
let
  constants = config.constants;
  inherit (config) username;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.gaming =
    { pkgs, lib, ... }:
    {
      # Enable user namespaces for Steam/Flatpak sandboxing
      security.unprivilegedUsernsClone = true;

      programs = {
        # Steam with VR/VRChat support
        # VRChat setup: Use Proton-GE-RTSP for video player support
        # See: https://lvra.gitlab.io/docs/vrchat/
        # Helper commands: vrchat-info, vrchat-link-pictures
        steam = {
          enable = true;
          protontricks.enable = true;
          remotePlay.openFirewall = true;
          dedicatedServer.openFirewall = true;
          extraCompatPackages = [
            pkgs.proton-ge-rtsp-bin # VRChat video player support (RTSP/HLS streams)
            pkgs.proton-ge-bin # Standard Proton GE for other games
          ];

          # mkDefault allows VR module to override
          package = lib.mkDefault (
            pkgs.steam.override {
              extraArgs = "-pipewire -system-composer";
              extraProfile = ''
                # Fix timezone issues in VR games (lvra.gitlab.io recommendation)
                unset TZ
                # Required for OpenXR games to find WiVRn runtime
                export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
              '';

              # Add packages to Steam's FHS environment
              # - VR support (xrizer-multilib, SDL2)
              # - Gamescope dependencies (Xorg libraries)
              # See: https://github.com/NixOS/nixpkgs/issues/214275
              extraPkgs =
                pkgs': with pkgs'; [
                  # VR support
                  xrizer-multilib
                  SDL2

                  # Gamescope within Steam (for launch options)
                  xorg.libXcursor
                  xorg.libXi
                  xorg.libXinerama
                  xorg.libXScrnSaver
                  libpng
                  libpulseaudio
                  libvorbis
                  stdenv.cc.cc.lib # Provides libstdc++.so.6
                  libkrb5
                  keyutils
                ];
            }
          );
        };

        gamescope = {
          enable = true;
          capSysNice = true;
        };

        gamemode = {
          enable = true;
          settings.general.renice = 10;
        };
      };

      services = {
        udev.packages = [ pkgs.game-devices-udev-rules ];

        # Override Steam's udev rule to restrict uinput to steam group
        udev.extraRules = ''
          KERNEL=="uinput", SUBSYSTEM=="misc", TAG-="uaccess", GROUP="steam", MODE="0660"
        '';
      };

      # Create steam system group for uinput access control
      users.groups.steam = { };

      # Add user to steam group for Steam Input access
      users.users.${username}.extraGroups = [ "steam" ];

      # Steam Link firewall
      networking.firewall = {
        allowedUDPPorts = [
          constants.ports.gaming.steamLinkDiscovery
        ]
        ++ constants.ports.gaming.steamLinkUdp;
        allowedTCPPorts = [ constants.ports.gaming.steamLinkTcp ];
      };

      environment.systemPackages = [
        pkgs.gamescope-wsi # WSI layer for gamescope
      ];

      hardware.uinput.enable = true;
    };

  # ==========================================================================
  # Home-Manager User Configuration
  # ==========================================================================
  flake.modules.homeManager.gaming =
    {
      pkgs,
      lib,
      osConfig ? { },
      ...
    }:
    let
      gamingEnabled = osConfig.host.features.gaming.enable or false;
      steamEnabled = osConfig.host.features.gaming.steam or false;

      # Helper script to install Media Foundation codecs for Proton/Steam games
      install-mf-codecs = pkgs.writeShellApplication {
        name = "install-mf-codecs";
        text = ''
          if [ $# -eq 0 ]; then
            echo "Usage: install-mf-codecs <STEAM_APP_ID>"
            echo "Find App ID: right-click game -> Properties, or check steamapps/"
            exit 1
          fi
          echo "Installing Media Foundation codecs for App ID: $1"
          ${pkgs.protontricks}/bin/protontricks "$1" -q mf
          echo "Done. Restart the game if needed."
        '';
        runtimeInputs = [ pkgs.protontricks ];
      };

      # VRChat: Link Pictures folder to system Pictures directory
      vrchat-link-pictures = pkgs.writeShellApplication {
        name = "vrchat-link-pictures";
        text = ''
          echo "=== VRChat Pictures Folder Setup ==="
          echo ""
          echo "This will link VRChat's Pictures folder to your system Pictures directory."
          echo "Default VRChat location: ~/.steam/steam/steamapps/compatdata/438100/pfx/drive_c/users/steamuser/Pictures/VRChat"
          echo ""
          echo "Opening Wine configuration for VRChat (App ID: 438100)..."
          echo ""
          ${pkgs.protontricks}/bin/protontricks 438100 winecfg
          echo ""
          echo "In the Wine Configuration window:"
          echo "  1. Go to 'Desktop Integration' tab"
          echo "  2. Select 'Pictures' from the folders list"
          echo "  3. Enable 'Link to' and browse to: $HOME/Pictures"
          echo "  4. Click Apply and OK"
          echo ""
          echo "After this, VRChat screenshots will save directly to ~/Pictures/VRChat"
        '';
        runtimeInputs = [ pkgs.protontricks ];
      };

      # VRChat: Comprehensive setup information and recommendations
      vrchat-info = pkgs.writeShellApplication {
        name = "vrchat-info";
        text = ''
          echo "╔══════════════════════════════════════════════════════════════════════╗"
          echo "║               VRChat on Linux - Setup Guide (NixOS)                 ║"
          echo "╚══════════════════════════════════════════════════════════════════════╝"
          echo ""
          echo "🎮 PROTON CONFIGURATION"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "✓ Proton-GE-RTSP installed (video player support)"
          echo ""
          echo "To enable in Steam:"
          echo "  1. Right-click VRChat in Steam Library"
          echo "  2. Properties → Compatibility"
          echo "  3. Enable 'Force the use of a specific Steam Play compatibility tool'"
          echo "  4. Select 'GE-Proton' with 'rtsp' in the name"
          echo ""
          echo "🚀 RECOMMENDED LAUNCH OPTIONS"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "Right-click VRChat → Properties → Launch Options:"
          echo ""
          echo "  gamemoderun mangohud %command% --process-priority=1"
          echo ""
          echo "This enables:"
          echo "  • gamemode: CPU/IO priority boost during gameplay"
          echo "  • mangohud: FPS overlay and performance monitoring"
          echo "  • --process-priority=1: Above-normal VRChat process priority"
          echo ""
          echo "📸 PICTURES SETUP"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "Link VRChat screenshots to ~/Pictures:"
          echo "  vrchat-link-pictures"
          echo ""
          echo "🎯 PERFORMANCE OPTIMIZATION"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "Recommended in-game settings:"
          echo "  • Anti-Aliasing: Off (or 2x if needed)"
          echo "  • Pixel Light Count: Low"
          echo "  • Shadow Quality: Low"
          echo "  • LOD Quality: Low or Medium"
          echo "  • Particle Limiter: On"
          echo ""
          echo "Avatar management:"
          echo "  • Max shown avatars: 10-15"
          echo "  • Create custom Safety profile blocking Animators/Shaders by default"
          echo "  • Manually enable avatars for active conversations"
          echo ""
          echo "CPU bottleneck detection:"
          echo "  • Run 'nvtop' or 'nvidia-smi' - if GPU < 100%, you're CPU-limited"
          echo "  • Lower SteamVR render resolution to confirm"
          echo ""
          echo "🔊 AUDIO CONFIGURATION"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "✓ PipeWire configured for VR (low-latency, large ring buffer)"
          echo "✓ Audio dropout fix enabled (DisplayPort headsets)"
          echo ""
          echo "🛡️ EASY ANTI-CHEAT"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "✓ EAC startup issues resolved (as of Oct-Nov 2024)"
          echo ""
          echo "⚠️  Do NOT set these environment variables:"
          echo "  • SDL_VIDEODRIVER (breaks splash screen)"
          echo "  • VR_OVERRIDE (causes compatibility issues)"
          echo ""
          echo "⚠️  Ensure firewall allows: modules-cdn.eac-prod.on.epicgames.com"
          echo ""
          echo "🥽 VR RUNTIME"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "✓ WiVRn (OpenXR) configured"
          echo "✓ xrizer-multilib (OpenVR→OpenXR translation) installed"
          echo ""
          echo "Check your runtime:"
          echo "  vr-which-runtime"
          echo ""
          echo "🛠️ HELPER COMMANDS"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "  vrchat-info            - Show this guide"
          echo "  vrchat-link-pictures   - Link screenshots to ~/Pictures"
          echo "  vrchat-performance     - Show detailed performance tips"
          echo "  install-mf-codecs 438100 - Install Media Foundation codecs"
          echo "  vr-which-runtime       - Check active OpenXR runtime"
          echo "  vr-fix-steamvr         - Diagnose SteamVR issues"
          echo ""
          echo "📚 MORE INFO"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "VRChat App ID: 438100"
          echo "Documentation: https://lvra.gitlab.io/docs/vrchat/"
          echo "OpenComposite: Replaced by xrizer (already configured)"
          echo ""
        '';
      };

      # VRChat: Detailed performance optimization guide
      vrchat-performance = pkgs.writeShellApplication {
        name = "vrchat-performance";
        text = ''
          echo "╔══════════════════════════════════════════════════════════════════════╗"
          echo "║            VRChat Performance Optimization Guide                     ║"
          echo "╚══════════════════════════════════════════════════════════════════════╝"
          echo ""
          echo "🎯 IN-GAME GRAPHICS SETTINGS"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
          echo "Recommended Settings (Performance First):"
          echo "  Setting                Value          Impact"
          echo "  ─────────────────────  ─────────────  ───────────────────────────"
          echo "  Anti-Aliasing          Off/2x         Minimal visual impact"
          echo "  Pixel Light Count      Low            HIGH CPU impact"
          echo "  Shadow Quality         Low            High performance cost"
          echo "  LOD Quality            Low/Medium     Depends on world complexity"
          echo "  Particle Limiter       On             Prevents particle spam"
          echo ""
          echo "🧑 AVATAR OPTIMIZATION"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
          echo "1. Limit Visible Avatars:"
          echo "   • Set max shown avatars: 10-15 people"
          echo "   • This matches typical conversation group sizes"
          echo ""
          echo "2. Create Custom Safety Profile:"
          echo "   • Block 'Animators' and 'Shaders' by default"
          echo "   • Block 'Very Poor' performance avatars"
          echo "   • Manually show avatars for people you're actively talking to"
          echo "   • This isolates performance-draining avatars"
          echo ""
          echo "3. For Content Creators:"
          echo "   Avatar optimization tools (requires Unity + vrc-get):"
          echo "   • d4rkAvatarOptimizer"
          echo "     vrc-get repo add https://d4rkc0d3r.github.io/vpm-repos/main.json"
          echo "   • Avatar Optimizer by Anatawa12"
          echo "     vrc-get repo add https://vpm.anatawa12.com/vpm.json"
          echo ""
          echo "🔍 DIAGNOSING BOTTLENECKS"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
          echo "Identifying CPU vs GPU bottleneck:"
          echo ""
          echo "1. Monitor GPU usage:"
          echo "   nvtop             # Interactive GPU monitor"
          echo "   nvidia-smi -l 1   # 1-second polling"
          echo ""
          echo "2. Interpret results:"
          echo "   • GPU < 100%: You're CPU-bottlenecked"
          echo "   • GPU = 100%: You're GPU-bottlenecked"
          echo ""
          echo "3. Confirm CPU bottleneck:"
          echo "   • Lower SteamVR render resolution"
          echo "   • If FPS doesn't improve → CPU is the limitation"
          echo ""
          echo "💡 CPU BOTTLENECK SOLUTIONS"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
          echo "• Reduce avatar count (primary impact)"
          echo "• Lower Pixel Light Count to Low"
          echo "• Disable Animators/Shaders on non-essential avatars"
          echo "• Use gamemode for CPU priority boost (already in launch options)"
          echo "• Close background applications"
          echo ""
          echo "💡 GPU BOTTLENECK SOLUTIONS"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
          echo "• Lower SteamVR render resolution"
          echo "• Disable Anti-Aliasing completely"
          echo "• Set Shadow Quality to Low"
          echo "• Reduce LOD Quality"
          echo "• Consider world complexity when choosing instances"
          echo ""
          echo "🎮 SYSTEM-LEVEL OPTIMIZATIONS"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
          echo "Already configured in your NixOS setup:"
          echo "  ✓ GameMode enabled (CPU/IO priority boost)"
          echo "  ✓ Low-latency PipeWire audio"
          echo "  ✓ Steam with performance flags"
          echo "  ✓ VR-optimized FHS environment"
          echo ""
          echo "Monitor performance:"
          echo "  mangohud %command%    # FPS overlay (add to launch options)"
          echo "  nvtop                 # GPU monitoring"
          echo "  btop                  # CPU monitoring"
          echo ""
          echo "📊 PERFORMANCE METRICS"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
          echo "Target framerates (VR):"
          echo "  • Quest 2: 72 Hz, 90 Hz, 120 Hz"
          echo "  • Quest 3: 72 Hz, 90 Hz, 120 Hz"
          echo "  • Valve Index: 80 Hz, 90 Hz, 120 Hz, 144 Hz"
          echo ""
          echo "Aim for consistent frametime over high FPS."
          echo "Reprojection (ASW/ATW) helps smooth dropped frames."
          echo ""
          echo "More info: https://lvra.gitlab.io/docs/vrchat/performance/"
          echo ""
        '';
      };
    in
    lib.mkIf (gamingEnabled && pkgs.stdenv.isLinux) {
      programs.mangohud = {
        enable = true;
        enableSessionWide = false; # Enable per-game via MANGOHUD=1
      };

      home.packages = [
        pkgs.moonlight-qt
        pkgs.wine
        pkgs.winetricks
        install-mf-codecs
        pkgs.protonup-qt # Proton version manager GUI
        # VRChat helpers
        vrchat-link-pictures
        vrchat-info
        vrchat-performance
      ]
      ++ lib.optionals steamEnabled [
        pkgs.steamcmd # Steam command-line client
        pkgs.steam-run # Steam runtime wrapper
      ];

      # Steam performance optimizations
      home.file.".steam/steam/steam_dev.cfg".text = ''
        # Shader compilation: use all CPU cores for faster pre-compilation
        unShaderBackgroundProcessingThreads 16

        # Disable HTTP2 for potentially faster downloads
        @nClientDownloadEnableHTTP2PlatformLinux 0
      '';

      # Replace Steam's internal bwrap with patched version for VR support
      systemd.user.services.steam-bwrap-setup = {
        Unit = {
          Description = "Replace Steam's bubblewrap with patched version for VR";
          Before = [ "steam-autostart.service" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "setup-steam-bwrap" ''
            STEAM_RUNTIME="$HOME/.local/share/Steam/ubuntu12_32/steam-runtime"
            PATCHED_BWRAP="/run/current-system/sw/bin/bwrap"

            for ARCH in amd64 i386; do
              STEAM_BWRAP="$STEAM_RUNTIME/$ARCH/usr/libexec/steam-runtime-tools-0/srt-bwrap"

              if [ ! -d "$(dirname "$STEAM_BWRAP")" ]; then
                echo "Steam runtime directory for $ARCH not yet created, skipping"
                continue
              fi

              if [ -f "$STEAM_BWRAP" ] && [ ! -L "$STEAM_BWRAP" ]; then
                echo "Backing up original Steam bwrap ($ARCH)"
                mv "$STEAM_BWRAP" "$STEAM_BWRAP.original"
              fi

              if [ ! -L "$STEAM_BWRAP" ]; then
                echo "Creating symlink for $ARCH"
                ln -sf "$PATCHED_BWRAP" "$STEAM_BWRAP"
              fi
            done
          '';
        };
      };

      # Auto-start Steam on login (when steam feature is enabled)
      systemd.user.services.steam-autostart = lib.mkIf steamEnabled {
        Unit = {
          Description = "Auto-start Steam on login";
          After = [
            "graphical-session.target"
            "steam-bwrap-setup.service"
          ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.steam}/bin/steam -silent";
          Restart = "on-failure";
          RestartSec = "5s";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
