# Caddy Helper Functions
# Reduces repetition in virtual host definitions
{ lib }:
let
  inherit (lib) optionalString;

  standardHeaders = ''
    header_up X-Real-IP {remote_host}
    header_up X-Forwarded-For {remote_host}
    header_up X-Forwarded-Proto {scheme}
  '';

  standardEncoding = "encode zstd gzip";
in
rec {
  # Unified reverse proxy builder with optional features
  # Usage:
  #   mkProxy { target = "localhost:8080"; }
  #   mkProxy { target = "localhost:8080"; extraHeaders = "header_up Host {host}"; }
  #   mkProxy { target = "https://localhost:8080"; transport = "tls_insecure_skip_verify"; }
  #   mkProxy { target = "localhost:8080"; basicAuth = true; }
  mkProxy =
    {
      target,
      extraHeaders ? "",
      transport ? null,
      basicAuth ? false,
    }:
    {
      extraConfig = ''
        ${optionalString basicAuth ''
          basicauth {
            import /etc/caddy/basicauth.conf
          }
        ''}
        reverse_proxy ${target} {
          ${optionalString (transport != null) ''
            transport http {
              ${transport}
            }
            header_up Host {host}
          ''}
          ${standardHeaders}
          ${extraHeaders}
        }
        ${standardEncoding}
      '';
    };

  # Legacy helper functions (kept for backward compatibility, delegates to mkProxy)
  mkReverseProxy = target: mkProxy { inherit target; };
  mkReverseProxyWithHeaders = target: extraHeaders: mkProxy { inherit target extraHeaders; };
  mkReverseProxyWithTransport = target: transport: mkProxy { inherit target transport; };
  mkAuthenticatedProxy = target: mkProxy {
    inherit target;
    basicAuth = true;
  };
}
