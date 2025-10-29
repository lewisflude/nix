# Native Media Management Services

This module provides declarative configuration for a complete media management stack using native NixOS services instead of containers.

## Services Included

### Indexers & Management

- **Prowlarr** (port 9696) - Indexer manager for Usenet and torrents
- **Radarr** (port 7878) - Movie collection manager
- **Sonarr** (port 8989) - TV show collection manager
- **Lidarr** (port 8686) - Music collection manager
- **Readarr** (port 8787) - Book/ebook collection manager
- **Whisparr** (port 6969) - Adult content manager (disabled by default)

### Download Clients

- **qBittorrent** (port 8080) - BitTorrent client with web UI
- **SABnzbd** (port 8082) - Usenet binary newsreader

### Media Server & Frontend

- **Jellyfin** (port 8096) - Open source media server
- **Jellyseerr** (port 5055) - Media request and discovery platform

### Utilities

- **FlareSolverr** (port 8191) - Proxy server to bypass Cloudflare protection
- **Unpackerr** - Automatic archive extractor for downloaded media

## Usage

### Basic Configuration

```nix
{
  host.services.mediaManagement = {
    enable = true;
    dataPath = "/mnt/storage";
    timezone = "Europe/London";
    user = "media";      # default
    group = "media";     # default
  };
}
```

This enables all services with default settings.

### Selective Services

```nix
{
  host.services.mediaManagement = {
    enable = true;
    dataPath = "/mnt/storage";

    # Disable services you don't need
    whisparr.enable = false;
    lidarr.enable = false;
    readarr.enable = false;
  };
}
```

### Advanced Configuration

Individual service options can be configured via the underlying NixOS modules:

```nix
{
  host.services.mediaManagement.enable = true;

  # Additional Radarr configuration
  services.radarr = {
    dataDir = "/custom/path";  # Override default
  };

  # Additional Jellyfin configuration
  services.jellyfin = {
    # Custom options here
  };
}
```

## Directory Structure

### Service State

Native services store their data in standard NixOS locations:

- `/var/lib/prowlarr`
- `/var/lib/radarr`
- `/var/lib/sonarr`
- `/var/lib/lidarr`
- `/var/lib/readarr`
- `/var/lib/whisparr`
- `/var/lib/qbittorrent`
- `/var/lib/sabnzbd`
- `/var/lib/jellyfin`
- `/var/lib/jellyseerr`

### Media Storage

Configure via `dataPath` option (default: `/mnt/storage`):

```
/mnt/storage/
├── media/
│   ├── movies/
│   ├── tv/
│   ├── music/
│   └── books/
├── torrents/
└── usenet/
```

## Features

### Automatic Setup

- ✅ User and group creation (`media` by default)
- ✅ Directory creation with proper permissions
- ✅ Firewall rules automatically configured
- ✅ systemd service ordering (Prowlarr starts before *arr apps)
- ✅ Timezone configuration

### qBittorrent VPN Isolation

- Optional WireGuard tunnel with dedicated network namespace
- Automatic tmpfiles, namespace setup, and firewall forwarding rules
- Secrets integration via `host.services.mediaManagement.qbittorrent.webUiCredentialsSecret` and `qbittorrent.vpn.privateKeySecret`

### Hardware Acceleration

- **Jellyfin**: Automatic GPU access for transcoding (`/dev/dri`)
- Media user automatically added to `render` and `video` groups

### Service Dependencies

Services have soft dependencies to prevent cascading failures:

- Radarr/Sonarr wait for Prowlarr (but don't fail if it's down)
- Jellyseerr waits for Jellyfin
- Unpackerr waits for *arr services

## Comparison: Containers vs Native

| Aspect | Containers | Native Modules |
|--------|-----------|----------------|
| Configuration | Compose files | Nix expressions |
| Updates | Manual pulls | `nixos-rebuild` |
| State location | `/var/lib/containers/...` | `/var/lib/<service>` |
| User management | PUID/PGID env vars | System users |
| Networking | Bridge networks | localhost |
| Firewall | Manual | Automatic |
| Logs | `podman logs` | `journalctl` |
| Dependencies | Container links | systemd ordering |

## Migration from Containers

See the [Migration Guide](../../../../docs/NATIVE-SERVICES-MIGRATION.md) for detailed instructions.

Quick migration:

1. Stop container services
2. Set `containers.enable = false`
3. Set `mediaManagement.enable = true`
4. Rebuild: `sudo nixos-rebuild switch`
5. (Optional) Copy data from `/var/lib/containers/...` to `/var/lib/<service>`

## Troubleshooting

### Check Service Status

```bash
systemctl status prowlarr radarr sonarr jellyfin
```

### View Logs

```bash
sudo journalctl -u radarr -f
```

### Restart Service

```bash
sudo systemctl restart radarr
```

### Check Permissions

```bash
ls -la /var/lib/radarr
sudo chown -R media:media /var/lib/radarr
```

### Port Conflicts

```bash
sudo ss -tlnp | grep :7878
```

## Module Structure

```
media-management/
├── default.nix         # Main module with options
├── prowlarr.nix        # Prowlarr configuration
├── radarr.nix          # Radarr configuration
├── sonarr.nix          # Sonarr configuration
├── lidarr.nix          # Lidarr configuration
├── readarr.nix         # Readarr configuration
├── whisparr.nix        # Whisparr configuration
├── qbittorrent.nix     # qBittorrent configuration
├── sabnzbd.nix         # SABnzbd configuration
├── jellyfin.nix        # Jellyfin configuration
├── jellyseerr.nix      # Jellyseerr configuration
├── flaresolverr.nix    # FlareSolverr configuration
└── unpackerr.nix       # Unpackerr custom service
```

## See Also

- [NixOS Service Options](https://search.nixos.org/options)
- [Prowlarr Wiki](https://wiki.servarr.com/prowlarr)
- [Jellyfin Documentation](https://jellyfin.org/docs/)
- [Migration Guide](../../../../docs/NATIVE-SERVICES-MIGRATION.md)
