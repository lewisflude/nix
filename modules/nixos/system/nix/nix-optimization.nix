{pkgs, ...}: {
  config = {
    nix.settings = {
      auto-optimise-store = true;
      max-jobs = "auto"; # Use all available CPU cores
      cores = 0; # Use all cores per build job (0 = auto)
      # Keep outputs/derivations for faster rebuilds and better caching
      keep-outputs = true; # Keep build outputs for better caching
      keep-derivations = true; # Keep .drv files for better rebuilds
      min-free = 1073741824;
      max-free = 3221225472;
      # Increased download buffer for faster binary cache downloads
      download-buffer-size = 524288000; # 500MB
      # Build reliability settings
      fallback = true; # Build from source if binary cache fails
      # Optimize substituter priority: personal cache first for fastest access
      substituters = [
        "https://lewisflude.cachix.org" # Personal cache - highest priority
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://ags.cachix.org"
        "https://catppuccin.cachix.org"
        "https://devenv.cachix.org"
        "https://yazi.cachix.org"
        "https://cuda-maintainers.cachix.org"
        "https://ghostty.cachix.org"
        "https://niri.cachix.org"
      ];
      trusted-substituters = [
        "https://lewisflude.cachix.org"
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://ags.cachix.org"
        "https://catppuccin.cachix.org"
        "https://devenv.cachix.org"
        "https://yazi.cachix.org"
        "https://cuda-maintainers.cachix.org"
        "https://ghostty.cachix.org"
        "https://niri.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "ags.cachix.org-1:naAvMrz0CuYqeyGNyLgE010iUiuf/qx6kYrUv3NwAJ8="
        "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "lewisflude.cachix.org-1:Y4J8FK/Rb7Es/PnsQxk2ZGPvSLup6ywITz8nimdVWXc="
        "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      ];
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
      ];
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
            # Full cleanup script available at: ~/.config/nix/scripts/cleanup-duplicates.sh

            CURRENT_DAY=$(date +%d)
            # Only run on first Monday (days 1-7)
            if [ "$CURRENT_DAY" -gt 7 ]; then
              echo "⏭️ Skipping duplicate cleanup (run on first Monday of month)"
              exit 0
            fi

            echo "🧹 Running monthly duplicate cleanup..."
            # Run non-interactive version (skip confirmations)
            CLEANUP_SCRIPT="/home/lewis/.config/nix/scripts/cleanup-duplicates.sh"
            if [ -f "$CLEANUP_SCRIPT" ]; then
              # Run in non-interactive mode (stdin not a terminal)
              NON_INTERACTIVE=1 bash "$CLEANUP_SCRIPT" </dev/null || true
            else
              echo "⚠️ Cleanup script not found at $CLEANUP_SCRIPT"
            fi
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

    # Automatic garbage collection
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 3d"; # More aggressive: keep only 3 days instead of 7
    };

    # NixOS-specific systemd services
    systemd = {
      timers.nix-store-optimization = {
        wantedBy = ["timers.target"];
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
        wantedBy = ["timers.target"];
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
