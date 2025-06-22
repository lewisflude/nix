{ pkgs, username, lib, system, ... }:

{
  # Nix Store Optimization and Garbage Collection Configuration
  
  nix.settings = {
    # Store optimization
    auto-optimise-store = true;
    
    # Build optimization
    max-jobs = "auto";
    cores = 0; # Use all available cores
    
    # Cache optimization
    keep-outputs = false; # Don't keep build outputs for GC roots
    keep-derivations = false; # Don't keep derivations for GC roots
    
    # Reduce store size
    min-free = 1073741824; # 1GB - start GC when free space is below this
    max-free = 3221225472; # 3GB - stop GC when free space reaches this
    
    # Binary cache settings for faster builds
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://cache.determinate.systems"
    ];
    
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.determinate.systems-1:cd9bVm9wnyQHfHpLRhHGDMWWgPEXFEoKhiMuQ1jmNj8="
    ];
    
    # Experimental features for performance
    experimental-features = [
      "nix-command"
      "flakes"
      "ca-derivations" # Content-addressed derivations
    ];
  };
  
  # System-wide packages for store management
  environment.systemPackages = with pkgs; [
    nix-tree # Visualize Nix store dependencies
    nix-du   # Analyze store disk usage
  ];
  
  # Store optimization scripts
  environment.etc."nix-optimization/optimize-store.sh".text = ''
    #!/usr/bin/env bash
    # Comprehensive Nix store optimization script
    
    set -euo pipefail
    
    echo "🧹 Starting Nix store optimization..."
    
    # 1. Show current store size
    echo "📊 Current store size:"
    du -sh /nix/store
    
    # 2. Garbage collect old generations
    echo "🗑️ Collecting garbage (older than 7 days)..."
    nix-collect-garbage --delete-older-than 7d
    
    # 3. Optimize store (deduplicate)
    echo "🔧 Optimizing store (deduplicating)..."
    nix store optimise
    
    # 4. Clean up user profiles
    echo "👤 Cleaning user profiles..."
    nix profile wipe-history --older-than 7d || true
    
    # 5. Show final store size
    echo "📊 Final store size:"
    du -sh /nix/store
    
    echo "✅ Store optimization complete!"
  '';
  
  # Quick cleanup script for manual use
  environment.etc."nix-optimization/quick-clean.sh".text = ''
    #!/usr/bin/env bash
    # Quick cleanup for immediate space recovery
    
    set -euo pipefail
    
    echo "⚡ Quick Nix cleanup..."
    
    # Show current size
    echo "Before: $(du -sh /nix/store | cut -f1)"
    
    # Quick garbage collection
    nix-collect-garbage -d
    
    # Show final size
    echo "After: $(du -sh /nix/store | cut -f1)"
    
    echo "✅ Quick cleanup complete!"
  '';
  
  # Store analysis script
  environment.etc."nix-optimization/analyze-store.sh".text = ''
    #!/usr/bin/env bash
    # Analyze Nix store usage and find large packages
    
    set -euo pipefail
    
    echo "🔍 Analyzing Nix store..."
    
    # Store statistics
    echo "📊 Store Statistics:"
    nix store info
    echo
    
    # Largest store paths
    echo "📦 Largest store paths:"
    nix path-info --recursive --size /run/current-system | sort -nk2 | tail -20
    echo
    
    # Show roots keeping things alive
    echo "🌳 Current GC roots:"
    nix-store --gc --print-roots | head -10
    echo
    
    # Show profile generations
    echo "👤 Profile generations:"
    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
  '';
  
  # Make scripts executable
  system.activationScripts.nix-optimization.text = ''
    chmod +x /etc/nix-optimization/*.sh
    
    # Create symlinks for easy access
    ln -sf /etc/nix-optimization/optimize-store.sh /usr/local/bin/nix-optimize || true
    ln -sf /etc/nix-optimization/quick-clean.sh /usr/local/bin/nix-clean || true
    ln -sf /etc/nix-optimization/analyze-store.sh /usr/local/bin/nix-analyze || true
  '';

  # Platform-specific garbage collection
  # NixOS/Linux - use systemd timers and built-in garbage collection
  nix.gc = lib.mkIf (lib.hasInfix "linux" system) {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  
} // lib.optionalAttrs (lib.hasInfix "linux" system) {
  # Systemd timer for store optimization (Linux only)
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
  };

} // lib.optionalAttrs (lib.hasInfix "darwin" system) {
  # Darwin-specific launchd configuration  
  launchd = {
    daemons.nix-garbage-collection = {
      serviceConfig = {
        ProgramArguments = [
          "/nix/var/nix/profiles/default/bin/nix-collect-garbage"
          "--delete-older-than"
          "7d"
        ];
        StartCalendarInterval = [
          {
            Hour = 3;
            Minute = 15;
            Weekday = 1; # Monday at 3:15 AM
          }
        ];
        StandardOutPath = "/var/log/nix-gc.log";
        StandardErrorPath = "/var/log/nix-gc-error.log";
        RunAtLoad = false;
      };
    };

    daemons.nix-store-optimization = {
      serviceConfig = {
        ProgramArguments = [
          "/etc/nix-optimization/optimize-store.sh"
        ];
        StartCalendarInterval = [
          {
            Hour = 3;
            Minute = 30;
            Weekday = 1; # Monday at 3:30 AM
          }
        ];
        StandardOutPath = "/var/log/nix-optimization.log";
        StandardErrorPath = "/var/log/nix-optimization-error.log";
        RunAtLoad = false;
      };
    };
  };
}