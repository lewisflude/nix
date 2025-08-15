_: {
  # Certificate management configuration
  # This module handles custom certificates for development and security tools

  security.pki.certificateFiles = [
    # MITMPROXY Certificate for development debugging
    # This certificate allows mitmproxy to intercept HTTPS traffic for debugging
    # Only enable on development machines - NOT for production
    ../../../secrets/certificates/mitmproxy-ca-cert.pem
  ];

  # Additional PKI options can be configured here as needed
  # See: https://search.nixos.org/options?query=security.pki
}
