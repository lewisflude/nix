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
        steam = {
          enable = true;
          protontricks.enable = true;
          remotePlay.openFirewall = true;
          dedicatedServer.openFirewall = true;
          extraCompatPackages = [ pkgs.proton-ge-bin ];

          # Add packages to Steam's FHS environment for VR
          extraPackages = [
            pkgs.xrizer-multilib
            pkgs.SDL2 # Required by SteamVR
          ];

          # mkDefault allows VR module to override
          package = lib.mkDefault (
            pkgs.steam.override {
              extraArgs = "-pipewire -system-composer";
              extraProfile = ''
                # Required for OpenXR games to find WiVRn runtime
                export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
              '';
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
    { pkgs, lib, ... }:
    let
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
    in
    {
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
    };
}
