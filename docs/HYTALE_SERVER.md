# Hytale Server on NixOS

Complete guide for hosting a Hytale game server on NixOS with declarative configuration.

## Overview

This repository provides a NixOS module for running Hytale game servers with:

- **Java 25 runtime** (required by Hytale)
- **QUIC protocol** over UDP (not TCP)
- **OAuth device authentication**
- **Automatic backups** (optional)
- **Systemd service** with proper lifecycle management
- **Security hardening** and resource limits
- **Declarative configuration** following repository patterns

## Quick Start

### 1. Flatpak Installation (Recommended)

The easiest way to get server files is via the Hytale Flatpak:

```bash
flatpak install flathub com.hypixel.HytaleLauncher
```

The module **automatically detects** the Flatpak installation and symlinks the required files. No manual copying needed!

### 2. Configure in NixOS

**Option A: Zero Configuration (Flatpak)**

If you have Hytale installed via Flatpak, just enable it:

```nix
# In hosts/<hostname>/default.nix
host.features.hytaleServer = {
  enable = true;
  memory = {
    max = "8G";
    min = "4G";
  };
  # That's it! Files auto-detected from Flatpak
};
```

**Option B: Manual File Paths**

If not using Flatpak, specify paths manually:

```nix
services.hytaleServer = {
  enable = true;
  serverFiles = {
    jarPath = "/path/to/HytaleServer.jar";
    assetsPath = "/path/to/Assets.zip";
  };
  jvmArgs = [
    "-XX:AOTCache=/var/lib/hytale-server/HytaleServer.aot"
    "-Xmx8G"
    "-Xms4G"
  ];
};
```

### 3. Rebuild and Start

```bash
# Rebuild system (files are auto-linked during activation)
nh os switch

# Service starts automatically on boot, or start manually
sudo systemctl start hytale-server

# Watch for authentication prompt
sudo journalctl -u hytale-server -f
```

**What happens during rebuild:**
- Module detects Flatpak installation at `~/.var/app/com.hypixel.HytaleLauncher/`
- Symlinks `HytaleServer.jar`, `Assets.zip`, and `HytaleServer.aot` to `/var/lib/hytale-server/`
- Sets correct permissions for `hytale-server` user
- Files stay in sync with Flatpak updates automatically

### 4. Authenticate (First Run Only)

The service will output a device authorization URL:

```
Visit: https://accounts.hytale.com/device
Enter code: ABCD-1234
```

Complete the OAuth flow in your browser. The server will then start normally.

## Flatpak Integration

The module automatically detects and uses Hytale server files from the Flatpak installation:

### Auto-Detection

Scans for Flatpak at:
- `~/.var/app/com.hypixel.HytaleLauncher/data/Hytale/install/release/package/game/latest`

### Symlink vs Copy

**Symlink (default, recommended):**
```nix
services.hytaleServer.serverFiles.symlinkFromFlatpak = true;  # Default
```
- ✅ No disk space duplication
- ✅ Automatic updates when Flatpak updates
- ✅ Always in sync with launcher version
- ⚠️ Requires Flatpak to remain installed

**Copy mode:**
```nix
services.hytaleServer.serverFiles.symlinkFromFlatpak = false;
```
- ✅ Server files independent of Flatpak
- ✅ Can uninstall Flatpak after copy
- ⚠️ Uses extra ~3.7GB disk space
- ⚠️ Manual updates required

### Manual Override

Override auto-detection if needed:

```nix
services.hytaleServer.serverFiles = {
  flatpakSourceDir = "/home/otheruser/.var/app/com.hypixel.HytaleLauncher/data/Hytale/install/release/package/game/latest";
  # Or set paths explicitly:
  jarPath = "/custom/path/HytaleServer.jar";
  assetsPath = "/custom/path/Assets.zip";
};
```

## Configuration Options

### Service Module (`services.hytaleServer`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable the Hytale server |
| `port` | int | `5520` | UDP port (QUIC protocol) |
| `authMode` | enum | `"authenticated"` | `"authenticated"` or `"offline"` |
| `dataDir` | string | `/var/lib/hytale-server` | Data directory for worlds and configs |
| `serverFiles.jarPath` | string | `null` | Path to HytaleServer.jar (auto-detect if null) |
| `serverFiles.assetsPath` | string | `null` | Path to Assets.zip (auto-detect if null) |
| `serverFiles.flatpakSourceDir` | string | `null` | Override Flatpak path detection |
| `serverFiles.symlinkFromFlatpak` | bool | `true` | Symlink instead of copy |
| `jvmArgs` | list | `["-XX:AOTCache=..." "-Xmx4G" "-Xms2G"]` | JVM arguments |
| `backup.enable` | bool | `false` | Enable automatic backups |
| `backup.directory` | string | `${dataDir}/backups` | Backup location |
| `backup.frequency` | int | `30` | Backup interval (minutes) |
| `disableSentry` | bool | `false` | Disable crash reporting |
| `extraArgs` | list | `[]` | Extra server arguments |
| `openFirewall` | bool | `true` | Auto-open UDP firewall port |
| `bindAddress` | string | `"0.0.0.0"` | Bind address |

### Feature Flag (`host.features.hytaleServer`)

Simplified high-level options that map to service configuration:

```nix
host.features.hytaleServer = {
  enable = true;
  port = 5520;
  authMode = "authenticated";
  memory = {
    max = "8G";
    min = "4G";
  };
  backup = {
    enable = true;
    frequency = 60;  # Every hour
  };
  disableSentry = false;
};
```

## Network Configuration

### Firewall

Hytale uses **QUIC protocol over UDP** (not TCP). The module automatically opens the UDP port if `openFirewall = true`.

**Manual firewall rules**:

```bash
# Linux (iptables)
sudo iptables -A INPUT -p udp --dport 5520 -j ACCEPT

# Linux (ufw)
sudo ufw allow 5520/udp

# NixOS (if openFirewall = false)
networking.firewall.allowedUDPPorts = [ 5520 ];
```

### Port Forwarding

If hosting behind a router, forward **UDP port 5520** (not TCP) to your server's IP address.

**Important**: QUIC uses UDP exclusively. TCP forwarding is not required or used.

## Authentication

### OAuth Device Flow (Default)

On first launch, the server requires OAuth authentication:

1. Service starts and outputs authentication URL
2. Watch logs: `sudo journalctl -u hytale-server -f`
3. Visit the URL in your browser
4. Enter the displayed code
5. Server authenticates and starts

Authentication tokens are stored in the data directory and persist across restarts.

### Server Limits

- **Free accounts**: Up to 100 servers per Hytale license
- **Server Provider accounts**: Higher limits available ([apply here](https://support.hytale.com/hc/en-us/articles/server-provider-authentication-guide))

### Offline Mode (Testing Only)

For development/testing, you can skip authentication:

```nix
services.hytaleServer.authMode = "offline";
```

**Warning**: Offline mode is unsupported and intended for testing only. Production servers should use `"authenticated"`.

## File Structure

```
/var/lib/hytale-server/
├── HytaleServer.jar          # Server binary
├── Assets.zip                 # Game assets
├── HytaleServer.aot          # AOT cache (auto-generated)
├── universe/                 # World data
│   └── worlds/
│       └── <world-uuid>/
│           ├── config.json   # World configuration
│           └── ...           # Chunk data
├── logs/                     # Server logs
├── mods/                     # Server mods
├── backups/                  # Automatic backups (if enabled)
├── .cache/                   # Internal cache
├── config.json               # Server configuration
├── permissions.json          # Permission settings
├── bans.json                 # Banned players
└── whitelist.json            # Whitelisted players
```

## Performance Tuning

### Memory

Adjust JVM heap size based on expected player count:

| Players | Min RAM | Max RAM |
|---------|---------|---------|
| 5-10    | 2GB     | 4GB     |
| 10-20   | 4GB     | 8GB     |
| 20+     | 8GB     | 16GB+   |

```nix
services.hytaleServer.jvmArgs = [
  "-XX:AOTCache=/var/lib/hytale-server/HytaleServer.aot"
  "-Xmx16G"  # Maximum heap
  "-Xms8G"   # Initial heap
];
```

### View Distance

**Critical Performance Note**: Hytale's default view distance of **384 blocks** is equivalent to **24 Minecraft chunks**. This is 2.4x higher than Minecraft's default (10 chunks) and significantly increases RAM usage.

**Recommendation**: Limit view distance to 12 chunks (384 blocks) in world `config.json`:

```json
{
  "ViewDistance": 12
}
```

This balances performance and gameplay. Lower values reduce RAM usage at the cost of render distance.

### AOT Cache

The server includes a pre-trained Ahead-of-Time (AOT) cache that improves boot times by skipping JIT warmup (JEP-514):

```nix
services.hytaleServer.jvmArgs = [
  "-XX:AOTCache=/var/lib/hytale-server/HytaleServer.aot"
  # ... other args
];
```

The cache is automatically generated on first run and reused on subsequent starts.

## Automatic Backups

Enable built-in backup system:

```nix
services.hytaleServer.backup = {
  enable = true;
  directory = "/var/lib/hytale-server/backups";
  frequency = 30;  # minutes
};
```

Backups include:
- World data (`universe/`)
- Configuration files
- Player data

**External Backups**: For production servers, also configure system-level backups (e.g., ZFS snapshots, restic, borg).

## Troubleshooting

### Service Won't Start

**Check logs**:
```bash
sudo journalctl -u hytale-server -n 100
```

**Common issues**:
- Missing jar/assets files (validation will catch this)
- Incorrect file permissions
- Java version mismatch

**Verify files**:
```bash
sudo -u hytale-server ls -la /var/lib/hytale-server/
```

### Authentication Issues

- OAuth flow must be completed in a browser
- Tokens stored in data directory
- If auth expires, restart service and re-authenticate

### Connection Issues

**Firewall check**:
```bash
# Check if UDP port is open
sudo ss -ulnp | grep 5520

# Test with firewall-cmd (if using firewalld)
sudo firewall-cmd --list-ports
```

**Port forwarding**:
- Ensure UDP (not TCP) port is forwarded
- Verify router configuration
- Test from external network

### Performance Issues

**Monitor resources**:
```bash
# CPU and memory usage
htop -p $(pgrep -f HytaleServer)

# Real-time logs
sudo journalctl -u hytale-server -f
```

**Tuning tips**:
- Increase `-Xmx` if RAM usage is near limit
- Lower view distance in world config
- Monitor garbage collection with `-XX:+PrintGCDetails`
- Use G1GC: `-XX:+UseG1GC`

### Java Version Warning

If you see a warning about Java 25 not being available:

```nix
# Option 1: Update nixpkgs
nix flake update

# Option 2: Use Adoptium flake input
# Add to flake.nix inputs:
# temurin = { url = "github:adoptium/temurin-nix-flake"; };

# Option 3: Wait for nixpkgs to package Java 25
# The server may work with newer JDK versions but this is unsupported
```

## Advanced Configuration

### Custom JVM Arguments

```nix
services.hytaleServer.jvmArgs = [
  "-XX:AOTCache=/var/lib/hytale-server/HytaleServer.aot"
  "-Xmx16G"
  "-Xms8G"
  "-XX:+UseG1GC"                # G1 garbage collector
  "-XX:MaxGCPauseMillis=200"    # GC pause target
  "-XX:+ParallelRefProcEnabled" # Parallel reference processing
];
```

### Server Arguments

See all available options:
```bash
java -jar HytaleServer.jar --help
```

Common options:
```nix
services.hytaleServer.extraArgs = [
  "--accept-early-plugins"  # Load early plugins (unsupported, may cause instability)
];
```

### Multiple Servers

Run multiple Hytale instances:

```nix
# First server
services.hytaleServer = {
  enable = true;
  port = 5520;
  dataDir = "/var/lib/hytale-server-1";
  # ...
};

# Second server (manual service)
systemd.services.hytale-server-2 = {
  # Copy service config and modify port/dataDir
};
```

### Mods and Plugins

Drop mods (`.zip` or `.jar`) into `${dataDir}/mods/`:

```bash
sudo cp my-mod.zip /var/lib/hytale-server/mods/
sudo chown hytale-server:hytale-server /var/lib/hytale-server/mods/my-mod.zip
sudo systemctl restart hytale-server
```

**Recommended Plugins** (from Nitrado and Apex Hosting):
- `Nitrado:WebServer` - Base plugin for web APIs
- `Nitrado:Query` - Expose server status via HTTP
- `Nitrado:PerformanceSaver` - Dynamic view distance based on resources
- `ApexHosting:PrometheusExporter` - Metrics for monitoring

## Architecture

The implementation follows repository patterns with proper separation:

**Service Module**: `modules/nixos/services/hytale-server/default.nix`
- Low-level systemd service configuration
- File management and permissions
- Security hardening

**Feature Flag**: `modules/nixos/features/hytale-server.nix`
- High-level feature bridge
- Maps to service module

**Host Options**: `modules/shared/host-options/features/hytale-server.nix`
- Per-host configuration options
- Simplified interface

**Constants**: `lib/constants.nix`
```nix
ports.services.hytaleServer = 5520;
```

**Overlay**: `overlays/default.nix`
- Java 25 package with fallback warning

## Known Limitations

1. **Protocol Version Matching**: Client and server must be on the exact same version. Support for ±2 version tolerance is coming soon.

2. **Java 25 Requirement**: Hytale officially requires Java 25. The module will fall back to the latest JDK with a warning if Java 25 is unavailable in nixpkgs.

3. **Manual File Management**: Server files must be copied manually or via `hytale-downloader` CLI. Automatic download integration is planned.

4. **Single Instance**: The module is optimized for single-server deployments. Multi-server setups require manual service duplication.

## Future Improvements

Potential enhancements:

- [ ] **Hytale Downloader Integration**: Auto-download server files
- [ ] **Multi-server Support**: Native support for multiple instances
- [ ] **SRV Record Support**: Domain-based connections (pending C# library)
- [ ] **Metrics Exporter**: Prometheus integration for monitoring
- [ ] **Web Panel**: Optional web UI for server management

## References

- [Hytale Server Manual](https://support.hytale.com/hc/en-us/articles/hytale-server-manual) - Official documentation
- [Server Provider Guide](https://support.hytale.com/hc/en-us/articles/server-provider-authentication-guide) - High-volume server authentication
- [Java 25 (Adoptium)](https://adoptium.net/temurin/releases/) - Recommended JDK
- [JEP-514: AOT Cache](https://openjdk.org/jeps/514) - Ahead-of-Time compilation

## Support

For issues with the NixOS module, check:
- Service logs: `sudo journalctl -u hytale-server -f`
- File permissions: `sudo -u hytale-server ls -la /var/lib/hytale-server/`
- Network configuration: `sudo ss -ulnp | grep 5520`

For Hytale server issues, consult the [official support site](https://support.hytale.com/).
