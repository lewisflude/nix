# ProtonVPN IPv6 and Port Forwarding Limitations

## Overview

ProtonVPN with WireGuard supports **IPv6 connectivity**, but their **NAT-PMP port forwarding is IPv4-only**. This creates a connectivity issue for torrent clients if not properly configured.

## The Problem

When using ProtonVPN with port forwarding for torrenting:

1. ✅ **IPv6 connectivity works** - ProtonVPN assigns IPv6 addresses (`2001:ac8:31:366::18`)
2. ✅ **NAT-PMP port forwarding works** - But **only for IPv4** traffic
3. ❌ **IPv6 port forwarding does NOT work** - No incoming IPv6 connections possible

### What This Means for Torrenting

If your torrent client announces both IPv4 and IPv6 addresses to trackers:

- **IPv4 peers**: ✅ Can connect to your forwarded port (works perfectly)
- **IPv6 peers**: ❌ Cannot connect (port not forwarded, connections fail)

This results in:

- Reduced peer connectivity
- Lower download/upload speeds
- Potentially poor seeding ratios

## The Solution

**Disable IPv6 for torrent clients** to ensure all peer connections use IPv4 (which has working port forwarding).

### Configuration Changes Applied

#### Transmission (`modules/nixos/services/media-management/transmission.nix`)

```nix
settings = {
  # ... other settings ...

  # Network configuration
  # IMPORTANT: Disable IPv6 because ProtonVPN's NAT-PMP port forwarding is IPv4-only
  # IPv6 peers would not be able to connect (port not forwarded)
  bind-address-ipv4 = "0.0.0.0";
  bind-address-ipv6 = "";  # Empty string disables IPv6
};
```

#### qBittorrent (`modules/nixos/services/media-management/qbittorrent.nix`)

```nix
Session = {
  # ... other settings ...

  # VPN Interface binding
  Interface = "qbt0";
  InterfaceName = "qbt0";
  InterfaceAddress = "10.2.0.2";  # IPv4 only
  # IMPORTANT: Disable IPv6 because ProtonVPN's NAT-PMP port forwarding is IPv4-only
  DisableIPv6 = true;
};
```

## Technical Details

### ProtonVPN IPv6 Support

ProtonVPN **does** provide IPv6 addresses with WireGuard:

- Interface gets IPv6 address (e.g., `2a07:b944::2:2/128`)
- WireGuard peer allows both IPv4 and IPv6: `allowed ips: 0.0.0.0/0, ::/0`
- IPv6 connectivity works for outbound connections
- IPv6 routing is functional

### NAT-PMP Protocol Limitation

NAT-PMP (Network Address Translation Port Mapping Protocol) was designed for IPv4 NAT traversal:

- Protocol spec: RFC 6886 (focuses on IPv4)
- Originally designed to solve IPv4 NAT issues
- No standardized IPv6 extension (IPv6 typically doesn't need NAT)

### Why VPN Providers Use NAT for IPv6

Even though IPv6 addresses are globally routable and don't need NAT:

- VPN providers often use NAT66 for privacy (hide client from server)
- ProtonVPN uses NAT for both IPv4 and IPv6
- But port forwarding automation (NAT-PMP) only works for IPv4

## Verification

### Before Fix

```bash
# Transmission was listening on IPv6
$ sudo ip netns exec qbt ss -tlnp | grep transmission
LISTEN 0      4096            [::]:64243         [::]:*    users:(("transmission-da",pid=944803,fd=11))

# IPv6 firewall rules exist but port forwarding doesn't work
$ sudo ip netns exec qbt ip6tables -L -n | grep 64243
ACCEPT     tcp  --  qbt0   *       ::/0                 ::/0                 tcp dpt:64243
```

### After Fix

After rebuilding with the new configuration:

```bash
# Transmission should only listen on IPv4
$ sudo ip netns exec qbt ss -tlnp | grep transmission
LISTEN 0      128          0.0.0.0:9091       0.0.0.0:*    users:(("transmission-da",pid=XXX,fd=16))
# No IPv6 listener on port 64243

# qBittorrent continues to work on IPv4
$ sudo ip netns exec qbt ss -tlnp | grep qbittorrent
LISTEN 0      30     10.2.0.2%qbt0:64243      0.0.0.0:*    users:((".qbittorrent-no",pid=XXX,fd=9))
```

## Rebuild Instructions

After applying these configuration changes:

```bash
# Review the changes
git diff

# Build and apply (choose your preferred method)
nh os switch
# or
sudo nixos-rebuild switch --flake .#jupiter

# Verify services restarted
sudo systemctl status qbittorrent.service
sudo systemctl status transmission.service

# Test port forwarding
./scripts/check-torrent-port.sh
```

## Expected Results

After rebuilding:

- ✅ Both torrent clients only use IPv4
- ✅ Port forwarding works correctly for all peers
- ✅ No failed IPv6 connection attempts
- ✅ Better peer connectivity and speeds

## Alternative: Disable IPv6 Globally in VPN Namespace

If you want to completely disable IPv6 in the VPN namespace (more aggressive approach):

```nix
# In qbittorrent-vpn-confinement.nix
boot.kernel.sysctl = {
  # Disable IPv6 in VPN namespace
  "net.ipv6.conf.qbt0.disable_ipv6" = 1;
};
```

**Note:** The per-application approach (current implementation) is preferred because:

- Allows IPv6 for non-torrent traffic in the namespace if needed
- More granular control
- Easier to debug and understand

## References

- [ProtonVPN Port Forwarding Setup](./PROTONVPN_PORT_FORWARDING_SETUP.md)
- [qBittorrent VPN Guide](./QBITTORRENT_GUIDE.md)
- RFC 6886: NAT-PMP Protocol Specification
- ProtonVPN Support: Port Forwarding with NAT-PMP

## Troubleshooting

### Check if IPv6 is properly disabled

```bash
# Check listening sockets (should be IPv4 only for torrent ports)
sudo ip netns exec qbt ss -tlnp

# Check for IPv6 connections on torrent port (should be empty)
sudo ip netns exec qbt ss -tunp | grep '\[2001:'

# Verify IPv6 is disabled in qBittorrent
curl -s http://127.0.0.1:8080/api/v2/app/preferences | jq '.listen_on_ipv6_address'
```

### If IPv6 peers still try to connect

This is normal and expected:

- Trackers may still announce your IPv6 address
- Peers will try IPv6 first, then fall back to IPv4
- No impact on performance (IPv4 will work)

To completely prevent IPv6 announcements:

- The clients will only bind to IPv4 addresses
- Trackers will only see IPv4 connections
- No IPv6 address will be announced to peers

## Conclusion

By disabling IPv6 for torrent clients while using ProtonVPN, you ensure:

- All peer connections use IPv4 with working port forwarding
- Maximum connectivity and performance
- No failed connection attempts from IPv6 peers
- Optimal seeding ratios

The configuration maintains IPv6 connectivity for other purposes while ensuring torrent traffic uses the properly-forwarded IPv4 port.
