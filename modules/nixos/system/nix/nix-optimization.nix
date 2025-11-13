{
  pkgs,
  config,
  lib,
  ...
}:
let
  flakeDir = "${config.users.users.${config.host.username}.home}/.config/nix";
in
{
  config = {
    nix = {

      gc = lib.mkIf config.nix.enable {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 3d";
      };

      optimise = lib.mkIf config.nix.enable {
        automatic = true;
        dates = [ "03:45" ];
      };
    };
    environment = {
      etc = {
        "nix-optimization/optimize-store.sh" = {
          text = ''
            set -euo pipefail
            echo "🧹 Starting Nix store optimization..."
            echo "📊 Current store size:"
            du -sh /nix/store
            echo "🗑️ Collecting garbage (older than 7 days)..."
            nix-collect-garbage --delete-older-than 7d
            echo "🔧 Optimizing store (deduplicating)..."
            nix store optimise
            echo "👤 Cleaning user profiles..."
            nix profile wipe-history --older-than 7d || true
            echo "📊 Final store size:"
            du -sh /nix/store
            echo "✅ Store optimization complete!"
          '';
          mode = "0755";
        };
        "nix-optimization/cleanup-duplicates.sh" = {
          text = ''
            set -euo pipefail



            CURRENT_DAY=$(date +%d)

            if [ "$CURRENT_DAY" -gt 7 ]; then
              echo "⏭️ Skipping duplicate cleanup (run on first Monday of month)"
              exit 0
            fi

            echo "🧹 Running monthly duplicate cleanup..."

            cd ${flakeDir}
            nix run .
          '';
          mode = "0755";
        };
        "nix-optimization/quick-clean.sh" = {
          text = ''
            set -euo pipefail
            echo "⚡ Quick Nix cleanup..."
            echo "Before: $(du -sh /nix/store | cut -f1)"
            nix-collect-garbage -d
            echo "After: $(du -sh /nix/store | cut -f1)"
            echo "✅ Quick cleanup complete!"
          '';
          mode = "0755";
        };
        "nix-optimization/analyze-store.sh" = {
          text = ''
            set -euo pipefail
            echo "🔍 Analyzing Nix store..."
            echo "📊 Store Statistics:"
            nix store info
            echo
            echo "📦 Largest store paths:"
            nix path-info --recursive --size /run/current-system | sort -nk2 | tail -20
            echo
            echo "🌳 Current GC roots:"
            nix-store --gc --print-roots | head -10
            echo
            echo "👤 Profile generations:"
            sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
          '';
        };
      };
      systemPackages = [
        (pkgs.writeShellScriptBin "nix-optimize" ''
          exec /etc/nix-optimization/optimize-store.sh "$@"
        '')
        (pkgs.writeShellScriptBin "nix-clean" ''
          exec /etc/nix-optimization/quick-clean.sh "$@"
        '')
        (pkgs.writeShellScriptBin "nix-analyze" ''
          exec /etc/nix-optimization/analyze-store.sh "$@"
        '')
      ];
    };

    systemd = {
      timers.nix-store-optimization = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "Mon 03:30:00";
          Persistent = true;
        };
      };
      services.nix-store-optimization = {
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "/etc/nix-optimization/optimize-store.sh";
        };
      };
      timers.nix-duplicate-cleanup = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "Mon 04:00:00";
          Persistent = true;
        };
      };
      services.nix-duplicate-cleanup = {
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "/etc/nix-optimization/cleanup-duplicates.sh";
        };
      };
    };

  };
}
