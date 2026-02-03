# Hytale Server Module - Dendritic Pattern
# Game server for Hytale with Java 25 runtime
# Usage: Import flake.modules.nixos.hytaleServer in host definition
{ config, ... }:
let
  constants = config.constants;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.hytaleServer =
    { lib, pkgs, ... }:
    let
      inherit (lib) mkDefault mkIf mkForce concatStringsSep optional;

      # Default configuration (can be overridden by hosts)
      port = constants.ports.services.hytaleServer;
      dataDir = "/var/lib/hytale-server";
      user = "hytale-server";
      group = "hytale-server";

      # Default JVM arguments
      jvmArgs = [
        "-XX:AOTCache=${dataDir}/HytaleServer.aot"
        "-Xmx4G"
        "-Xms2G"
      ];

      # File paths (will be symlinked/copied in activation script)
      jarPath = "${dataDir}/HytaleServer.jar";
      assetsPath = "${dataDir}/Assets.zip";

      # Build server arguments
      serverArgs = concatStringsSep " " [
        "--assets ${assetsPath}"
        "--bind 0.0.0.0:${toString port}"
        "--auth-mode authenticated"
      ];

      # File validation script
      validateFiles = pkgs.writeShellScript "validate-hytale-files" ''
        set -euo pipefail

        echo "Validating Hytale server files..."

        if [ ! -f "${jarPath}" ] && [ ! -L "${jarPath}" ]; then
          echo "ERROR: HytaleServer.jar not found at: ${jarPath}"
          echo ""
          echo "The activation script should have set this up automatically."
          echo "If this failed, try:"
          echo "  1. Install Hytale via Flatpak: flatpak install com.hypixel.HytaleLauncher"
          echo "  2. Copy files manually to ${dataDir}/"
          exit 1
        fi

        if [ ! -f "${assetsPath}" ] && [ ! -L "${assetsPath}" ]; then
          echo "ERROR: Assets.zip not found at: ${assetsPath}"
          exit 1
        fi

        echo "✓ Server files validated successfully"
        if [ -L "${jarPath}" ]; then
          echo "  Using files from: $(readlink -f "${jarPath}" | xargs dirname | xargs dirname)"
        fi
      '';
    in
    {
      # User and group for the server
      users.users.${user} = mkDefault {
        isSystemUser = true;
        inherit group;
        home = dataDir;
        createHome = true;
        description = "Hytale game server user";
        # Add to users group to access Flatpak files in /home/*/
        extraGroups = [ "users" ];
      };

      users.groups.${group} = mkDefault { };

      # Activation script to setup server files from Flatpak
      system.activationScripts.hytale-server-setup = lib.stringAfter [ "users" ] ''
        echo "Setting up Hytale server files..."

        # Ensure data directory exists
        mkdir -p ${dataDir}

        # Auto-detect Flatpak installation
        FLATPAK_DIR=""

        # Try to find Flatpak installation
        for user_home in /home/*; do
          candidate="$user_home/.var/app/com.hypixel.HytaleLauncher/data/Hytale/install/release/package/game/latest"
          if [ -d "$candidate/Server" ] && [ -f "$candidate/Assets.zip" ]; then
            FLATPAK_DIR="$candidate"
            echo "  ✓ Auto-detected Flatpak installation at: $FLATPAK_DIR"
            break
          fi
        done

        if [ -z "$FLATPAK_DIR" ]; then
          echo "  ⚠ No Flatpak installation found"
          echo "  Manual setup required:"
          echo "    1. Install Hytale via Flatpak, OR"
          echo "    2. Copy files manually to ${dataDir}/"
          exit 0  # Don't fail, validation will happen at service start
        fi

        # Create symlinks to Flatpak installation
        ln -sf "$FLATPAK_DIR/Server/HytaleServer.jar" "${dataDir}/HytaleServer.jar"
        ln -sf "$FLATPAK_DIR/Assets.zip" "${dataDir}/Assets.zip"
        if [ -f "$FLATPAK_DIR/Server/HytaleServer.aot" ]; then
          ln -sf "$FLATPAK_DIR/Server/HytaleServer.aot" "${dataDir}/HytaleServer.aot"
        fi
        echo "  ✓ Symlinked server files from Flatpak installation"

        # Set correct permissions
        chown -R ${user}:${group} ${dataDir}
        chmod 750 ${dataDir}

        echo "Hytale server files ready at ${dataDir}"
      '';

      # Systemd service
      systemd.services.hytale-server = {
        description = "Hytale Game Server";
        documentation = [ "https://support.hytale.com/hc/en-us/articles/hytale-server-manual" ];
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        serviceConfig = {
          Type = "simple";
          User = user;
          Group = group;
          WorkingDirectory = dataDir;
          ExecStartPre = validateFiles;
          ExecStart = ''
            ${pkgs.jdk25 or pkgs.jdk}/bin/java ${concatStringsSep " " jvmArgs} -jar ${jarPath} ${serverArgs}
          '';
          Restart = "on-failure";
          RestartSec = "10s";

          # Security hardening
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ dataDir ];
          NoNewPrivileges = true;
          PrivateDevices = false; # May need access to /dev/urandom, etc.

          # Resource limits
          # Hytale servers can use significant resources with many players
          LimitNOFILE = 65536; # File descriptors (QUIC connections)
          LimitNPROC = 4096; # Process limit

          # Stop gracefully on shutdown
          KillMode = "mixed";
          KillSignal = "SIGTERM";
          TimeoutStopSec = "30s";
        };

        # Environment variables
        environment = {
          JAVA_HOME = "${pkgs.jdk25 or pkgs.jdk}";
          # Ensure UTF-8 encoding
          LC_ALL = "en_US.UTF-8";
        };
      };

      # Firewall configuration (UDP for QUIC protocol)
      networking.firewall.allowedUDPPorts = mkDefault [ port ];

      # Ensure data directory exists with correct permissions
      systemd.tmpfiles.rules = [
        "d '${dataDir}' 0750 ${user} ${group} -"
        "d '${dataDir}/universe' 0750 ${user} ${group} -"
        "d '${dataDir}/universe/worlds' 0750 ${user} ${group} -"
        "d '${dataDir}/logs' 0750 ${user} ${group} -"
        "d '${dataDir}/mods' 0750 ${user} ${group} -"
        "d '${dataDir}/.cache' 0750 ${user} ${group} -"
      ];
    };
}
