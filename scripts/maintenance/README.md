# Maintenance Scripts

This directory contains maintenance and monitoring scripts for the Nix configuration.

## Scripts

### track-performance.sh

**Purpose**: Monthly performance tracking routine (Task 4.1)

**What it does**:

- Measures evaluation times (flake check, NixOS/Darwin)
- Tracks store size growth
- Monitors binary cache connectivity
- Collects system information
- Generates trend analysis

**Usage**:

```bash
./scripts/maintenance/track-performance.sh
```

**Output**: `.performance-metrics/YYYY-MM.json`

**Scheduling**: Run monthly via cron or systemd timer (see `docs/PERFORMANCE_MONITORING.md`)

### update-flake.sh

**Purpose**: Flake input freshness review (Task 4.3)

**What it does**:

- Updates flake inputs (all or specific)
- Monitors for deprecated/archived repositories
- Checks for FlakeHub alternatives
- Documents problematic inputs

**Usage**:

```bash
# Update all inputs
./scripts/maintenance/update-flake.sh

# Dry run (check what would change)
./scripts/maintenance/update-flake.sh --dry-run

# Update specific input
./scripts/maintenance/update-flake.sh --input nixpkgs
```

**Output**: `.flake-updates/report-YYYY-MM-DD.json` and change logs

**Scheduling**: Run weekly via cron or systemd timer (see `docs/PERFORMANCE_MONITORING.md`)

## Related Documentation

- **Performance Monitoring**: `docs/reference/performance-monitoring.md` - Comprehensive monitoring guide
- **Performance Tuning**: `docs/PERFORMANCE_TUNING.md` - Performance optimizations and baseline
- **Upstream Contributions**: `docs/UPSTREAM_CONTRIBUTIONS.md` - Overlay contribution tracking
- **Feature System**: `docs/FEATURES.md` - Feature system documentation

## Scheduling Examples

### systemd Timer (NixOS)

```nix
systemd.timers = {
  monthly-performance = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "monthly";
      Persistent = true;
    };
  };
  weekly-flake-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };
};

systemd.services = {
  monthly-performance = {
    serviceConfig.Type = "oneshot";
    script = "${pkgs.bash}/bin/bash ${./scripts/maintenance/track-performance.sh}";
  };
  weekly-flake-update = {
    serviceConfig.Type = "oneshot";
    script = "${pkgs.bash}/bin/bash ${./scripts/maintenance/update-flake.sh} --dry-run";
  };
};
```

### Cron (macOS/Darwin)

```bash
# Add to crontab (crontab -e)
# Monthly performance tracking (1st of month at midnight)
0 0 1 * * /path/to/scripts/maintenance/track-performance.sh

# Weekly flake update (Sundays at midnight)
0 0 * * 0 /path/to/scripts/maintenance/update-flake.sh --dry-run
```
