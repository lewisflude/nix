# qBittorrent VPN Configuration Guide

This guide covers the complete qBittorrent VPN setup using VPN-Confinement for secure BitTorrent traffic routing through a ProtonVPN WireGuard tunnel.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Configuration](#configuration)
3. [Port Forwarding](#port-forwarding)
4. [Interface Binding](#interface-binding)
5. [Troubleshooting](#troubleshooting)
6. [Manual Setup](#manual-setup)

## Architecture Overview

### Current Implementation

The qBittorrent VPN setup uses **VPN-Confinement** to isolate qBittorrent in a network namespace with a dedicated WireGuard interface.

**Key Components:**

- VPN-Confinement namespace: `qbittor`
- WireGuard interface: `qbittor0` (created automatically by VPN-Confinement)
- Interface IP: `10.2.0.2/32`
- Gateway: `10.2.0.1` (ProtonVPN WireGuard gateway)
- BitTorrent port: `6881` (mapped via VPN-Confinement)

### Architecture Benefits

✅ **Complete Traffic Isolation:**

- All qBittorrent traffic routes through VPN
- No IP leaks possible - qBittorrent can only use VPN interface
- Network namespace prevents accidental leaks

✅ **Automatic Port Forwarding:**

- NAT-PMP support for ProtonVPN port forwarding
- Automatic port mapping renewal
- Better peer connectivity and download speeds

✅ **Secure Configuration:**

- WireGuard configuration stored in SOPS
- No manual network setup required
- Declarative NixOS configuration

### Recommended Architecture (Future Improvement)

The current implementation works well, but for future improvements, consider:

#### Option 1: Dedicated Namespace Service + NetworkNamespacePath (Recommended)

- Use systemd's native `NetworkNamespacePath` support
- No `CAP_SYS_ADMIN` needed for qbittorrent service
- Cleaner separation of concerns
- Better error handling and logging

See [Architecture Best Practices](#architecture-best-practices) section below.

## Configuration

### VPN-Confinement Setup

**File:** `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix`

The VPN-Confinement configuration:

- Creates network namespace `qbittor`
- Sets up WireGuard interface `qbittor0`
- Configures port mappings for BitTorrent (port 6881)
- Manages WireGuard connection lifecycle

### qBittorrent Configuration

**File:** `modules/nixos/services/media-management/qbittorrent-standard.nix`

Key settings when VPN is enabled:

```nix
BitTorrent = {
  Session = {
    # Bind to VPN interface
    InterfaceName = "qbittor0";
  };
};

Network = {
  # Enable NAT-PMP port forwarding
  PortForwardingEnabled = true;
};
```

### WireGuard Configuration

**Storage:** SOPS secrets (`vpn-confinement-qbittorrent`)

**Requirements:**

- Must be generated with **NAT-PMP (port forwarding) enabled**
- Must use a **P2P server** (double-arrow icon in ProtonVPN)
- Requires paid ProtonVPN plan for port forwarding

**How to generate:**

1. Sign in to [Proton VPN Account](https://account.protonvpn.com/account)
2. Go to **Account** → **Downloads** → **WireGuard configuration**
3. Select a **P2P server**
4. Enable **"NAT-PMP (port forwarding)"**
5. Download and store in SOPS

## Port Forwarding

### ProtonVPN Port Forwarding

Port forwarding enables incoming BitTorrent connections, improving download speeds and peer connectivity.

#### Automatic Port Forwarding Service

A systemd service (`protonvpn-port-forwarding`) automatically forwards ports:

**Service Details:**

- **Service name:** `protonvpn-port-forwarding.service`
- **Gateway IP:** `10.2.0.1` (ProtonVPN WireGuard default gateway)
- **BitTorrent port:** `6881` (configurable)
- **Protocol:** Both UDP and TCP
- **Renewal interval:** Every 45 seconds (60-second lifetime)

**How It Works:**

1. Service starts after VPN namespace is ready
2. `natpmpc` requests port forwarding from ProtonVPN gateway
3. ProtonVPN assigns a public port (e.g., 53186) and forwards to private port 6881
4. Port mapping is renewed every 45 seconds
5. qBittorrent listens on port 6881 (private port inside namespace)

**Port Configuration:**

- **qBittorrent listening port:** `6881` (private port inside VPN namespace)
- **ProtonVPN public port:** Randomly assigned (e.g., 53186), changes on reconnection
- **Port forwarding:** Public port → Private port 6881 (handled by ProtonVPN gateway)

#### Verification

**Check Service Status:**

```bash
sudo systemctl status protonvpn-port-forwarding.service
```

**Check Service Logs:**

```bash
sudo journalctl -u protonvpn-port-forwarding.service -f
```

Expected output:

```
Mapped public port 53186 to private port 6881 UDP, lifetime 60s
Mapped public port 53186 to private port 6881 TCP, lifetime 60s
```

**Verify in qBittorrent WebUI:**

1. Open: `http://192.168.15.1:8080/`
2. Go to **Options** → **Connection**
3. Check **"Port forwarding status"** - should show as active

### NAT-PMP Configuration

NAT-PMP (NAT Port Mapping Protocol) allows qBittorrent to automatically configure port forwarding.

**Enabled in configuration:**

```nix
Network = {
  PortForwardingEnabled = true;
};
```

**What This Does:**

- qBittorrent sends NAT-PMP requests to the gateway/router
- Requests forwarding for port 6881 (TCP and UDP)
- Gateway responds if NAT-PMP is supported
- Enables incoming connections and improves speeds

**Note:** Most VPN providers don't support NAT-PMP/UPnP, but ProtonVPN does when configured correctly.

## Interface Binding

### Automatic Interface Binding

qBittorrent is automatically configured to bind to the VPN interface when VPN is enabled:

```nix
BitTorrent = {
  Session = {
    InterfaceName = "qbittor0";  # VPN interface name
  };
};
```

**What This Does:**

1. Forces all qBittorrent traffic through VPN
2. Prevents socket binding conflicts
3. Ensures UDP tracker announces use correct interface
4. Matches WebUI setting: Options > Advanced > Network Interface

**Interface Details:**

- **VPN-Confinement namespace:** `qbittor`
- **WireGuard interface:** `qbittor0` (pattern: `<namespace-name>0`)
- **Interface IP:** `10.2.0.2/32`

### Verification

**Check configuration:**

```bash
sudo cat /var/lib/qBittorrent/config/qBittorrent.conf | grep -i interface
# Should show: Session\InterfaceName=qbittor0
```

**Check in WebUI:**

- Go to: Options > Advanced > Network Interface
- Should show: `qbittor0` selected

**Verify interface binding:**

```bash
sudo ip netns exec qbittor ss -tunp | grep qbittorrent
# All sockets should show qbittor0 interface
```

## Troubleshooting

### UDP Tracker Errors

**Problem:** UDP trackers report "Device or resource busy" errors

**Status:** Known qBittorrent issue with UDP tracker socket binding in network namespaces

**Symptoms:**

- UDP trackers show "Not working" with "Device or resource busy"
- TCP trackers work fine
- DHT, LSD, and PeX work correctly
- UDP connectivity from namespace works (`nc -vzu` succeeds)

**Root Cause:**
qBittorrent has a known issue binding UDP sockets for tracker announces in network namespaces. When qBittorrent tries to send UDP tracker announces, socket binding can conflict or hit resource limits.

**Workarounds:**

1. **Interface Binding:** Ensure qBittorrent is bound to VPN interface (already configured)
2. **Use TCP Trackers:** Remove UDP trackers from torrents (not recommended)
3. **Wait for Fix:** Monitor qBittorrent releases for namespace UDP fixes
4. **Alternative Client:** Consider using a different BitTorrent client if UDP trackers are critical

**Impact:**

- Downloads may still work via TCP trackers or DHT/PeX
- BitTorrents with multiple trackers may still work
- Peer connections work (can still download/upload)

### Port Forwarding Issues

**Service Fails to Start:**

- **Error:** "VPN namespace qbittor not found"
- **Solution:** Ensure VPN-Confinement namespace is configured and starts before this service

**Port Forwarding Fails:**

- **WireGuard config doesn't have NAT-PMP enabled:** Regenerate config with NAT-PMP enabled
- **Wrong gateway IP:** Verify gateway IP: `sudo ip netns exec qbittor ip route | grep default`
- **Not connected to P2P server:** Ensure WireGuard config is for a P2P server
- **Free ProtonVPN plan:** Port forwarding requires a paid plan

**qBittorrent Doesn't Use Forwarded Port:**

- Ensure `PortForwardingEnabled = true` in qBittorrent config
- qBittorrent's NAT-PMP should automatically detect the forwarded port
- If not working, manually configure the port in qBittorrent WebUI

### Gateway IP Issues

If your ProtonVPN gateway IP is not `10.2.0.1`:

1. Find the actual gateway:

   ```bash
   sudo ip netns exec qbittor ip route | grep default
   ```

2. Update `protonvpnGateway` in `qbittorrent-vpn-confinement.nix`

### NAT-PMP State File Permissions

**Issue:** Permission errors for `.natpmp-state` directory

**Solution:** Already fixed in configuration - qBittorrent user has correct permissions

## Manual Setup

### Quick Test: Manual Interface Binding

If you want to test interface binding immediately without rebuilding NixOS:

#### Method 1: Via WebUI (Easiest)

1. Open qBittorrent WebUI: `http://192.168.15.1:8080/`
2. Navigate to: Options > Advanced
3. Set **"Network Interface"** to `qbittor0`
4. Click **Apply** or **OK**
5. Restart qBittorrent: `sudo systemctl restart qbittorrent`

#### Method 2: Via Config File

1. Edit config: `sudo nano /var/lib/qBittorrent/config/qBittorrent.conf`
2. Find `[BitTorrent]` section and add:

   ```ini
   [BitTorrent]
   Session\InterfaceName=qbittor0
   ```

3. Save and restart: `sudo systemctl restart qbittorrent`

**Note:** Manual changes will be overwritten when you rebuild NixOS configuration.

## Architecture Best Practices

### Recommended Future Improvements

#### Option 1: Dedicated Namespace Service + NetworkNamespacePath (Recommended)

**Benefits:**

- ✅ systemd manages namespace lifecycle (proper dependencies)
- ✅ No `CAP_SYS_ADMIN` needed for qbittorrent service
- ✅ Cleaner separation of concerns
- ✅ Better error handling and logging
- ✅ Follows NixOS service patterns

**Structure:**

1. `qbittorrent-vpn-namespace.service` - Creates and manages namespace (oneshot, RemainAfterExit)
2. WireGuard interface created normally (can be moved to namespace by namespace service)
3. qbittorrent service uses `NetworkNamespacePath` pointing to `/var/run/netns/wg-qbittorrent`

**Example Implementation:**

```nix
systemd.services.qbittorrent = {
  after = [ "qbittorrent-vpn-namespace.service" ];
  requires = [ "qbittorrent-vpn-namespace.service" ];

  serviceConfig = {
    # Use systemd's native namespace support
    NetworkNamespacePath = lib.mkIf vpnEnabled "/var/run/netns/${namespace}";
    ExecStart = "${lib.getExe cfg.qbittorrent.package} --webui-port=${toString cfg.qbittorrent.webUI.port}";
    # No CAP_SYS_ADMIN needed!
    NoNewPrivileges = true;
  };
};
```

#### Option 2: Simpler Interface Binding (Less Isolation)

- Bind qbittorrent to WireGuard interface IP address
- Use firewall rules to prevent leaks
- Less isolation - if VPN drops, might leak (but firewall helps)

#### Option 3: Policy-Based Routing (Most Complex)

- Use iptables/nftables to route traffic from namespace through WireGuard
- WireGuard stays in default namespace
- Full routing control but more complex setup

## Related Files

- **VPN-Confinement config:** `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix`
- **qBittorrent config:** `modules/nixos/services/media-management/qbittorrent-standard.nix`
- **WireGuard config:** Stored in SOPS as `vpn-confinement-qbittorrent`

## Notes

- **Port assignment:** ProtonVPN assigns a random public port (e.g., 53186), which forwards to your private port (6881)
- **Port changes:** The public port may change when reconnecting to VPN - the service handles this automatically
- **qBittorrent listening port:** Keep qBittorrent configured to listen on port **6881** (the private port)
- **Security:** Port forwarding only works through ProtonVPN's secure gateway - your real IP is never exposed
- **Interface name:** Hardcoded as `qbittor0` based on VPN-Confinement's naming pattern (`<namespace-name>0`)

## References

- [ProtonVPN Port Forwarding Manual Setup](https://protonvpn.com/support/port-forwarding-manual-setup)
- [VPN-Confinement Documentation](https://github.com/placek/vpn-confinement)
