# Fix: Routing Conflict Issue

## Problem Identified

The routing table has a conflict:

- Default route: `default dev qbt0` ✅ (correct)
- BUT: `10.0.0.0/8 via 192.168.15.5 dev veth-qbt` ❌ (conflicts!)

The VPN DNS (10.2.0.1) is in the 10.0.0.0/8 range, so it's being routed via `veth-qbt` instead of `qbt0`. This breaks VPN connectivity.

## Solution

The route `10.0.0.0/8 via veth-qbt` is too broad and conflicts with VPN traffic. We need to exclude VPN addresses from this route.

### Option 1: More Specific Routes (Recommended)

Replace the broad `10.0.0.0/8` route with more specific routes that exclude VPN ranges:

```bash
# Remove the conflicting route
sudo ip netns exec qbt ip route del 10.0.0.0/8 via 192.168.15.5 dev veth-qbt

# Add specific routes for local networks only (excluding VPN range)
sudo ip netns exec qbt ip route add 10.0.0.0/9 via 192.168.15.5 dev veth-qbt
sudo ip netns exec qbt ip route add 10.128.0.0/9 via 192.168.15.5 dev veth-qbt
# But exclude VPN range (10.2.0.0/16)
sudo ip netns exec qbt ip route add 10.0.0.0/9 via 192.168.15.5 dev veth-qbt
sudo ip netns exec qbt ip route add 10.1.0.0/16 via 192.168.15.5 dev veth-qbt
sudo ip netns exec qbt ip route add 10.3.0.0/16 via 192.168.15.5 dev veth-qbt
# ... etc (complex, not ideal)
```

### Option 2: Exclude VPN Range (Better)

Add a more specific route for VPN range that takes precedence:

```bash
# Add VPN range route via WireGuard (more specific, takes precedence)
sudo ip netns exec qbt ip route add 10.2.0.0/16 dev qbt0

# Now 10.2.0.1 will use qbt0, other 10.x.x.x will use veth-qbt
```

### Option 3: Remove Conflicting Route Entirely (Simplest)

If you don't need access to other 10.x.x.x networks via veth, just remove the route:

```bash
sudo ip netns exec qbt ip route del 10.0.0.0/8 via 192.168.15.5 dev veth-qbt
```

Then VPN traffic will use the default route via qbt0.

## Quick Test

Try Option 3 first (simplest):

```bash
# Remove conflicting route
sudo ip netns exec qbt ip route del 10.0.0.0/8 via 192.168.15.5 dev veth-qbt

# Test connectivity
sudo ip netns exec qbt ping -c 2 10.2.0.1
sudo ip netns exec qbt ping -c 2 8.8.8.8
sudo ip netns exec qbt curl http://example.com
```

If this works, we need to fix the VPN-Confinement script to not add this conflicting route.

## Permanent Fix

The route is added by the VPN-Confinement script (`qbt-up`). We need to modify it to exclude VPN ranges or make it more specific.

**Temporary fix** (apply after each restart):

```bash
sudo systemctl edit qbt.service
```

Add:

```ini
[Service]
ExecStartPost=/usr/bin/ip netns exec qbt ip route del 10.0.0.0/8 via 192.168.15.5 dev veth-qbt
```

**Or modify the script** (requires rebuild):
The script at `/nix/store/ray4zihiiy9q77ryd9kmfb9pbzm6jxf8-qbt-up/bin/qbt-up` needs to be fixed to exclude VPN ranges from the 10.0.0.0/8 route.

## Verify Fix

After applying the fix:

```bash
# Check routing
sudo ip netns exec qbt ip route show

# Should show VPN traffic going via qbt0
sudo ip netns exec qbt ip route get 10.2.0.1
sudo ip netns exec qbt ip route get 8.8.8.8

# Test connectivity
sudo ip netns exec qbt ping -c 2 10.2.0.1
sudo ip netns exec qbt curl https://torrent.blmt.io
```
