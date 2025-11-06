{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    optionalString
    mkIf
    ;
  inherit (lib.strings) hasSuffix;
  cfg = config.telemetry;
  isLinux = hasSuffix "linux" hostSystem;

  collectTelemetryScript = pkgs.writeShellScript "collect-telemetry" ''
    #!/usr/bin/env bash


    TELEMETRY_DIR="${cfg.dataDir}"
    TELEMETRY_FILE="$TELEMETRY_DIR/telemetry.json"
    HISTORY_FILE="$TELEMETRY_DIR/history.json"


    mkdir -p "$TELEMETRY_DIR"


    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")


    SYSTEM_PACKAGES=$(${
      if isLinux then
        "nix-env -q --installed --profile /nix/var/nix/profiles/system | wc -l"
      else
        "nix-env -q --installed --profile /run/current-system | wc -l"
    })
    USER_PACKAGES=$(nix-env -q --installed | wc -l)


    ${
      if isLinux then
        ''
          CURRENT_GEN=$(nixos-rebuild list-generations 2>/dev/null | grep current | awk '{print $1}' || echo "unknown")
          TOTAL_GENS=$(nixos-rebuild list-generations 2>/dev/null | wc -l || echo "0")
        ''
      else
        ''
          CURRENT_GEN=$(darwin-rebuild --list-generations 2>/dev/null | grep current | awk '{print $1}' || echo "unknown")
          TOTAL_GENS=$(darwin-rebuild --list-generations 2>/dev/null | wc -l || echo "0")
        ''
    }


    if [ -f "$TELEMETRY_FILE" ]; then
      LAST_REBUILD=$(${pkgs.jq}/bin/jq -r '.lastRebuild // "0"' "$TELEMETRY_FILE")
      CURRENT_TIME=$(date +%s)
      DAYS_SINCE=$(( (CURRENT_TIME - LAST_REBUILD) / 86400 ))
    else
      DAYS_SINCE=0
    fi


    cat > "$TELEMETRY_FILE" <<EOF
    {
      "version": "1.0.0",
      "timestamp": "$TIMESTAMP",
      "hostname": "${config.networking.hostName or config.system.name or "unknown"}",
      "system": {
        "platform": "${hostSystem}",
        "nixVersion": "$(nix --version | awk '{print $3}')"
      },
      "features": ${builtins.toJSON (config.host.features or { })},
      "packages": {
        "system": $SYSTEM_PACKAGES,
        "user": $USER_PACKAGES,
        "total": $(( SYSTEM_PACKAGES + USER_PACKAGES ))
      },
      "generations": {
        "current": "$CURRENT_GEN",
        "total": $TOTAL_GENS
      },
      "rebuild": {
        "lastRebuild": $(date +%s),
        "daysSinceLastRebuild": $DAYS_SINCE,
        "rebuildsThisMonth": $(grep -c "$TIMESTAMP" "$HISTORY_FILE" 2>/dev/null | head -1 || echo "0")
      },
      "storeSize": "$(du -sh /nix/store 2>/dev/null | awk '{print $1}' || echo 'unknown')"
    }
    EOF


    if [ -f "$HISTORY_FILE" ]; then
      ${pkgs.jq}/bin/jq -s '. += [input]' "$HISTORY_FILE" "$TELEMETRY_FILE" > "$HISTORY_FILE.tmp"
      mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
    else
      cp "$TELEMETRY_FILE" "$HISTORY_FILE"
    fi


    ${pkgs.jq}/bin/jq --arg cutoff "$(date -d "${toString cfg.historyDays} days ago" +%s 2>/dev/null || date -v-${toString cfg.historyDays}d +%s)" \
      '[.[] | select(.rebuild.lastRebuild > ($cutoff | tonumber))]' \
      "$HISTORY_FILE" > "$HISTORY_FILE.tmp" || cp "$HISTORY_FILE" "$HISTORY_FILE.tmp"
    mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"

    ${optionalString cfg.verbose ''
      echo "📊 Telemetry collected:"
      echo "  System packages: $SYSTEM_PACKAGES"
      echo "  User packages: $USER_PACKAGES"
      echo "  Current generation: $CURRENT_GEN"
      echo "  Store size: $(du -sh /nix/store 2>/dev/null | awk '{print $1}' || echo 'unknown')"
      echo "  Data saved to: $TELEMETRY_FILE"
    ''}
  '';

  viewTelemetryScript = pkgs.writeShellScript "view-telemetry" ''
      #!/usr/bin/env bash


      TELEMETRY_FILE="${cfg.dataDir}/telemetry.json"
      HISTORY_FILE="${cfg.dataDir}/history.json"

        if [ ! -f "$TELEMETRY_FILE" ]; then
        echo "❌ No telemetry data found. Run collect-telemetry first."
        exit 1
      fi

      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "📊 Nix Configuration Telemetry"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""


      echo "📦 Current State:"
      ${pkgs.jq}/bin/jq -r '"  Hostname: \(.hostname)
    Platform: \(.system.platform)
    Nix Version: \(.system.nixVersion)

    Packages:
      System: \(.packages.system)
      User: \(.packages.user)
      Total: \(.packages.total)

    Generations:
      Current: \(.generations.current)
      Total: \(.generations.total)

    Store Size: \(.storeSize)"' "$TELEMETRY_FILE"

      echo ""
      echo "🎛️  Enabled Features:"
      ${pkgs.jq}/bin/jq -r '.features | to_entries | map("  \(.key): \(.value.enable // false)") | .[]' "$TELEMETRY_FILE"

      if [ -f "$HISTORY_FILE" ]; then
        echo ""
        echo "📈 Historical Trends:"

        REBUILD_COUNT=$(${pkgs.jq}/bin/jq length "$HISTORY_FILE")
        echo "  Total rebuilds tracked: $REBUILD_COUNT"

        AVG_PACKAGES=$(${pkgs.jq}/bin/jq '[.[].packages.total] | add / length | floor' "$HISTORY_FILE")
        echo "  Average packages: $AVG_PACKAGES"

        LAST_REBUILD=$(${pkgs.jq}/bin/jq -r '.[-1].rebuild.lastRebuild' "$HISTORY_FILE")
        DAYS_AGO=$(( ($(date +%s) - LAST_REBUILD) / 86400 ))
        echo "  Last rebuild: $DAYS_AGO days ago"

        echo ""
        echo "📅 Recent Rebuilds:"
        ${pkgs.jq}/bin/jq -r '.[-5:] | .[] | "  \(.timestamp) - \(.packages.total) packages"' "$HISTORY_FILE"
      fi

      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "💡 Usage Insights:"


      if ${pkgs.jq}/bin/jq -e '.features.development.enable' "$TELEMETRY_FILE" > /dev/null; then
        echo "  ✅ Development features are enabled"
      else
        echo "  ⚪ Development features are disabled"
      fi

      if ${pkgs.jq}/bin/jq -e '.features.gaming.enable' "$TELEMETRY_FILE" > /dev/null; then
        echo "  🎮 Gaming features are enabled"
      else
        echo "  ⚪ Gaming features are disabled"
      fi

      echo ""
      echo "📁 Data location: $TELEMETRY_FILE"
      echo "📁 History: $HISTORY_FILE"
      echo ""
  '';
in
{
  options.telemetry = {
    enable = mkEnableOption "local usage telemetry (privacy-first, nothing sent externally)";

    dataDir = mkOption {
      type = types.str;
      default = if isLinux then "/var/lib/nix-config-telemetry" else "\${HOME}/.nix-config-telemetry";
      description = "Directory to store telemetry data";
    };

    collectOnBuild = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically collect telemetry on system rebuild";
    };

    historyDays = mkOption {
      type = types.int;
      default = 90;
      description = "Number of days of history to keep";
    };

    verbose = mkOption {
      type = types.bool;
      default = false;
      description = "Show verbose output when collecting telemetry";
    };
  };

  config = mkIf cfg.enable {

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "collect-telemetry" ''
        exec ${collectTelemetryScript}
      '')
      (pkgs.writeShellScriptBin "view-telemetry" ''
        exec ${viewTelemetryScript}
      '')
    ];

    system.activationScripts.telemetry = mkIf (!isLinux) {
      text = ''
        mkdir -p ${cfg.dataDir}
      '';
    };

    system.activationScripts.telemetry-collect = mkIf (!isLinux && cfg.collectOnBuild) {
      text = ''
        ${collectTelemetryScript}
      '';
    };
  };
}
