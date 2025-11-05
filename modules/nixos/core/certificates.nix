{ lib, ... }:
let
  # Optional certificate - only include if file exists
  # This allows builds to succeed in CI where the certificate isn't available
  certPath = ../../../secrets/certificates/mitmproxy-ca-cert.pem;
  certExists = builtins.pathExists certPath;
in
{
  security.pki.certificateFiles = lib.optionals certExists [
    certPath
  ];
}
