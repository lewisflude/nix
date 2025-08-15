_: {
  # Certificate management configuration
  # This module handles custom certificates for development and security tools

  security.pki.certificateFiles = [
    # MITMPROXY Certificate for development debugging
    # This certificate allows mitmproxy to intercept HTTPS traffic for debugging
    # Only enable on development machines - NOT for production
    ../../secrets/certificates/mitmproxy-ca-cert.pem
  ];

  # Additional certificate validation and security settings
  security.pki.settings = {
    # Add any additional PKI settings here if needed
  };
}
