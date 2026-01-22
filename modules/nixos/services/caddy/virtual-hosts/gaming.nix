# Gaming Services Virtual Hosts
# Sunshine streaming, etc.
_:
let
  constants = import ../../../../../lib/constants.nix;
in
{
  # Sunshine (Gaming) - special transport config
  "sunshine.blmt.io" = {
    extraConfig = ''
      reverse_proxy https://127.0.0.1:${toString constants.ports.services.sunshine.http} {
        transport http {
          tls_insecure_skip_verify
        }
        header_up Host {host}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
      }
      encode zstd gzip
    '';
  };
}
