{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  gamingEnabled = osConfig.host.features.gaming.enable or false;

  # Helper script to install Media Foundation codecs for Proton/Steam games
  install-mf-codecs = pkgs.writeShellApplication {
    name = "install-mf-codecs";
    text = ''
      if [ $# -eq 0 ]; then
        echo "Usage: install-mf-codecs <STEAM_APP_ID>"
        echo "Find App ID: right-click game → Properties, or check steamapps/"
        exit 1
      fi
      echo "Installing Media Foundation codecs for App ID: $1"
      ${pkgs.protontricks}/bin/protontricks "$1" -q mf
      echo "Done. Restart the game if needed."
    '';
    runtimeInputs = [ pkgs.protontricks ];
  };
in
mkIf gamingEnabled {
  programs.mangohud = {
    enable = true;
    enableSessionWide = false; # Enable per-game via MANGOHUD=1
  };

  home.packages = [
    pkgs.moonlight-qt
    pkgs.wine
    pkgs.winetricks
    install-mf-codecs
    # Gaming user tools (moved from system packages)
    pkgs.protonup-qt # Proton version manager GUI
  ]
  ++ lib.optionals (osConfig.host.features.gaming.steam or false) [
    pkgs.steamcmd # Steam command-line client
    pkgs.steam-run # Steam runtime wrapper
  ];

  # Steam performance optimizations
  # See: https://wiki.archlinux.org/title/Steam#Faster_shader_pre-compilation
  home.file.".steam/steam/steam_dev.cfg".text = ''
    # Shader compilation: use all CPU cores for significantly faster pre-compilation
    # Jupiter has 16 cores, so use all of them
    unShaderBackgroundProcessingThreads 16

    # Disable HTTP2 for potentially faster downloads on some network configurations
    # Some systems experience better download speeds with HTTP/1.1
    @nClientDownloadEnableHTTP2PlatformLinux 0
  '';

  # Replace Steam's internal bwrap with patched version for VR support
  # This is required because Steam uses its own bundled bubblewrap binary
  # The patched bwrap is provided by the gaming module's systemPackages
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

        # Setup bwrap for both architectures (amd64 and i386)
        for ARCH in amd64 i386; do
          STEAM_BWRAP="$STEAM_RUNTIME/$ARCH/usr/libexec/steam-runtime-tools-0/srt-bwrap"

          # Skip if directory doesn't exist yet
          if [ ! -d "$(dirname "$STEAM_BWRAP")" ]; then
            echo "Steam runtime directory for $ARCH not yet created, skipping"
            continue
          fi

          # Backup original if it exists and isn't already a symlink
          if [ -f "$STEAM_BWRAP" ] && [ ! -L "$STEAM_BWRAP" ]; then
            echo "Backing up original Steam bwrap ($ARCH) to $STEAM_BWRAP.original"
            mv "$STEAM_BWRAP" "$STEAM_BWRAP.original"
          fi

          # Create symlink to patched bwrap (from system packages)
          if [ ! -L "$STEAM_BWRAP" ]; then
            echo "Creating symlink for $ARCH: $STEAM_BWRAP -> $PATCHED_BWRAP"
            ln -sf "$PATCHED_BWRAP" "$STEAM_BWRAP"
          fi
        done

        echo "Steam bwrap setup complete - VR capabilities enabled for both architectures"
      '';
    };
  };

  # Auto-start Steam on login (for gaming PC use case)
  systemd.user.services.steam-autostart = {
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
}
