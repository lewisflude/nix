# qBittorrent VPN Architecture - Best Practices

## Current Architecture Issues

The current implementation has several problems:

1. **Manual Namespace Management**: Creating namespaces in WireGuard `preSetup` hooks is fragile and race-condition prone
2. **Moving Interfaces**: Moving WireGuard interface after creation interferes with WireGuard's own management
3. **Security Concerns**: Requires `CAP_SYS_ADMIN` to use `ip netns exec` wrapper script
4. **Not Using systemd Features**: Not leveraging systemd's native `NetworkNamespacePath` support
5. **Complex Shell Scripts**: Critical networking logic hidden in shell scripts rather than declarative Nix

## Recommended Architecture

### Option 1: Dedicated Namespace Service + NetworkNamespacePath (Recommended)

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

**Implementation:**

- Namespace service runs before qbittorrent
- WireGuard can create interface normally, namespace service moves it
- qbittorrent uses `NetworkNamespacePath` - no wrapper script needed
- Namespace persists via bind mount to `/var/run/netns`

### Option 2: Simpler Interface Binding (Less Isolation)

**Benefits:**

- ✅ Simplest to implement
- ✅ No namespace complexity
- ✅ Good enough for most use cases

**How it works:**

- Bind qbittorrent to WireGuard interface IP address
- Use firewall rules to prevent leaks
- Less isolation - if VPN drops, might leak (but firewall helps)

### Option 3: Policy-Based Routing (Most Complex)

**Benefits:**

- ✅ WireGuard stays in default namespace
- ✅ Full routing control

**How it works:**

- Use iptables/nftables to route traffic from namespace through WireGuard
- More complex routing setup
- Doesn't require moving interfaces

## Recommendation

**Use Option 1** - It's the most idiomatic NixOS approach:

- Declarative (all in Nix config)
- Uses systemd features properly
- Clean separation of concerns
- Better maintainability
- Follows NixOS patterns

## Migration Path

1. Create `qbittorrent-vpn-namespace.nix` module
2. Update qbittorrent service to use `NetworkNamespacePath` instead of wrapper
3. Simplify WireGuard module (remove namespace creation logic)
4. Update imports in `default.nix`

## Example: Clean Implementation

```nix
# qbittorrent service with NetworkNamespacePath
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

This is cleaner, simpler, and more maintainable than the current approach.
