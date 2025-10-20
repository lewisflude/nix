# Container Configuration Backup Strategy

This document outlines the backup strategy for containerized services in this NixOS configuration.

## Overview

Containers have two types of data:
1. **Configuration data** - Settings, databases, state (MUST be backed up)
2. **Media/bulk data** - Movies, TV shows, music (backed up separately)

## What Gets Backed Up

### Container Configuration Paths

All container configurations are stored under `/var/lib/containers/`:

```
/var/lib/containers/
├── supplemental/              # Supplemental services configs
│   ├── homarr/               # Dashboard config & icons
│   ├── wizarr/               # Invitation system database
│   ├── doplarr/              # Discord bot config
│   ├── comfyui/              # AI models & workflows
│   └── calcom/               # Scheduling app data & database
│       ├── postgres/         # PostgreSQL database
│       └── app_data/         # Application data
└── music-assistant/          # Music Assistant state
```

### Native Service Paths

Native NixOS services store data in standard locations:

```
/var/lib/
├── prowlarr/                 # Indexer manager config
├── radarr/                   # Movie management database
├── sonarr/                   # TV show management database
├── lidarr/                   # Music management database
├── readarr/                  # Book management database
├── jellyfin/                 # Media server config & metadata
├── jellyseerr/               # Request management database
├── private/
│   ├── qbittorrent/         # Torrent client config
│   └── sabnzbd/             # Usenet client config
└── ollama/                   # LLM models (large, may exclude)
```

### What NOT to Back Up

- **Media files** (`/mnt/storage/media/`) - Too large, backed up via separate media backup strategy
- **Download directories** (`/mnt/storage/torrents/`, `/mnt/storage/usenet/`) - Temporary files
- **Container images** - Reproducible via Nix configuration
- **Logs** - Ephemeral data

## Automated Backup Service

### Using Restic (Recommended)

If you're already using Restic (your config has restic support), add a container backup job:

```nix
# In your host configuration (e.g., hosts/jupiter/configuration.nix)
{
  services.restic.backups = {
    # Your existing backups...
    
    # Add container configuration backup
    container-configs = {
      paths = [
        "/var/lib/containers/supplemental"
        "/var/lib/music-assistant"
        # Native services
        "/var/lib/prowlarr"
        "/var/lib/radarr"
        "/var/lib/sonarr"
        "/var/lib/lidarr"
        "/var/lib/readarr"
        "/var/lib/jellyfin"
        "/var/lib/jellyseerr"
        "/var/lib/private/qbittorrent"
        "/var/lib/private/sabnzbd"
      ];
      
      repository = "rest:https://your-restic-server:8000/container-configs";
      passwordFile = "/var/lib/restic/password";
      
      # Backup schedule
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
      
      # Retention policy
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
      ];
      
      # Exclude patterns
      exclude = [
        # Exclude cache directories
        "**/.cache"
        "**/cache"
        
        # Exclude logs
        "**/*.log"
        "**/logs"
        
        # Exclude temporary files
        "**/tmp"
        "**/.tmp"
        
        # Ollama models are huge, backup separately or exclude
        "/var/lib/ollama/models"
      ];
      
      # Pre-backup hook: Stop write-heavy services (optional)
      backupPrepareCommand = ''
        echo "Starting container config backup..."
        # Optionally stop services during backup
        # systemctl stop podman-calcom-db.service
      '';
      
      # Post-backup hook: Restart services
      backupCleanupCommand = ''
        # systemctl start podman-calcom-db.service
        echo "Container config backup completed"
      '';
    };
  };
}
```

### Manual Systemd Service (Alternative)

If not using Restic, create a simple backup service:

```nix
# In a shared module or host configuration
{
  systemd.services.container-config-backup = {
    description = "Backup container configurations";
    
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = pkgs.writeShellScript "backup-containers" ''
        set -euo pipefail
        
        BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
        BACKUP_DIR="/mnt/storage/backups/containers"
        BACKUP_FILE="$BACKUP_DIR/container-configs-$BACKUP_DATE.tar.gz"
        
        # Create backup directory
        mkdir -p "$BACKUP_DIR"
        
        echo "Starting backup to $BACKUP_FILE..."
        
        # Create compressed archive
        ${pkgs.gnutar}/bin/tar czf "$BACKUP_FILE" \
          -C /var/lib \
          containers/supplemental \
          music-assistant \
          prowlarr \
          radarr \
          sonarr \
          lidarr \
          readarr \
          jellyfin \
          jellyseerr \
          private/qbittorrent \
          private/sabnzbd \
          --exclude='*.log' \
          --exclude='cache' \
          --exclude='.cache'
        
        # Keep only last 30 days of backups
        find "$BACKUP_DIR" -name "container-configs-*.tar.gz" -mtime +30 -delete
        
        echo "Backup completed: $BACKUP_FILE"
        echo "Backup size: $(du -h "$BACKUP_FILE" | cut -f1)"
      '';
    };
  };
  
  # Run backup daily at 2 AM
  systemd.timers.container-config-backup = {
    description = "Daily container configuration backup";
    wantedBy = ["timers.target"];
    
    timerConfig = {
      OnCalendar = "daily";
      OnBootSec = "15min";  # Also backup 15min after boot
      Persistent = true;
    };
  };
}
```

## Backup Verification

### Automated Testing

Add a verification service that runs weekly:

```nix
systemd.services.container-backup-verify = {
  description = "Verify container backup integrity";
  
  serviceConfig = {
    Type = "oneshot";
    User = "root";
    ExecStart = pkgs.writeShellScript "verify-backup" ''
      set -euo pipefail
      
      # For Restic
      ${pkgs.restic}/bin/restic -r rest:https://your-server:8000/container-configs \
        check --read-data-subset=5%
      
      # Or for tar backups
      LATEST_BACKUP=$(ls -t /mnt/storage/backups/containers/container-configs-*.tar.gz | head -1)
      echo "Verifying: $LATEST_BACKUP"
      ${pkgs.gnutar}/bin/tar tzf "$LATEST_BACKUP" > /dev/null
      echo "Backup verification successful"
    '';
  };
};

systemd.timers.container-backup-verify = {
  description = "Weekly backup verification";
  wantedBy = ["timers.target"];
  timerConfig = {
    OnCalendar = "weekly";
    Persistent = true;
  };
};
```

## Disaster Recovery Procedure

### Complete System Recovery

1. **Rebuild NixOS system from configuration:**
   ```bash
   nixos-rebuild switch --flake .#jupiter
   ```

2. **Restore container configurations from Restic:**
   ```bash
   # Stop all container services
   systemctl stop podman-*.service
   
   # Restore from backup
   restic -r rest:https://your-server:8000/container-configs \
     restore latest \
     --target /
   
   # Fix permissions if needed
   chown -R 1000:100 /var/lib/containers/supplemental
   
   # Start services
   systemctl start podman-*.service
   ```

3. **Or restore from tar backup:**
   ```bash
   systemctl stop podman-*.service
   
   cd /
   tar xzf /mnt/storage/backups/containers/container-configs-YYYYMMDD_HHMMSS.tar.gz
   
   systemctl start podman-*.service
   ```

### Single Service Recovery

Example: Restore only Cal.com database:

```bash
# Stop service
systemctl stop podman-calcom.service podman-calcom-db.service

# Restore specific path
restic -r rest:https://your-server:8000/container-configs \
  restore latest \
  --target / \
  --include /var/lib/containers/supplemental/calcom

# Or from tar
tar xzf backup.tar.gz -C / containers/supplemental/calcom

# Restart service
systemctl start podman-calcom-db.service podman-calcom.service
```

## Monitoring Backup Health

### Email Notifications (Optional)

```nix
systemd.services.container-config-backup = {
  # ... existing config ...
  
  serviceConfig = {
    # Send email on failure
    OnFailure = ["notify-backup-failure@%n.service"];
  };
};

# Create notification service
systemd.services."notify-backup-failure@" = {
  description = "Send email notification on backup failure";
  serviceConfig = {
    Type = "oneshot";
    ExecStart = pkgs.writeShellScript "notify-failure" ''
      echo "Backup job %i failed on $(hostname)" | \
        ${pkgs.mailutils}/bin/mail -s "Backup Failed" admin@example.com
    '';
  };
};
```

### Prometheus Monitoring (Advanced)

Export backup metrics for monitoring:

```nix
systemd.services.container-config-backup = {
  # ... existing config ...
  
  serviceConfig.ExecStartPost = pkgs.writeShellScript "backup-metrics" ''
    # Write metrics to node_exporter textfile collector
    cat > /var/lib/prometheus-node-exporter/container_backup.prom <<EOF
    # HELP container_backup_last_success_timestamp_seconds Last successful backup
    # TYPE container_backup_last_success_timestamp_seconds gauge
    container_backup_last_success_timestamp_seconds $(date +%s)
    
    # HELP container_backup_size_bytes Size of last backup
    # TYPE container_backup_size_bytes gauge
    container_backup_size_bytes $(stat -f%z "$BACKUP_FILE" 2>/dev/null || echo 0)
    EOF
  '';
};
```

## Best Practices

### ✅ DO

1. **Backup before major changes** - Manual backup before upgrades
2. **Test restores regularly** - Verify backups work (monthly)
3. **Monitor backup jobs** - Check for failures
4. **Document recovery procedures** - Keep this guide updated
5. **Use encryption** - Restic encrypts by default
6. **Keep multiple retention periods** - Daily, weekly, monthly
7. **Store backups off-site** - Remote Restic server or S3

### ❌ DON'T

1. **Don't backup media files with configs** - Too large, separate strategy
2. **Don't skip verification** - Backups are useless if they don't restore
3. **Don't ignore backup failures** - Set up monitoring
4. **Don't store backups on same disk** - Defeats the purpose
5. **Don't backup secrets to unencrypted storage** - Use Restic encryption

## Container-Specific Backup Notes

### PostgreSQL (Cal.com)

PostgreSQL should be backed up with proper dumps for consistency:

```bash
# Better approach for PostgreSQL
podman exec calcom-db pg_dump -U calcom calcom > /var/lib/containers/supplemental/calcom/calcom-dump.sql

# Include in backup
services.restic.backups.container-configs.backupPrepareCommand = ''
  podman exec calcom-db pg_dump -U calcom calcom > \
    /var/lib/containers/supplemental/calcom/calcom-dump.sql
'';
```

### Jellyfin

Jellyfin stores metadata that can be large. Consider excluding thumbnail caches:

```nix
exclude = [
  "/var/lib/jellyfin/metadata/library/*/Season */thumbs"
  "/var/lib/jellyfin/transcodes"
];
```

### Ollama Models

Ollama models are huge (4-70GB per model). Options:
- Exclude from backup (models are reproducible via configuration)
- Backup separately with lower frequency
- Store on dedicated volume with separate backup policy

## Testing Your Backup

Create a test restore script:

```bash
# test-restore.sh
#!/usr/bin/env bash
set -euo pipefail

RESTORE_DIR="/tmp/backup-test"
rm -rf "$RESTORE_DIR"
mkdir -p "$RESTORE_DIR"

echo "Testing backup restore to $RESTORE_DIR..."

restic -r rest:https://your-server:8000/container-configs \
  restore latest \
  --target "$RESTORE_DIR"

echo "Verifying restored files..."
test -d "$RESTORE_DIR/var/lib/containers/supplemental/homarr" || exit 1
test -f "$RESTORE_DIR/var/lib/prowlarr/config.xml" || exit 1

echo "✅ Backup restore test successful"
rm -rf "$RESTORE_DIR"
```

Run monthly: `systemctl enable --now backup-test.timer`

## Additional Resources

- [Restic Documentation](https://restic.readthedocs.io/)
- [PostgreSQL Backup Best Practices](https://www.postgresql.org/docs/current/backup.html)
- [Container Backup Strategies](https://docs.docker.com/storage/volumes/#backup-restore-or-migrate-data-volumes)
