{
  config,
  lib,
  pkgs,
  ...
}:
# Hytale Server Module
#
# This module configures a Hytale game server on NixOS with:
# - Java 25 runtime (required by Hytale)
# - Systemd service with proper lifecycle management
# - UDP firewall configuration (QUIC protocol)
# - Persistent data directory for worlds and configs
# - AOT cache support for faster boot times
#
# Setup:
#   1. Copy HytaleServer.jar and Assets.zip to configured paths
#   2. Enable the service: services.hytaleServer.enable = true;
#   3. Start service: systemctl start hytale-server
#   4. Authenticate: Follow device auth flow in journalctl output
#
# See: docs/HYTALE_SERVER_PLAN.md for detailed documentation
let
  inherit (lib)
    mkOption
    mkIf
    types
    concatStringsSep
    ;

  constants = import ../../../lib/constants.nix;
  cfg = config.services.hytaleServer;
in
{
  options.services.hytaleServer = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable the Hytale game server.

        After enabling, you must:
        1. Provide HytaleServer.jar and Assets.zip files
        2. Start the service and complete OAuth device authentication
        3. Configure firewall/port forwarding for UDP port (default: 5520)
      '';
    };

    port = mkOption {
      type = types.port;
      default = constants.ports.services.hytaleServer;
      description = ''
        UDP port for the server (QUIC protocol).
        Default is 5520. Change if needed for port forwarding.
      '';
      example = 3500;
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/hytale-server";
      description = ''
        Data directory for server files, worlds, logs, and configuration.
        Worlds are stored in {dataDir}/universe/worlds/
      '';
    };

    serverFiles = {
      jarPath = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Path to HytaleServer.jar file.

          If null, will attempt to find from Flatpak installation.
          Set explicitly to override automatic detection.
        '';
        example = "/var/lib/hytale-server/HytaleServer.jar";
      };

      assetsPath = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Path to Assets.zip file.

          If null, will attempt to find from Flatpak installation.
          Set explicitly to override automatic detection.
        '';
        example = "/var/lib/hytale-server/Assets.zip";
      };

      flatpakSourceDir = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Source directory for Hytale Flatpak installation.

          Default: Automatically detected from common Flatpak locations
          Set to override automatic detection or if running as different user.
        '';
        example = "/home/username/.var/app/com.hypixel.HytaleLauncher/data/Hytale/install/release/package/game/latest";
      };

      symlinkFromFlatpak = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Symlink server files from Flatpak installation instead of copying.

          Advantages:
          - No disk space duplication
          - Automatic updates when Flatpak updates
          - Always in sync with launcher version

          Set to false to copy files instead (useful for stability).
        '';
      };
    };

    jvmArgs = mkOption {
      type = types.listOf types.str;
      default = [
        "-XX:AOTCache=${cfg.dataDir}/HytaleServer.aot"
        "-Xmx4G"
        "-Xms2G"
      ];
      description = ''
        JVM arguments for the server.

        Default includes:
        - AOT cache for faster boot times (JEP-514)
        - 4GB max heap (-Xmx4G)
        - 2GB initial heap (-Xms2G)

        Adjust -Xmx based on your RAM and expected player count.
        Recommended: 4GB minimum, 8GB+ for high player counts.
      '';
      example = [
        "-XX:AOTCache=/var/lib/hytale-server/HytaleServer.aot"
        "-Xmx8G"
        "-Xms4G"
        "-XX:+UseG1GC"
      ];
    };

    authMode = mkOption {
      type = types.enum [
        "authenticated"
        "offline"
      ];
      default = "authenticated";
      description = ''
        Authentication mode for the server.

        - authenticated: Requires OAuth device authentication (default)
        - offline: Skip authentication (for testing only, not recommended)

        Note: Offline mode is intended for development/testing environments only.
        Production servers should use authenticated mode.
      '';
    };

    backup = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable automatic backups of server data.

          Backups include world data, configurations, and player data.
          Frequency and location can be configured below.
        '';
      };

      directory = mkOption {
        type = types.str;
        default = "${cfg.dataDir}/backups";
        description = ''
          Directory where backups will be stored.
          Default: {dataDir}/backups
        '';
      };

      frequency = mkOption {
        type = types.int;
        default = 30;
        description = ''
          Backup interval in minutes.
          Default: 30 minutes
        '';
      };
    };

    disableSentry = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Disable Sentry crash reporting.

        Recommended during plugin development to avoid submitting development errors.
        For production servers, leave this disabled to help improve Hytale.
      '';
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Extra server arguments passed to HytaleServer.jar.

        See: java -jar HytaleServer.jar --help for all options
      '';
      example = [ "--accept-early-plugins" ];
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Automatically open the UDP firewall port.
        Set to false if you manage firewall rules manually.
      '';
    };

    bindAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = ''
        Address to bind the server to.
        Use 0.0.0.0 to listen on all interfaces, or specific IP for one interface.
      '';
      example = "192.168.1.100";
    };
  };

  config = mkIf cfg.enable (
    let
      # Flatpak source directory
      # Note: Auto-detection happens in activation script, not during eval
      flatpakBaseDir = cfg.serverFiles.flatpakSourceDir;

      # File paths - use explicit paths if set, otherwise default to dataDir
      # (Activation script will symlink/copy from Flatpak)
      jarPath =
        if cfg.serverFiles.jarPath != null then
          cfg.serverFiles.jarPath
        else
          "${cfg.dataDir}/HytaleServer.jar";

      assetsPath =
        if cfg.serverFiles.assetsPath != null then
          cfg.serverFiles.assetsPath
        else
          "${cfg.dataDir}/Assets.zip";
    in
    {
      # Validate configuration
      assertions = [
        {
          assertion = cfg.backup.frequency > 0;
          message = "services.hytaleServer.backup.frequency must be greater than 0";
        }
      ];

      # User and group for the server
      users.users.hytale-server = {
        isSystemUser = true;
        group = "hytale-server";
        home = cfg.dataDir;
        createHome = true;
        description = "Hytale game server user";
        # Add to users group to access Flatpak files in /home/*/
        extraGroups = [ "users" ];
      };

      users.groups.hytale-server = { };

      # Activation script to setup server files from Flatpak
      system.activationScripts.hytale-server-setup = lib.stringAfter [ "users" ] ''
        echo "Setting up Hytale server files..."

        # Ensure data directory exists
        mkdir -p ${cfg.dataDir}

        # Auto-detect Flatpak if not explicitly configured
        FLATPAK_DIR="${if flatpakBaseDir != null then flatpakBaseDir else ""}"

        if [ -z "$FLATPAK_DIR" ]; then
          # Try to find Flatpak installation
          for user_home in /home/*; do
            candidate="$user_home/.var/app/com.hypixel.HytaleLauncher/data/Hytale/install/release/package/game/latest"
            if [ -d "$candidate/Server" ] && [ -f "$candidate/Assets.zip" ]; then
              FLATPAK_DIR="$candidate"
              echo "  ✓ Auto-detected Flatpak installation at: $FLATPAK_DIR"
              break
            fi
          done
        fi

        if [ -z "$FLATPAK_DIR" ]; then
          echo "  ⚠ No Flatpak installation found"
          echo "  Manual setup required:"
          echo "    1. Install Hytale via Flatpak, OR"
          echo "    2. Set serverFiles.flatpakSourceDir explicitly, OR"
          echo "    3. Copy files manually to ${cfg.dataDir}/"
          exit 0  # Don't fail, validation will happen at service start
        fi

        ${
          if cfg.serverFiles.symlinkFromFlatpak then
            # Symlink from Flatpak (always in sync, no duplication)
            ''
              # Create symlinks to Flatpak installation
              ln -sf "$FLATPAK_DIR/Server/HytaleServer.jar" "${cfg.dataDir}/HytaleServer.jar"
              ln -sf "$FLATPAK_DIR/Assets.zip" "${cfg.dataDir}/Assets.zip"
              if [ -f "$FLATPAK_DIR/Server/HytaleServer.aot" ]; then
                ln -sf "$FLATPAK_DIR/Server/HytaleServer.aot" "${cfg.dataDir}/HytaleServer.aot"
              fi
              echo "  ✓ Symlinked server files from Flatpak installation"
            ''
          else
            # Copy from Flatpak (stable, but uses more space)
            ''
              # Copy files if they don't exist or are older than source
              if [ ! -f "${cfg.dataDir}/HytaleServer.jar" ] || [ "$FLATPAK_DIR/Server/HytaleServer.jar" -nt "${cfg.dataDir}/HytaleServer.jar" ]; then
                cp -f "$FLATPAK_DIR/Server/HytaleServer.jar" "${cfg.dataDir}/HytaleServer.jar"
                echo "  ✓ Copied HytaleServer.jar"
              fi

              if [ ! -f "${cfg.dataDir}/Assets.zip" ] || [ "$FLATPAK_DIR/Assets.zip" -nt "${cfg.dataDir}/Assets.zip" ]; then
                cp -f "$FLATPAK_DIR/Assets.zip" "${cfg.dataDir}/Assets.zip"
                echo "  ✓ Copied Assets.zip"
              fi

              if [ -f "$FLATPAK_DIR/Server/HytaleServer.aot" ]; then
                if [ ! -f "${cfg.dataDir}/HytaleServer.aot" ] || [ "$FLATPAK_DIR/Server/HytaleServer.aot" -nt "${cfg.dataDir}/HytaleServer.aot" ]; then
                  cp -f "$FLATPAK_DIR/Server/HytaleServer.aot" "${cfg.dataDir}/HytaleServer.aot"
                  echo "  ✓ Copied HytaleServer.aot"
                fi
              fi
            ''
        }

        # Set correct permissions
        chown -R hytale-server:hytale-server ${cfg.dataDir}
        chmod 750 ${cfg.dataDir}

        echo "Hytale server files ready at ${cfg.dataDir}"
      '';

      # Systemd service
      systemd.services.hytale-server =
        let
          # Build server arguments
          serverArgs = lib.concatStringsSep " " (
            [
              "--assets ${assetsPath}"
              "--bind ${cfg.bindAddress}:${toString cfg.port}"
              "--auth-mode ${cfg.authMode}"
            ]
            ++ lib.optional cfg.backup.enable "--backup"
            ++ lib.optional cfg.backup.enable "--backup-dir ${cfg.backup.directory}"
            ++ lib.optional cfg.backup.enable "--backup-frequency ${toString cfg.backup.frequency}"
            ++ lib.optional cfg.disableSentry "--disable-sentry"
            ++ cfg.extraArgs
          );

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
              echo "  2. Set serverFiles.flatpakSourceDir explicitly in your config"
              echo "  3. Copy files manually to ${cfg.dataDir}/"
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
          description = "Hytale Game Server";
          documentation = [ "https://support.hytale.com/hc/en-us/articles/hytale-server-manual" ];
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];

          serviceConfig = {
            Type = "simple";
            User = "hytale-server";
            Group = "hytale-server";
            WorkingDirectory = cfg.dataDir;
            ExecStartPre = validateFiles;
            ExecStart = ''
              ${pkgs.jdk25 or pkgs.jdk}/bin/java ${concatStringsSep " " cfg.jvmArgs} -jar ${jarPath} ${serverArgs}
            '';
            Restart = "on-failure";
            RestartSec = "10s";

            # Security hardening
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            ReadWritePaths = [ cfg.dataDir ];
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
      networking.firewall.allowedUDPPorts = mkIf cfg.openFirewall [ cfg.port ];

      # Ensure data directory exists with correct permissions
      systemd.tmpfiles.rules = [
        "d '${cfg.dataDir}' 0750 hytale-server hytale-server -"
        "d '${cfg.dataDir}/universe' 0750 hytale-server hytale-server -"
        "d '${cfg.dataDir}/universe/worlds' 0750 hytale-server hytale-server -"
        "d '${cfg.dataDir}/logs' 0750 hytale-server hytale-server -"
        "d '${cfg.dataDir}/mods' 0750 hytale-server hytale-server -"
        "d '${cfg.dataDir}/.cache' 0750 hytale-server hytale-server -"
      ]
      ++ lib.optional cfg.backup.enable "d '${cfg.backup.directory}' 0750 hytale-server hytale-server -";
    }
  );
}
