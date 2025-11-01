# qBittorrent with VPN (WireGuard) Setup Guide

This guide covers the complete setup for running qBittorrent through a WireGuard VPN in a network namespace.

## Overview

The setup uses:

- **Network Namespace**: Isolates qBittorrent's network traffic
- **WireGuard**: Encrypted VPN tunnel
- **veth pair**: Bridges host and namespace networks
- **Privoxy**: HTTP proxy (optional, for other services)
- **Dante**: SOCKS5 proxy (for Prowlarr integration)
- **iptables**: Port forwarding rules

## Critical Configuration

### 1. Fixed Torrent Port (CRITICAL ⚠️)

```nix
qbittorrent = {
  randomizePort = false;  # MUST be false with VPN namespace
  torrentingPort = 6881;  # Fixed port for iptables rules
  # ...
};
```

**Why**: iptables rules forward traffic to a specific port in the namespace. If the port randomizes on startup, the forwarding won't match and torrents will fail.

### 2. Network Interface Configuration (CRITICAL ⚠️)

```nix
qbittorrent = {
  # These ensure qBittorrent listens on all interfaces in the namespace
  # So it can receive forwarded traffic from the host
  # (auto-configured in qbittorrent.nix module)
};
```

The module automatically sets:

- `Connection.ListenInterfaceValue = "0.0.0.0"`
- `Connection.InterfaceAddress = "0.0.0.0"`

This allows qBittorrent to receive traffic forwarded by iptables.

### 3. DNS Configuration (CRITICAL ⚠️)

```nix
qbittorrent = {
  vpn = {
    dns = [ "10.2.0.1" ];  # Upstream VPN DNS server
  };
};
```

**Why**: The namespace needs a DNS resolver to:

- Resolve tracker hostnames
- Resolve peer lookup services
- Avoid DNS leaks (queries go through VPN)

## Complete Example Configuration

```nix
mediaManagement = {
  enable = true;
  dataPath = "/mnt/storage";
  timezone = "Europe/London";

  qbittorrent = {
    enable = true;

    # WebUI credentials
    webUiUsername = "lewisflude";
    webUiPasswordHash = "@ByteArray(...)";
    webUiAuthSubnetWhitelist = [
      "127.0.0.1/32"
      "192.168.1.0/24"
      "10.0.0.0/8"
    ];

    # Download management
    downloadPath = "/mnt/storage/torrents";
    categoryPaths = {
      movies = "/mnt/storage/torrents/movies";
      tv = "/mnt/storage/torrents/tv";
    };

    # Speed limits (recommended for VPN)
    globalUploadLimit = 800;    # KiB/s - set to 70-80% of your max
    globalDownloadLimit = 3000;  # KiB/s

    # Torrent queueing
    maxActiveTorrents = 10;

    # Port configuration
    torrentingPort = 6881;
    randomizePort = false;  # CRITICAL: Must be false with VPN

    # Disk management
    preallocateDiskSpace = true;  # Prevents fragmentation
    deleteTorrentFile = false;     # Keep .torrent files
    useIncompleteFolder = false;   # Don't use separate incomplete folder with VPN

    # Encryption & privacy
    encryptionPolicy = "Enabled";  # Allow unencrypted for better peer discovery
    anonymousMode = false;         # NOT recommended - reduces peer connections

    # VPN Configuration (WireGuard in namespace)
    vpn = {
      enable = true;

      # Network configuration
      namespace = "qbittorrent";
      interfaceName = "wg-qbtvpn";
      addresses = [ "10.2.0.2/32" ];
      dns = [ "10.2.0.1" ];

      # Private key from sops-nix secret
      privateKeySecret = "qbittorrent/vpn/privateKey";

      # WireGuard peer (your VPN provider)
      peers = [
        {
          publicKey = "YOUR_VPN_PUBLIC_KEY";
          endpoint = "vpn.provider.com:51820";
          allowedIPs = [
            "0.0.0.0/0"     # Route all IPv4 through VPN
            "::/0"          # Route all IPv6 through VPN
          ];
          persistentKeepalive = 25;
        }
      ];

      # veth pair for host-namespace communication
      veth = {
        hostInterface = "qbt-host";
        namespaceInterface = "qbt-veth";
        hostAddress = "10.200.0.2/30";
        namespaceAddress = "10.200.0.1/30";
      };
    };
  };

  # Prowlarr with VPN proxy
  prowlarr = {
    enable = true;
    useVpnProxy = true;
    proxyType = "socks5";  # Use Dante SOCKS proxy
  };
};
```

## How the Setup Works

### 1. Network Namespace

```
Host Network          Namespace (qbittorrent)
─────────────────────────────────────────
                   wg-qbtvpn (WireGuard)
                   ↓ (encrypted tunnel)
qbt-host           qbt-veth → VPN Provider
(10.200.0.2)       (10.200.0.1)
```

### 2. Port Forwarding Flow

```
Torrent Peer → Port 6881 (host) → iptables NAT → Port 6881 (namespace) → qBittorrent
```

### 3. Traffic Flow

```
qBittorrent
  ↓
Namespace routing table
  ↓
WireGuard interface (encrypted)
  ↓
VPN Provider
```

## Verification & Troubleshooting

### Run the Verification Script

```bash
/home/lewis/.config/nix/scripts/verify-qbt-vpn.sh
```

This checks:

- Network namespace exists
- WireGuard interface is up
- veth pair is configured
- DNS is set in namespace
- iptables rules are in place
- Services are running
- Port connectivity
- VPN connectivity

### Common Issues

#### Issue: Torrents not downloading

**Check**:

1. Is `randomizePort` set to `false`?
2. Is the VPN interface up? `systemctl status wg-quick-wg-qbtvpn`
3. Are iptables rules correct? `iptables -t nat -L PREROUTING`
4. Can you access WebUI? `curl http://127.0.0.1:8080`

**Solution**:

```bash
# Restart services in order
sudo systemctl restart qbittorrent-netns.service
sudo systemctl restart wg-quick-wg-qbtvpn.service
sudo systemctl restart qbittorrent.service
```

#### Issue: DNS not resolving in namespace

**Check**:

1. Does `/run/netns/qbittorrent/etc/resolv.conf` exist?
2. Does it contain the correct nameserver?

**Test from namespace**:

```bash
sudo ip netns exec qbittorrent nslookup example.com
```

#### Issue: IPv6 leak

**Check**:

```bash
sudo ip netns exec qbittorrent ip -6 route show
```

**Should show**: No default route (only link-local routes)

If there's a default route, it's leaking IPv6:

```bash
sudo ip netns exec qbittorrent ip -6 route del default
```

#### Issue: WebUI unreachable

**Check**:

1. Is qBittorrent running in namespace?

```bash
sudo ip netns exec qbittorrent ps aux | grep qbittorrent
```

2. Is it listening on port 8080 in namespace?

```bash
sudo ip netns exec qbittorrent ss -tlnp | grep 8080
```

3. Are iptables rules forwarding correctly?

```bash
iptables -t nat -L PREROUTING -n | grep 8080
```

## Performance Tips

### 1. Speed Limits

Set realistic limits based on your VPN provider's limits:

```nix
globalUploadLimit = 800;      # Adjust to your VPN cap
globalDownloadLimit = 3000;   # Adjust to your VPN cap
```

### 2. Active Torrents

Limit concurrent downloads:

```nix
maxActiveTorrents = 10;
```

Too many torrents = worse performance on VPN.

### 3. Port Forwarding

Ensure your VPN provider has the port forwarded:

- Contact VPN provider support with port 6881
- Confirm it's fowrarded and open
- Test with `iptables -A INPUT -p tcp --dport 6881 -j ACCEPT`

### 4. Seeding Ratio

Set realistic limits in qBittorrent UI:

- `Bittorrent → Seeding Limits → Max ratio: 2.0`
- Use Radarr/Sonarr seeding goals instead

## Security Considerations

### ✅ What's Protected

- All qBittorrent traffic (encrypted + VPN routed)
- DNS queries (through VPN DNS)
- Peer IP addresses
- Tracker communication

### ⚠️ What's NOT Protected

- Your ISP still sees VPN traffic (not the torrent traffic itself)
- VPN provider can see your VPN traffic (choose trusted provider)
- IPv6 leaks if not properly configured

### Recommended Settings

```nix
encryptionPolicy = "Enabled";  # Force BT protocol encryption
anonymousMode = false;          # Better peer discovery
```

## Advanced: Manual Namespace Commands

```bash
# View namespace
ip netns list

# Execute command in namespace
sudo ip netns exec qbittorrent <command>

# Check network interfaces
sudo ip netns exec qbittorrent ip addr show
sudo ip netns exec qbittorrent ip route show

# Check WireGuard status
sudo ip netns exec qbittorrent wg show

# Test DNS
sudo ip netns exec qbittorrent nslookup tracker.example.com

# Check listening ports
sudo ip netns exec qbittorrent ss -tlnp
```

## References

- [WireGuard Documentation](https://www.wireguard.com/)
- [qBittorrent Documentation](https://github.com/qbittorrent/qBittorrent/wiki)
- [Linux Network Namespaces](https://man7.org/linux/man-pages/man7/network_namespaces.7.html)
- [iptables NAT Rules](https://wiki.archlinux.org/title/Iptables)

## Related Services

- **Prowlarr**: Indexer manager with VPN proxy support
- **Radarr**: Movie management (uses qBittorrent)
- **Sonarr**: TV show management (uses qBittorrent)
- **Privoxy**: HTTP proxy for namespace traffic
- **Dante**: SOCKS5 proxy for Prowlarr

For Prowlarr VPN proxy configuration, see the proxy settings:

- Proxy type: SOCKS5 (Dante) at `127.0.0.1:1080`
- Or HTTP at `127.0.0.1:8118` (Privoxy)
