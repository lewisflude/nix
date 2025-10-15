# NixOS-specific telemetry configuration (systemd services)
{
  config,
  lib,
  pkgs,
  telemetryScripts ? { },
  ...
}:
with lib;
let
  cfg = config.telemetry;

  # Script to collect runtime telemetry
  collectTelemetryScript =
    telemetryScripts.collect or (pkgs.writeShellScript "collect-telemetry" ''
        # Collect runtime telemetry data
        TELEMETRY_DIR="${cfg.dataDir}"
        mkdir -p "$TELEMETRY_DIR"
        TELEMETRY_FILE="$TELEMETRY_DIR/telemetry.json"

          # Bind dynamic values for interpolation
          timestamp="$(date -Iseconds)"
          development_flag=${if config.host.features.development.enable then "true" else "false"}
          gaming_flag=${if config.host.features.gaming.enable then "true" else "false"}
          desktop_flag=${if config.host.features.desktop.enable then "true" else "false"}
          virtualisation_flag=${if config.host.features.virtualisation.enable then "true" else "false"}

          # Generate telemetry JSON
          cat > "$TELEMETRY_FILE" <<EOF
      {
        "timestamp": "${timestamp}",
        "hostname": "${config.host.hostname}",
        "system": "${config.host.system}",
        "features": {
          "development": ${development_flag},
          "gaming": ${gaming_flag},
          "desktop": ${desktop_flag},
          "virtualisation": ${virtualisation_flag}
        }
      }
      EOF

          ${optionalString cfg.verbose ''
            echo "✅ Telemetry data collected at $TELEMETRY_FILE"
          ''}
    '');
in
{
  config = mkIf cfg.enable {
    # Create telemetry data directory using systemd tmpfiles
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
    ];

    # Automatic collection on rebuild (uses systemd)
    systemd.services.nix-telemetry-collect = mkIf cfg.collectOnBuild {
      description = "Collect Nix configuration telemetry";
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${collectTelemetryScript}";
        User = "root";
      };
    };
  };
}
