# qBittorrent Module Analysis: Overengineering Assessment

## Executive Summary

The `qbittorrent.nix` module is **moderately overengineered** but serves a complex use case. While it works, there are opportunities to simplify and better leverage NixOS patterns.

## Current Complexity Issues

### 1. **WireGuard Config Generation (Lines 46-95)**

**Problem**: Manual shell script generation of WireGuard config files, even though VPN-Confinement likely handles this.

**Current approach**:

- Generates WireGuard config via shell script at runtime
- Uses `ExecStartPre` to generate config before VPN namespace starts
- Duplicates WireGuard configuration logic

**Better approach**:

- VPN-Confinement should accept WireGuard config directly via Nix configuration
- Or use `pkgs.writeText` to generate config at build time if secrets allow
- Check if VPN-Confinement supports structured WireGuard config via options

### 2. **Multiple Proxy Services (Lines 791-866)**

**Problem**: Three different proxy services (Privoxy, Dante, 3proxy) for essentially the same purpose.

**Current setup**:

- Privoxy (HTTP proxy on port 8118) - for other services
- Dante (SOCKS5 proxy on port 1080) - for Prowlarr
- 3proxy (HTTP + SOCKS5 on configurable ports) - for external systems

**Better approach**:

- **Consolidate to one proxy service** that supports both HTTP and SOCKS5
- Use **3proxy** as the single solution (it supports both protocols)
- OR use **socat** or **socksify** wrappers if simpler
- Consider if external access is really needed - if not, remove 3proxy entirely

### 3. **Complex Secret Handling (Lines 27-44)**

**Problem**: Deeply nested conditionals for secret resolution.

**Current approach**:

```nix
vpnPrivateKeyFile =
  if !qbtVpnEnabled then
    null
  else if vpnCfg.privateKeySecret != null then
    (
      if vpnSecretAttr != null then
        vpnSecretAttr.path
      else
        throw "..."
    )
  else
    vpnCfg.privateKeyFile;
```

**Better approach**:

- Extract to a helper function: `resolveSecretPath attrName secretName filePath`
- Use `lib.getAttrFromPath` or pattern matching
- Consider using `lib.mkMerge` with assertions

### 4. **Credential Update Script (Lines 104-194)**

**Problem**: Custom shell script to modify qBittorrent config file at runtime.

**Current approach**:

- 90+ lines of bash to parse and modify INI-style config
- Updates username/password from secrets

**Better approaches**:

- **Option A**: Use `services.qbittorrent.serverConfig` directly (already partially done)
- **Option B**: If username must come from secret, use `systemd.serviceConfig.Environment` + wrapper script
- **Option C**: Use `pkgs.writeText` to generate config template, then use `sed`/`awk` for secret substitution
- **Option D**: Contribute to NixOS upstream to support `webUiUsernameSecret` option

### 5. **Excessive Assertions (Lines 474-520)**

**Problem**: Many assertions could be replaced with better type system usage.

**Current approach**: 12+ assertion checks

**Better approach**:

- Use `mkOption` with `type = types.submodule` and validation in the type system
- Use `lib.types.enum` or custom types with built-in validation
- Move validation closer to option definitions

### 6. **Proxy Configuration Complexity (Lines 523-593)**

**Problem**: Complex proxy config generation with conditional logic for auth.

**Current approach**: Inline config generation with conditional password handling

**Better approach**:

- Extract to separate file or function
- Use `lib.generators.toINI` or similar if 3proxy supports standard formats
- Consider if proxy auth is really needed (isolation might be enough)

## Recommendations for Improvement

### Immediate Wins (Low Risk)

1. **Consolidate Proxy Services**
   - Remove Privoxy and Dante
   - Use only 3proxy (supports both HTTP and SOCKS5)
   - Reduces ~70 lines of code

2. **Simplify Secret Resolution**

   ```nix
   resolveSecretPath = secretName: filePath:
     if secretName != null then
       config.sops.secrets."${secretName}".path
     else
       filePath;
   ```

3. **Extract Helper Functions**
   - Move proxy config generation to `lib/` or separate file
   - Extract WireGuard config generation to helper module
   - Create `media-management/lib.nix` with shared utilities

### Medium-Term Improvements

4. **Leverage VPN-Confinement Better**
   - Research if VPN-Confinement accepts structured WireGuard config
   - If yes, remove manual config generation
   - If no, consider contributing upstream

5. **Simplify Credential Management**
   - If possible, use `serverConfig` directly without runtime modification
   - Consider using environment variables instead of config file modification
   - Document why runtime modification is necessary

6. **Better Type System Usage**
   - Create custom types for VPN config validation
   - Use `mkOption` with validation functions
   - Reduce assertions by catching errors at type level

### Long-Term Considerations

7. **Module Splitting**
   - Split into `qbittorrent.nix` (core) and `qbittorrent-vpn.nix` (VPN integration)
   - This would make VPN optional and cleaner
   - Or create `media-management/vpn-proxy.nix` as shared module

8. **Upstream Contributions**
   - Contribute `webUiUsernameSecret` to NixOS `services.qbittorrent`
   - This would eliminate credential update script entirely

## Alternative Approaches in NixOS

### Option 1: Use `systemd-networkd` Namespaces

Instead of VPN-Confinement, use native NixOS networking:

- `networking.networks` with namespace support
- More declarative, less third-party dependency
- Better integration with NixOS networking stack

### Option 2: Use `containers` Feature

NixOS containers provide network isolation:

- `containers.qbittorrent` with `config.networking.vpn` or custom networking
- More NixOS-native approach
- Better resource isolation

### Option 3: Simpler VPN Approach

If VPN is just for routing, not isolation:

- Use `networking.wireguard` directly
- Configure qBittorrent to bind to WireGuard interface
- No namespace needed if trust model allows

## Complexity Score

| Aspect | Score | Notes |
|--------|-------|-------|
| **Overall** | 7/10 | Complex but manageable |
| **VPN Integration** | 8/10 | Too much manual work |
| **Proxy Services** | 9/10 | Three proxies is excessive |
| **Secret Handling** | 6/10 | Could be cleaner |
| **Maintainability** | 6/10 | Hard to understand flow |
| **NixOS Idioms** | 5/10 | Too much shell scripting |

## Conclusion

The module is **overengineered** but not catastrophically so. The main issues are:

1. **Redundant proxy services** - Easy fix
2. **Manual WireGuard config** - May be necessary, but worth investigating
3. **Runtime config modification** - Consider alternatives
4. **Complex conditionals** - Extract to helpers

**Recommended action**: Start with proxy consolidation (lowest risk, highest impact), then evaluate VPN-Confinement integration improvements.
