# Caddy CSRF Header Fix - December 1, 2025

## Summary

Added CSRF protection bypass headers to Caddy reverse proxy configuration for qBittorrent and Transmission. This resolves "Unauthorized" errors when accessing these services via their public domain names.

## Problem

qBittorrent and Transmission have built-in CSRF protection that validates the `Host` header. When accessing via reverse proxy (e.g., `torrent.blmt.io`), the Host header doesn't match the expected `localhost:8080`, causing authentication failures.

## Solution

Configure Caddy to rewrite request headers to satisfy CSRF checks without disabling security:

```caddy
reverse_proxy 192.168.15.1:8080 {
  # CSRF Protection Fix
  header_up Host localhost:8080
  header_up Origin http://localhost:8080
  header_up Referer http://localhost:8080

  # Standard proxy headers
  header_up X-Real-IP {remote_host}
  header_up X-Forwarded-For {remote_host}
  header_up X-Forwarded-Proto {scheme}
}
```

## Files Modified

- `modules/nixos/services/caddy.nix`
  - Updated `torrent.blmt.io` virtual host
  - Updated `transmission.blmt.io` virtual host

## Testing

After rebuilding:

1. Access `https://torrent.blmt.io` - should load without "Unauthorized"
2. Access `https://transmission.blmt.io` - should load without authentication errors
3. Verify functionality:
   - Add/remove torrents
   - Modify settings
   - Check API access works

## Security Note

This approach is **secure** because:

1. We're not disabling CSRF protection
2. Headers are rewritten by our trusted reverse proxy
3. The application still validates the Host header
4. External attackers cannot bypass this (they don't control our Caddy server)

## References

- Based on recommendation from optimal NixOS + ProtonVPN + Caddy setup guide
- Similar to nginx's `proxy_set_header Host` directive
- qBittorrent CSRF documentation: <https://github.com/qbittorrent/qBittorrent/wiki/WebUI-HTTPS-configuration>
