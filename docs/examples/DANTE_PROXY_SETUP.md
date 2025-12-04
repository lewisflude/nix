# Dante SOCKS Proxy Setup

> **⚠️ DEPRECATED**: This service has been disabled as VLAN2 no longer exists in the network configuration. This documentation is kept for reference only.

This guide shows how to use the Dante SOCKS proxy to route traffic through a specific network interface.

## Overview

The Dante proxy module (`services.dante-proxy`) provides a SOCKS proxy server that can bind to a specific network interface for selective traffic routing.

## Basic Configuration

Add to your host configuration (e.g., `hosts/jupiter/configuration.nix`):

```nix
{
  services.dante-proxy = {
    enable = true;
    port = 1080;  # Default SOCKS port
    interface = "vlan2";  # Routes through VPN
    listenAddress = "0.0.0.0";  # Listen on all interfaces

    # Allow connections from local network
    allowedClients = [
      "127.0.0.1/32"      # Localhost
      "192.168.0.0/16"    # Local network
    ];

    # Open firewall if you want other devices to use the proxy
    openFirewall = false;  # Set to true for network-wide access
  };
}
```

## Configuration Options

### Localhost Only (Most Secure)

```nix
services.dante-proxy = {
  enable = true;
  listenAddress = "127.0.0.1";  # Only local connections
  openFirewall = false;
};
```

### Network-Wide Access

```nix
services.dante-proxy = {
  enable = true;
  listenAddress = "0.0.0.0";  # All interfaces
  allowedClients = [
    "192.168.10.0/24"  # Main network
    "192.168.2.0/24"  # VLAN 2 network
  ];
  openFirewall = true;  # Allow through firewall
};
```

## Usage Examples

### Firefox

1. Open `about:preferences`
2. Search for "proxy"
3. Click "Settings"
4. Select "Manual proxy configuration"
5. SOCKS Host: `127.0.0.1`, Port: `1080`
6. Select "SOCKS v5"
7. Check "Proxy DNS when using SOCKS v5"

### Chrome/Chromium

Launch with SOCKS proxy:

```bash
chromium --proxy-server="socks5://127.0.0.1:1080"
```

### curl

```bash
curl --socks5 127.0.0.1:1080 https://ifconfig.me
```

### wget

```bash
wget -e use_proxy=yes -e socks_proxy=127.0.0.1:1080 https://example.com
```

### git

```bash
# Set globally
git config --global http.proxy socks5://127.0.0.1:1080

# Or per-command
git -c http.proxy=socks5://127.0.0.1:1080 clone https://github.com/user/repo.git

# Unset
git config --global --unset http.proxy
```

### ssh

Add to `~/.ssh/config`:

```
Host vpn-*
  ProxyCommand nc -X 5 -x 127.0.0.1:1080 %h %p
```

Then connect:

```bash
ssh vpn-example.com
```

### System-Wide Proxy (Environment Variables)

```bash
export SOCKS_PROXY=socks5://127.0.0.1:1080
export socks_proxy=socks5://127.0.0.1:1080
export ALL_PROXY=socks5://127.0.0.1:1080
```

## Verifying Traffic Routes Through vlan2

### Check Your Public IP

```bash
# Without proxy (should show main connection IP)
curl https://ifconfig.me

# With proxy (should show VPN IP)
curl --socks5 127.0.0.1:1080 https://ifconfig.me
```

### Monitor Interface Traffic

```bash
# Watch vlan2 traffic in real-time
sudo tcpdump -i vlan2 -n

# Or use iftop
sudo iftop -i vlan2
```

### Test Script

```bash
#!/usr/bin/env bash
echo "Testing proxy routing..."
echo ""
echo "Direct connection IP:"
curl -s https://ifconfig.me
echo ""
echo "Through vlan2 proxy IP:"
curl -s --socks5 127.0.0.1:1080 https://ifconfig.me
```

## Troubleshooting

### Check Dante Service Status

```bash
systemctl status dante.service
```

### View Logs

```bash
journalctl -u dante.service -f
```

### Test Connectivity

```bash
# Test if proxy is listening
nc -zv 127.0.0.1 1080

# Or with ss
ss -tlnp | grep 1080
```

### Verify vlan2 Interface

```bash
# Check interface status
ip addr show vlan2

# Check routing table
ip route show table 2
```

### Test vlan2 Connectivity

```bash
# Use existing test script
./scripts/test-vlan2-speed.sh
```

## Advanced: Per-Application Proxy with proxychains

Install proxychains:

```nix
environment.systemPackages = [ pkgs.proxychains ];
```

Configure `~/.proxychains/proxychains.conf`:

```
strict_chain
proxy_dns
tcp_read_time_out 15000
tcp_connect_time_out 8000

[ProxyList]
socks5 127.0.0.1 1080
```

Use:

```bash
proxychains firefox
proxychains transmission-gtk
proxychains curl https://example.com
```

## Integration with qBittorrent

Note: qBittorrent is already bound directly to vlan2, so it doesn't need the proxy. However, you could use the proxy for the WebUI access if needed.

## Alternative: HTTP Proxy with Privoxy

If you need an HTTP proxy instead of SOCKS, you can layer Privoxy on top:

```nix
services.privoxy = {
  enable = true;
  settings = {
    listen-address = "127.0.0.1:8118";
    forward-socks5 = "/ 127.0.0.1:1080 .";
  };
};
```

Then use HTTP proxy at `127.0.0.1:8118`.

## Security Considerations

### Authentication (Password)

By default, the proxy has **no password** because it's configured for localhost-only access (`127.0.0.1`). This is secure since only local services can connect.

**When you don't need authentication:**

- Localhost access only (`listenAddress = "127.0.0.1"`)
- Trusted local services (Prowlarr, Radarr, etc.)

**When you should enable authentication:**

- Network-wide access (`listenAddress = "0.0.0.0"`)
- Untrusted users/devices on your network

To enable authentication:

```nix
services.dante-proxy = {
  enable = true;
  enableAuthentication = true;
};

# Create proxy user
users.users.proxyuser = {
  isSystemUser = true;
  group = "proxyusers";
  password = "your-password";  # Or use hashedPassword
};
users.groups.proxyusers = {};
```

### General Security Guidelines

1. **Localhost only**: Set `listenAddress = "127.0.0.1"` for maximum security
2. **Network access**: Only enable if you need other devices to use the proxy
3. **Client restrictions**: Use `allowedClients` to limit who can connect
4. **Firewall**: Only set `openFirewall = true` if absolutely necessary
5. **Authentication**: Enable if exposing to network

## Performance

The Dante proxy adds minimal overhead. Your bottleneck will typically be:

1. VPN gateway throughput
2. Network latency through vlan2
3. ProtonVPN connection speed

Use `./scripts/test-vlan2-speed.sh` to benchmark your vlan2 connection.
