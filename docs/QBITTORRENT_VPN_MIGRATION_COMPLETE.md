# qBittorrent VPN Migration - Configuration Complete

## Summary

Successfully configured qBittorrent to run in a VPN namespace using VPN-Confinement module. This migrates WireGuard/ProtonVPN connection from the UDM to jupiter itself.

## Changes Made

### 1. Added VPN-Confinement Flake Input

- **File**: `flake.nix`
- Added `vpn-confinement` input from `github:Maroka-chan/VPN-Confinement`

### 2. Created VPN Namespace Module

- **File**: `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix`
- Configures VPN namespace for qBittorrent
- Handles WireGuard configuration from SOPS
- Sets up port mappings and firewall rules

### 3. Updated qBittorrent Module

- **File**: `modules/nixos/services/media-management/qbittorrent.nix`
- Removed VLAN2 bindings (192.168.2.0/24)
- Added VPN namespace support
- Updated interface bindings to work with VPN namespace
- Made WebUI accessible on main network

### 4. Updated Jupiter Configuration

- **File**: `hosts/jupiter/default.nix`
- Enabled VPN for qBittorrent
- Configured namespace name: `qbt`
- Set WebUI to be accessible from any interface

### 5. Deleted Non-Working Script

- **File**: `scripts/update-qbittorrent-protonvpn-port.sh` (deleted)
- Will handle NAT-PMP port forwarding separately

## Configuration Details

### VPN Namespace

- **Namespace Name**: `qbt` (max 7 chars due to Linux interface name limits)
- **Interface**: `qbt0`
- **VPN IP**: `10.2.0.2/32`
- **VPN Gateway**: `10.2.0.1`
- **Endpoint**: ProtonVPN WireGuard (138.199.7.129:51820)

### Network Access

- **WebUI**: Accessible at `http://192.168.1.210:8080` or `https://torrent.blmt.io`
- **Torrent Traffic**: Routed through VPN namespace
- **Main Network**: 192.168.1.0/24 (jupiter at 192.168.1.210)

### Port Configuration

- **WebUI Port**: 8080 (accessible on host network)
- **Torrent Port**: 62000 (initial, will be updated by NAT-PMP)

## Build & Deploy Instructions

### Step 1: Update Flake Lock

```bash
nix flake update vpn-confinement
```

This will fetch the VPN-Confinement module.

### Step 2: Build the Configuration

```bash
nh os switch
```

**Expected behavior:**

- Flake lock will update
- VPN-Confinement module will be fetched
- qBittorrent service will be reconfigured
- VPN namespace will be created
- WireGuard interface will be configured

**Note:** If you encounter any build errors related to VPN-Confinement, please share the error output.

### Step 3: Verify Services Started

```bash
# Check qBittorrent service
systemctl status qbittorrent

# Check VPN namespace service
systemctl status qbt

# List network namespaces
sudo ip netns list
# Should show: qbt
```

## Verification Checklist

### Phase 1: Namespace & Network

- [ ] VPN namespace exists

  ```bash
  sudo ip netns list | grep qbt
  ```

- [ ] WireGuard interface in namespace

  ```bash
  sudo ip netns exec qbt ip addr show
  # Should show wg0 interface with 10.2.0.2
  ```

- [ ] VPN connectivity

  ```bash
  sudo ip netns exec qbt ping -c 3 10.2.0.1
  # Should get responses from ProtonVPN gateway
  ```

- [ ] External IP through VPN

  ```bash
  sudo ip netns exec qbt curl -s https://ipv4.icanhazip.com
  # Should show ProtonVPN IP (NOT your real IP)
  ```

### Phase 2: qBittorrent Service

- [ ] Service running

  ```bash
  systemctl status qbittorrent
  # Should be active (running)
  ```

- [ ] Service logs look good

  ```bash
  journalctl -u qbittorrent -n 50
  # Check for any errors
  ```

- [ ] WebUI accessible

  ```bash
  curl -I http://192.168.1.210:8080
  # Should return HTTP 200
  ```

- [ ] Login to WebUI
  - Navigate to `http://192.168.1.210:8080`
  - Or use Caddy: `https://torrent.blmt.io`
  - Login with: username `lewis`, password from config

### Phase 3: Network Binding

- [ ] Interface binding correct

  ```bash
  sudo cat /var/lib/qbittorrent/qBittorrent/config/qBittorrent.conf | grep InterfaceName
  # Should show: Session\InterfaceName=qbt0
  ```

- [ ] Connection status in WebUI
  - Open WebUI ? Tools ? Options ? Connection
  - Should show "Connected" status
  - Network interface should be `qbt0`

### Phase 4: Torrent Functionality

- [ ] Add a test torrent
  - Use a legal torrent (Ubuntu ISO, etc.)
  - Should appear in torrent list

- [ ] Test download
  - Torrent should start downloading
  - Check download speed

- [ ] Verify traffic through VPN
  - In torrent tracker status, check reported IP
  - Should show ProtonVPN IP, not your real IP

## NAT-PMP Port Forwarding (To Be Configured)

ProtonVPN uses NAT-PMP for port forwarding. The port is dynamically assigned and needs to be:

1. Queried from the VPN gateway (10.2.0.1)
2. Updated in qBittorrent configuration
3. Renewed periodically (lease expires)

**Next steps:**

- We'll work together to set up NAT-PMP automation
- Will create a systemd service/timer for automatic port updates
- Port forwarding is not critical for downloading, but needed for optimal seeding

## UDM Cleanup (After Successful Migration)

Once everything is working on jupiter:

1. **Stop WireGuard on UDM**
   - Disable in UniFi Network UI
   - Or stop the service if configured manually

2. **Remove VLAN 2** (optional)
   - Remove the 192.168.2.0/24 network from UDM
   - Remove routing rules

3. **Update Caddy** (if needed)
   - Ensure `torrent.blmt.io` points to `192.168.1.210:8080`

## Troubleshooting

### Issue: VPN namespace not created

**Check:**

```bash
systemctl status vpn-qbt
journalctl -u vpn-qbt -n 50
```

**Common causes:**

- SOPS secret not properly decrypted
- VPN-Confinement module not loaded
- WireGuard kernel module not loaded

### Issue: qBittorrent can't access internet

**Check:**

```bash
sudo ip netns exec qbt curl -v https://www.google.com
```

**Common causes:**

- WireGuard not connected
- DNS not working in namespace
- Routing not configured

### Issue: WebUI not accessible

**Check:**

```bash
ss -tlnp | grep 8080
```

**Common causes:**

- qBittorrent not binding to correct interface
- Firewall blocking port 8080
- Service not running

### Issue: Torrents not downloading

**Check WebUI logs and verify:**

- Interface binding is correct
- Port is configured
- Trackers are being contacted

## Known Limitations

1. **Port Forwarding**: Currently using static port 62000. NAT-PMP automation will be added later.
2. **Kill Switch**: If VPN drops, qBittorrent should stop (enforced by VPN namespace), but verify this behavior.

## Files Modified

- `flake.nix` - Added vpn-confinement input
- `modules/nixos/services/media-management/default.nix` - Added VPN module import
- `modules/nixos/services/media-management/qbittorrent.nix` - Updated for VPN support
- `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix` - New VPN module
- `hosts/jupiter/default.nix` - Enabled VPN configuration

## Files Deleted

- `scripts/update-qbittorrent-protonvpn-port.sh` - Non-working script removed

## Next Steps

1. **Build and deploy** the configuration
2. **Verify** all checklist items above
3. **Test** downloading a torrent
4. **Set up NAT-PMP automation** (together)
5. **Clean up UDM** once verified working
