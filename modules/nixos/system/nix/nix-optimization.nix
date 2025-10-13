{pkgs, ...}: {
  config = {
    nix.settings = {
      auto-optimise-store = true;
      max-jobs = 24;
      cores = 0;
      keep-outputs = false;
      keep-derivations = false;
      min-free = 1073741824;
      max-free = 3221225472;
      download-buffer-size = 524288000;
      substituters = [
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
        "https://install.determinate.systems"
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
        "https://install.determinate.systems"
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
        "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
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
    };

    # Note: Darwin-specific launchd services should be in modules/darwin, not here
    # This is a NixOS-only module, so launchd configuration doesn't make sense here
  };
}
