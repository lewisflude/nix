{ lib, ... }:
let

  certPath = ../../../secrets/certificates/mitmproxy-ca-cert.pem;
  certExists = builtins.pathExists certPath;
in
{
  security.pki.certificateFiles = lib.optionals certExists [
    certPath
  ];
}
