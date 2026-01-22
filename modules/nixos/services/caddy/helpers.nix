# Caddy Helper Functions
# Reduces repetition in virtual host definitions
_:
let
  # inherit (lib) concatStringsSep;

  # Standard reverse proxy headers
  standardHeaders = ''
    header_up X-Real-IP {remote_host}
    header_up X-Forwarded-For {remote_host}
    header_up X-Forwarded-Proto {scheme}
  '';

  # Standard encoding
  standardEncoding = "encode zstd gzip";
in
{
  # Create a standard reverse proxy virtual host config
  # Usage: mkReverseProxy "localhost:8080"
  mkReverseProxy = target: {
    extraConfig = ''
      reverse_proxy ${target} {
        ${standardHeaders}
      }
      ${standardEncoding}
    '';
  };

  # Create a reverse proxy with custom headers
  # Usage: mkReverseProxyWithHeaders "localhost:8080" "header_up Host {host}"
  mkReverseProxyWithHeaders = target: extraHeaders: {
    extraConfig = ''
      reverse_proxy ${target} {
        ${standardHeaders}
        ${extraHeaders}
      }
      ${standardEncoding}
    '';
  };

  # Create a reverse proxy with special transport (e.g., HTTPS with insecure skip verify)
  # Usage: mkReverseProxyWithTransport "https://localhost:8080" "tls_insecure_skip_verify"
  mkReverseProxyWithTransport = target: transportConfig: {
    extraConfig = ''
      reverse_proxy ${target} {
        transport http {
          ${transportConfig}
        }
        header_up Host {host}
        ${standardHeaders}
      }
      ${standardEncoding}
    '';
  };

  # Create a reverse proxy with HTTP Basic Auth protection
  # Usage: mkAuthenticatedProxy "localhost:8080"
  # Note: Requires setting up credentials via Caddy's hash-password command
  mkAuthenticatedProxy = target: {
    extraConfig = ''
      basicauth {
        # Generate hash with: caddy hash-password
        # Add users here or import from secrets
        import /etc/caddy/basicauth.conf
      }
      reverse_proxy ${target} {
        ${standardHeaders}
      }
      ${standardEncoding}
    '';
  };
}
