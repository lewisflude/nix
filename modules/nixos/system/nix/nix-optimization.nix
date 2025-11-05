{
  pkgs,
  config,
  lib,
  ...
}:
{
  config = {
    nix = {
      settings = {
        # Performance optimizations
        auto-optimise-store = true;
        max-jobs = "auto"; # Use all available CPU cores
        cores = 0; # Use all cores per build job (0 = auto)

        # Keep outputs/derivations for faster rebuilds and better caching
        keep-outputs = true; # Keep build outputs for better caching
        keep-derivations = true; # Keep .drv files for better rebuilds

        # Free space management
        min-free = 1073741824; # 1GB minimum free space
        max-free = 3221225472; # 3GB maximum free space

        # Download optimization (500MB buffer)
        download-buffer-size = 524288000;

        # High-throughput substitution parallelism (Tip 5)
        # Maximizes parallel TCP connections and substitution jobs for faster binary cache fetching
        # Optimized for high-RAM system (64GB) - set to 128 for maximum throughput
        # Note: With cache priorities properly set in flake.nix, timeout delays are minimized,
        # so higher parallelism (128) is safe and beneficial
        # Reference: https://brianmcgee.uk/posts/2023/12/13/how-to-optimise-substitutions-in-nix/
        http-connections = 128; # Parallel TCP connections (default: ~2-5, recommended: 64-128 for high-end)
        max-substitution-jobs = 128; # Concurrent substitution jobs (default: low, recommended: 64-128 for high-end)

        # Logging
        log-lines = 25; # Lines of build output to show on failure

        # Build-time input fetching (Tip 11)
        # Enables deferring source fetching until actual build time for inputs marked with buildTime = true
        # This speeds up flake evaluation by not fetching inputs during evaluation phase
        # Note: This is an experimental feature that must be enabled in both nixConfig and nix.settings
        extra-experimental-features = [
          "build-time-fetch-tree"
          "cgroups" # Execute builds inside cgroups (NixOS/Linux only - better build isolation)
        ];

        # Note: Binary caches, trusted-public-keys, and most experimental-features are configured
        # in flake.nix nixConfig section. Those settings apply to both Darwin and NixOS.
        # Platform-specific features like 'cgroups' are added here (NixOS only).
        # Determinate Nix's lazy-trees feature already speeds up evaluation significantly.
      };

      # Automatic garbage collection
      # Note: With Determinate Nix (nix.enable = false), Determinate Nixd handles GC automatically.
      # These options require nix.enable = true, so they're only set when NixOS manages the daemon.
      # When using Determinate Nix, rely on:
      # 1. Determinate Nixd's built-in GC
      # 2. nh clean service (configured in home/common/nh.nix)
      # 3. Manual cleanup via systemd timers (nix-store-optimization service below)
      gc = lib.mkIf config.nix.enable {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 3d"; # More aggressive: keep only 3 days instead of 7
      };

      # Automatic store optimization
      # Automatically hardlinks duplicate files in the store, recovering 20-40% space
      # Runs daily at 3:45 AM, after GC completes
      # Note: Requires nix.enable = true, so disabled when using Determinate Nix
      # Use systemd timers (nix-store-optimization service) instead for manual optimization
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
            # Lightweight duplicate cleanup - only runs first Monday of month
            # Uses pog-powered cleanup-duplicates tool

            CURRENT_DAY=$(date +%d)
            # Only run on first Monday (days 1-7)
            if [ "$CURRENT_DAY" -gt 7 ]; then
              echo "⏭️ Skipping duplicate cleanup (run on first Monday of month)"
              exit 0
            fi

            echo "🧹 Running monthly duplicate cleanup..."
            # Run non-interactive pog version (skip confirmations)
            cd /home/lewis/.config/nix
            nix run .#cleanup-duplicates -- --auto-confirm || true
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
      systemPackages = with pkgs; [
        (writeShellScriptBin "nix-optimize" ''
          exec /etc/nix-optimization/optimize-store.sh "$@"
        '')
        (writeShellScriptBin "nix-clean" ''
          exec /etc/nix-optimization/quick-clean.sh "$@"
        '')
        (writeShellScriptBin "nix-analyze" ''
          exec /etc/nix-optimization/analyze-store.sh "$@"
        '')
      ];
    };

    # NixOS-specific systemd services
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
          OnCalendar = "Mon 04:00:00"; # Run after optimization
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

    # Note: Darwin-specific launchd services should be in modules/darwin, not here
    # This is a NixOS-only module, so launchd configuration doesn't make sense here
  };
}
