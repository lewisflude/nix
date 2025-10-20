# Cal.com Example Configuration
# Add this to your host configuration (e.g., hosts/jupiter/default.nix)
{
  # Example 1: Basic Development Setup
  containersSupplemental = {
    enable = true;

    calcom = {
      enable = true;
      port = 3000;
      webappUrl = "http://localhost:3000";

      # REQUIRED: Generate these with: openssl rand -hex 32
      nextauthSecret = "YOUR_NEXTAUTH_SECRET_HERE";
      calendarEncryptionKey = "YOUR_ENCRYPTION_KEY_HERE";

      # Database password
      dbPassword = "secure_postgres_password";
    };
  };

  # Example 2: Production Setup with Custom Domain
  /*
  containersSupplemental = {
    enable = true;

    calcom = {
      enable = true;
      port = 3000;
      webappUrl = "https://cal.yourdomain.com";

      # Use proper secrets management in production (sops-nix, agenix, etc.)
      nextauthSecret = "actual_secure_32_byte_hex_string";
      calendarEncryptionKey = "actual_secure_32_byte_hex_string";
      dbPassword = "very_secure_database_password";
    };
  };

  # Don't forget to set up reverse proxy for HTTPS:
  services.nginx.virtualHosts."cal.yourdomain.com" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:3000";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };
  */

  # Example 3: Custom Port Setup
  /*
  containersSupplemental = {
    enable = true;

    calcom = {
      enable = true;
      port = 8080;  # Use different port
      webappUrl = "http://localhost:8080";
      nextauthSecret = "your_secret";
      calendarEncryptionKey = "your_key";
      dbPassword = "your_db_password";
    };
  };
  */
}
# After enabling, run:
# 1. sudo nixos-rebuild switch
# 2. Wait for containers to start
# 3. sudo podman exec -it calcom npx prisma migrate deploy
# 4. Access http://localhost:3000 (or your configured URL)

