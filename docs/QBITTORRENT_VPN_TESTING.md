# Testing qBittorrent VPN Configuration

## Quick Test Steps

After rebuilding your NixOS configuration, test the VPN setup:

### 1. Test WireGuard Config Generation

```bash
# Start the config generation service
sudo systemctl start generate-qbt-wg-config.service

# Check if it succeeded
sudo systemctl status generate-qbt-wg-config.service

# Verify config file exists
ls -la /run/qbittorrent-wg.conf
cat /run/qbittorrent-wg.conf
```

### 2. Test VPN Namespace Service

```bash
# Start the VPN namespace
sudo systemctl start qbt.service

# Check status
sudo systemctl status qbt.service

# Verify namespace exists
ip netns list | grep qbt

# Check WireGuard interface in namespace
sudo ip netns exec qbt ip link show wg0
sudo ip netns exec qbt ip addr show wg0
```

### 3. Test qBittorrent

```bash
# Start qBittorrent
sudo systemctl start qbittorrent.service

# Check status
sudo systemctl status qbittorrent.service

# Access WebUI
# http://localhost:8080
```

### 4. Test Proxy (if enabled)

```bash
# Start 3proxy
sudo systemctl start 3proxy-qbvpn.service

# Check status
sudo systemctl status 3proxy-qbvpn.service

# Test HTTP proxy
curl --proxy http://127.0.0.1:8118 https://api.ipify.org

# Test SOCKS proxy
curl --socks5 127.0.0.1:1080 https://api.ipify.org
```

### 5. Verify VPN Routing

```bash
# Check IP through VPN
sudo ip netns exec qbt curl https://api.ipify.org

# Should show your VPN IP, not your real IP
```

## Automated Test Script

Run the comprehensive test script:

```bash
./scripts/test-qbt-vpn.sh
```

## Troubleshooting

### Config file not generated

- Check: `sudo journalctl -u generate-qbt-wg-config.service -n 50`
- Verify secret file exists: `ls -la /run/secrets/qbittorrent/vpn/privateKey`

### VPN namespace fails

- Check: `sudo journalctl -u qbt.service -n 50`
- Verify config file: `cat /run/qbittorrent-wg.conf`

### Services won't start

- Check dependencies: `systemctl list-dependencies qbt.service`
- Reload systemd: `sudo systemctl daemon-reload`
