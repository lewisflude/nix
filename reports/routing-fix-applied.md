# Fix Applied: Routing Conflict Resolution

## Problem Found

**Location:** `modules/nixos/services/media-management/qbittorrent.nix` line 492

**Issue:** The default `accessibleFrom` includes `10.0.0.0/8`, which VPN-Confinement uses to create routes. This conflicts with VPN addresses (10.2.0.2/32) that should route through WireGuard instead of veth.

**Conflict:**

- VPN address: `10.2.0.2/32` (should route via `qbt0` WireGuard interface)
- Route created: `10.0.0.0/8 via 192.168.15.5 dev veth-qbt` (routes VPN DNS/addresses via veth)

## Fix Applied

Removed `10.0.0.0/8` from the default `accessibleFrom` list to prevent routing conflicts.

**Before:**

```nix
default = [
  "127.0.0.1/32"
  "192.168.0.0/16"
  "10.0.0.0/8"  // ❌ Conflicts with VPN addresses
];
```

**After:**

```nix
default = [
  "127.0.0.1/32"
  "192.168.0.0/16"
  // 10.0.0.0/8 removed - conflicts with VPN addresses
];
```

## Next Steps

1. **Rebuild NixOS configuration:**

   ```bash
   sudo nixos-rebuild switch
   ```

2. **Restart VPN namespace service:**

   ```bash
   sudo systemctl restart qbt.service
   ```

3. **Verify routing:**

   ```bash
   sudo ip netns exec qbt ip route show
   # Should NOT have: 10.0.0.0/8 via 192.168.15.5 dev veth-qbt
   ```

4. **Test connectivity:**

   ```bash
   sudo ip netns exec qbt ping -c 2 10.2.0.1
   sudo ip netns exec qbt ping -c 2 8.8.8.8
   sudo ip netns exec qbt curl https://torrent.blmt.io
   ```

## If You Need 10.x.x.x Access

If you need to access the namespace from 10.x.x.x networks, add specific subnets that exclude VPN ranges:

```nix
qbittorrent = {
  vpn = {
    accessibleFrom = [
      "127.0.0.1/32"
      "192.168.0.0/16"
      "10.0.0.0/9"      # 10.0.0.0 - 10.127.255.255
      "10.128.0.0/9"    # 10.128.0.0 - 10.255.255.255
      # Excludes: 10.2.0.0/16 (VPN range)
    ];
  };
};
```

## Additional Issue: HTTP Timeout

After removing the route, HTTP connects but times out. This might be:

1. **iptables FORWARD rules** - Check if packets are being forwarded
2. **Response routing** - Responses might not be routed back correctly
3. **MTU issues** - MTU might be too large for WireGuard

Check iptables FORWARD rules:

```bash
sudo ip netns exec qbt iptables -L FORWARD -n -v
```

If FORWARD is DROP, that's the issue - responses won't be forwarded back.
