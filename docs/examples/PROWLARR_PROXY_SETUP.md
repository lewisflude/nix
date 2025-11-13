# Configuring Prowlarr to Use SOCKS Proxy

This guide shows how to configure Prowlarr to route its traffic through the Dante SOCKS proxy (and thus through vlan2/VPN).

## Configuration Steps

### 1. Access Prowlarr Settings

1. Open Prowlarr web interface (<https://prowlarr.blmt.io> or localhost:9696)
2. Go to **Settings** ? **General**
3. Show **Advanced Settings** (toggle at the top)

### 2. Configure Proxy Settings

Scroll down to the **Proxy** section and configure:

- **Type**: `SOCKS5` (or `SOCKS4` if you have compatibility issues)
- **Hostname**: `127.0.0.1`
- **Port**: `1080`
- **Username**: *(leave empty - no authentication by default)*
- **Password**: *(leave empty - no authentication by default)*
- **Bypass Proxy for Local Addresses**: `Yes` (recommended)

### 3. Save and Test

1. Click **Save Changes**
2. Go to **System** ? **Status**
3. Look for any proxy-related errors

### 4. Test with an Indexer

1. Add or edit an indexer
2. Click **Test** to verify connectivity through the proxy
3. If successful, the indexer should connect through vlan2

## Verifying It's Working

### Check Prowlarr Logs

```bash
journalctl -u prowlarr.service -f
```

Look for successful connections or any proxy-related errors.

### Monitor vlan2 Traffic

While testing an indexer in Prowlarr:

```bash
sudo tcpdump -i vlan2 -n port 443
```

You should see HTTPS traffic going through vlan2.

### Check IP Address

Some indexers show your IP address. With the proxy enabled, it should show your VPN IP instead of your main connection IP.

## Alternative: Network-Wide Proxy Access

If Prowlarr is running in a container or on a different machine, you need to make the proxy accessible:

```nix
services.dante-proxy = {
  enable = true;
  listenAddress = "0.0.0.0";  # Listen on all interfaces
  openFirewall = true;         # Open firewall port
};
```

Then in Prowlarr, use your server's IP instead of `127.0.0.1`:

- **Hostname**: `192.168.1.x` (your server's IP on main network)
- **Port**: `1080`

## With Authentication (Optional)

If you enable authentication for better security:

### 1. Update Configuration

```nix
services.dante-proxy = {
  enable = true;
  enableAuthentication = true;
};

# Create a user for the proxy
users.users.proxyuser = {
  isSystemUser = true;
  group = "proxyusers";
  password = "your-password-here"; # Or use hashedPassword
};

users.groups.proxyusers = {};
```

### 2. Configure Prowlarr with Credentials

- **Username**: `proxyuser`
- **Password**: `your-password-here`

## Troubleshooting

### Proxy Connection Failed

```bash
# Check if Dante is running
systemctl status dante.service

# Check if port is listening
ss -tlnp | grep 1080

# Test proxy manually
curl --socks5 127.0.0.1:1080 https://ifconfig.me
```

### Prowlarr Can't Reach Indexers

1. Verify vlan2 has internet connectivity:

   ```bash
   ./scripts/test-vlan2-speed.sh
   ```

2. Check DNS resolution through vlan2:

   ```bash
   curl --socks5 127.0.0.1:1080 https://1.1.1.1
   ```

3. Check Prowlarr logs for specific errors:

   ```bash
   journalctl -u prowlarr.service -n 100
   ```

### Indexers Timing Out

The proxy adds a small latency. If indexers time out:

1. In Prowlarr ? Settings ? General
2. Increase **Indexer Timeout** (default is usually 60 seconds)

## Why Use Proxy for Prowlarr?

1. **Privacy**: Hides your real IP from indexer sites
2. **Avoid Blocks**: Some indexers block certain ISPs or regions
3. **VPN Routing**: Routes through ProtonVPN (vlan2) for anonymity
4. **Selective Routing**: Only Prowlarr goes through VPN, not all traffic

## Performance Impact

The SOCKS proxy adds minimal overhead:

- **Latency**: ~1-5ms additional
- **Throughput**: Limited by VPN speed, not proxy
- **CPU**: Negligible

Use `./scripts/test-vlan2-speed.sh` to check your VPN performance.

## Other *arr Apps

You can configure other services similarly:

- **Radarr**: Settings ? General ? Proxy
- **Sonarr**: Settings ? General ? Proxy
- **Lidarr**: Settings ? General ? Proxy
- **Readarr**: Settings ? General ? Proxy

All use the same format:

- Type: `SOCKS5`
- Hostname: `127.0.0.1`
- Port: `1080`
