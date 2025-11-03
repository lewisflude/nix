# qBittorrent localhost:8080 Access Debugging Plan

**Issue:** Cannot access qBittorrent WebUI at localhost:8080 with VPN-Confinement enabled

## Configuration Summary

- **WebUI Port:** 8080 (default)
- **VPN Namespace:** `qbittor` (VPN-Confinement)
- **Service:** Standard NixOS `services.qbittorrent` module
- **VPN-Confinement:** Enabled with port mapping from 8080→8080
- **WebUI Address:** `*` (bind to all interfaces)

## Debugging Plan

### Phase 1: Service Status Verification

**Objective:** Verify qBittorrent service is running and healthy

1. **Check service status:**

   ```bash
   sudo systemctl status qbittorrent
   ```

   - [ ] Service is `active (running)`
   - [ ] No errors in status output
   - [ ] Check exit code: `echo $?` (should be 0)

2. **Check service logs:**

   ```bash
   sudo journalctl -u qbittorrent -n 50 --no-pager
   ```

   - [ ] Look for WebUI startup messages
   - [ ] Check for binding errors
   - [ ] Verify port 8080 is mentioned
   - [ ] Check for VPN namespace errors

3. **Verify process is running:**

   ```bash
   ps aux | grep qbittorrent
   ```

   - [ ] Process exists
   - [ ] Running as correct user (`qbittorrent`)
   - [ ] Command includes `--webui-port=8080`

### Phase 2: VPN-Confinement Namespace Verification

**Objective:** Verify VPN-Confinement namespace is set up correctly

4. **Check VPN namespace service:**

   ```bash
   sudo systemctl status qbittor.service
   ```

   - [ ] Service is `active (exited)` or `active (running)`
   - [ ] No errors in status

5. **Check namespace exists:**

   ```bash
   sudo ip netns list | grep qbittor
   ```

   - [ ] Namespace `qbittor` exists

6. **Check veth interfaces:**

   ```bash
   ip link show | grep -E "veth|qbittor"
   ```

   - [ ] veth interfaces exist (typically `veth-qbittor-host` and `veth-qbittor-vpn`)
   - [ ] Interfaces are UP

7. **Check namespace network configuration:**

   ```bash
   sudo ip netns exec qbittor ip addr show
   sudo ip netns exec qbittor ip route show
   ```

   - [ ] VPN interface (wg-mullvad) exists in namespace
   - [ ] veth interface has correct IP (10.200.200.2/24)
   - [ ] Default route goes through VPN interface

8. **Check VPN-Confinement logs:**

   ```bash
   sudo journalctl -u qbittor.service -n 50 --no-pager
   ```

   - [ ] No namespace creation errors
   - [ ] Port mappings configured correctly
   - [ ] WireGuard interface moved successfully

### Phase 3: Port Listening Verification

**Objective:** Verify qBittorrent is listening on the correct port

9. **Check if port is listening in namespace:**

   ```bash
   sudo ip netns exec qbittor ss -tlnp | grep 8080
   ```

   - [ ] Port 8080 is LISTEN
   - [ ] Process is qbittorrent
   - [ ] Address is `*:8080` or `0.0.0.0:8080`

10. **Check if port is listening on host:**

    ```bash
    ss -tlnp | grep 8080
    ```

    - [ ] **Expected:** Port 8080 might NOT be listening on host (VPN-Confinement handles forwarding)
    - [ ] Check veth interface: `ss -tlnp | grep veth`

11. **Check VPN-Confinement port forwarding:**

    ```bash
    sudo iptables -t nat -L -n -v | grep 8080
    sudo iptables -L -n -v | grep 8080
    ```

    - [ ] NAT rules exist for port 8080
    - [ ] Forwarding rules exist

### Phase 4: Network Connectivity Testing

**Objective:** Test connectivity from various perspectives

12. **Test from host namespace:**

    ```bash
    curl -v http://localhost:8080
    curl -v http://127.0.0.1:8080
    ```

    - [ ] Connection succeeds or specific error returned
    - [ ] Check error message if connection fails

13. **Test from VPN namespace:**

    ```bash
    sudo ip netns exec qbittor curl -v http://127.0.0.1:8080
    sudo ip netns exec qbittor curl -v http://localhost:8080
    ```

    - [ ] Connection succeeds from within namespace
    - [ ] This confirms qBittorrent is working in namespace

14. **Test via veth interface:**

    ```bash
    # Find veth host IP
    ip addr show | grep -A 2 veth.*qbittor.*host
    # Should be 10.200.200.1/24
    curl -v http://10.200.200.1:8080
    ```

    - [ ] Test if accessible via veth interface

15. **Check firewall rules:**

    ```bash
    sudo iptables -L INPUT -n -v | grep 8080
    sudo nft list ruleset | grep 8080
    ```

    - [ ] Firewall allows port 8080 (if using iptables/nftables)
    - [ ] Note: VPN-Confinement may handle this differently

### Phase 5: Configuration Verification

**Objective:** Verify configuration files are correct

16. **Check qBittorrent config file:**

    ```bash
    sudo cat /var/lib/qBittorrent/config/qBittorrent.conf | grep -A 5 WebUI
    ```

    - [ ] `WebUI\Enabled=true` is present
    - [ ] `WebUI\Port=8080` is correct
    - [ ] `WebUI\Address=*` or `WebUI\Address=0.0.0.0` is set

17. **Check VPN-Confinement config:**

    ```bash
    sudo nix-instantiate --eval -E 'with import <nixpkgs/nixos> {}; (import ./flake.nix).nixosConfigurations.jupiter.config.vpnNamespaces.qbittor.portMappings' --show-trace
    ```

    - [ ] Port mapping exists: `from = 8080, to = 8080`
    - [ ] `accessibleFrom` includes `127.0.0.1/32`

18. **Verify service configuration:**

    ```bash
    sudo systemctl cat qbittorrent | grep -A 10 vpnConfinement
    ```

    - [ ] `vpnConfinement.enable = true`
    - [ ] `vpnConfinement.namespace = "qbittor"`

### Phase 6: Common Issues Checklist

**Common VPN-Confinement Issues:**

- [ ] **Namespace not starting:** Check `qbittor.service` status
- [ ] **Port mapping not configured:** Verify `portMappings` in VPN-Confinement config
- [ ] **AccessibleFrom too restrictive:** Ensure `127.0.0.1/32` is in `accessibleFrom`
- [ ] **veth interface not configured:** Check veth interfaces exist and are UP
- [ ] **NAT rules missing:** VPN-Confinement should create iptables rules automatically
- [ ] **WebUI not binding:** Check qBittorrent config has `WebUI\Enabled=true` and `WebUI\Address=*`
- [ ] **Firewall blocking:** VPN-Confinement handles firewall, but verify it's not blocking

**Common qBittorrent Issues:**

- [ ] **WebUI disabled:** Check config file for `WebUI\Enabled=true`
- [ ] **Wrong port:** Verify config has `WebUI\Port=8080`
- [ ] **Binding to wrong interface:** Should be `*` or `0.0.0.0` for VPN-Confinement
- [ ] **Service dependency:** Check `qbittor.service` starts before `qbittorrent.service`

### Phase 7: Advanced Debugging

19. **Check VPN-Confinement source code/implementation:**
    - Review how VPN-Confinement sets up port forwarding
    - Verify NAT rules are created correctly
    - Check if there are known issues with localhost forwarding

20. **Test with tcpdump:**

    ```bash
    # On host
    sudo tcpdump -i lo -n port 8080
    # In another terminal, try curl http://localhost:8080
    ```

    - [ ] See packets on loopback interface
    - [ ] Check if packets are reaching qBittorrent

21. **Check systemd network namespace:**

    ```bash
    sudo systemctl show qbittorrent | grep NetworkNamespacePath
    ```

    - [ ] Verify namespace path is set correctly

22. **Test with strace:**

    ```bash
    sudo strace -p $(pgrep qbittorrent) -e trace=bind,listen,accept
    ```

    - [ ] See if qBittorrent is attempting to bind to port 8080
    - [ ] Check for bind errors

## Expected Root Causes (Prioritized)

1. **VPN-Confinement port mapping not working for localhost**
   - Port forwarding may only work for external IPs, not localhost
   - Solution: Access via veth interface IP or configure VPN-Confinement differently

2. **WebUI not binding correctly in namespace**
   - qBittorrent may not be listening in the namespace
   - Solution: Verify WebUI config and namespace setup

3. **Service dependency issue**
   - qBittorrent may start before VPN namespace is ready
   - Solution: Check `after` and `requires` dependencies

4. **Firewall blocking localhost connections**
   - VPN-Confinement may not allow localhost access by default
   - Solution: Verify `accessibleFrom` includes `127.0.0.1/32`

5. **Port mapping configuration error**
   - Port mapping may be misconfigured
   - Solution: Verify `portMappings` configuration

## Root Cause Identified ✅

**Date:** 2025-11-03
**Status:** RESOLVED - Use bridge gateway IP instead of localhost

### Findings

1. ✅ **qBittorrent is working correctly inside the namespace**
   - Listening on port 8080 inside `qbittor` namespace
   - Responds with HTTP 200 when accessed from within namespace
   - WebUI is functional

2. ✅ **VPN-Confinement NAT rule is correct**
   - Current rule: `DNAT tcp dpt:8080 to:192.168.15.1:8080`
   - `192.168.15.1` is the bridge gateway IP, which correctly forwards to qBittorrent
   - VPN-Confinement uses bridge `qbittor-br` with IP `192.168.15.5/24`

3. ✅ **Solution: Access via bridge gateway IP**
   - **Working:** `http://192.168.15.1:8080/` ✅
   - **Not working:** `http://localhost:8080` ❌ (bypasses bridge NAT rules)

### Why Localhost Doesn't Work

**Technical explanation:**

- **Localhost routing:** `localhost:8080` routes through loopback interface (`lo`), bypassing the bridge
- **NAT rules location:** VPN-Confinement's iptables rules apply to bridge interface traffic, not loopback
- **Bridge gateway:** `192.168.15.1:8080` routes through bridge interface where NAT rules apply correctly

### Solution ✅

**Access qBittorrent at:** `http://192.168.15.1:8080/`

This is the intended way to access services in VPN-Confinement namespaces. The bridge gateway IP is specifically designed for this purpose.

## Next Steps After Diagnosis

Once root cause is identified:

1. **Document the issue** in this file ✅
2. **Fix the configuration** in appropriate `.nix` file
3. **Test the fix** with commands from Phase 1-4
4. **Update documentation** if needed

## Quick Diagnostic Commands

Run these in order for a quick check:

```bash
# 1. Service status
sudo systemctl status qbittorrent qbittor.service

# 2. Port listening in namespace
sudo ip netns exec qbittor ss -tlnp | grep 8080

# 3. Test connectivity from namespace
sudo ip netns exec qbittor curl -v http://127.0.0.1:8080

# 4. Test connectivity from host
curl -v http://localhost:8080

# 5. Check VPN-Confinement NAT rules
sudo iptables -t nat -L -n -v | grep 8080

# 6. Check qBittorrent config
sudo cat /var/lib/qBittorrent/config/qBittorrent.conf | grep WebUI
```
