# Cal.com Setup Guide

Cal.com is an open-source scheduling platform integrated into your NixOS configuration as a Podman container.

## Quick Start

### 1. Generate Required Secrets

Generate secure secrets for Cal.com:

```bash
# Generate NextAuth secret
openssl rand -hex 32

# Generate Calendar encryption key
openssl rand -hex 32
```

### 2. Enable Cal.com

Add Cal.com configuration to your host file (e.g., `hosts/jupiter/default.nix`):

```nix
containersSupplemental = {
  enable = true;
  
  calcom = {
    enable = true;
    port = 3000;  # Port to expose Cal.com on
    webappUrl = "http://localhost:3000";  # Change to your domain in production
    nextauthSecret = "your_generated_secret_here";
    calendarEncryptionKey = "your_generated_key_here";
    dbPassword = "secure_database_password";
  };
};
```

### 3. Apply Configuration

```bash
sudo nixos-rebuild switch
```

### 4. Run Database Migrations (Required on First Setup)

After the containers start, you need to initialize the database schema:

```bash
# Wait a few seconds for containers to fully start
sleep 10

# Run Prisma migrations
sudo podman exec -it calcom npx prisma migrate deploy

# (Optional) Seed initial data if needed
sudo podman exec -it calcom npx ts-node --project prisma/tsconfig.json ./prisma/seed.ts
```

### 5. Access Cal.com

Open your browser and navigate to:
- `http://localhost:3000` (or your configured URL)
- Complete the initial setup wizard
- Create your first user account

## Configuration Options

### Available Options

```nix
calcom = {
  enable = false;  # Enable/disable Cal.com service
  
  port = 3000;     # Host port to expose Cal.com on
  
  webappUrl = "http://localhost:3000";  # Public URL for Cal.com
  # For production with a domain: "https://cal.example.com"
  
  nextauthSecret = null;  # NextAuth secret (required)
  # Generate with: openssl rand -hex 32
  
  calendarEncryptionKey = null;  # Calendar encryption key (required)
  # Generate with: openssl rand -hex 32
  
  dbPassword = "calcom_secure_password";  # PostgreSQL password
  # Change this to a secure password
};
```

### Common Configuration Examples

#### Development Setup (localhost)

```nix
calcom = {
  enable = true;
  port = 3000;
  webappUrl = "http://localhost:3000";
  nextauthSecret = "dev_secret_change_in_production";
  calendarEncryptionKey = "dev_key_change_in_production";
  dbPassword = "dev_password";
};
```

#### Production Setup (with domain)

```nix
calcom = {
  enable = true;
  port = 3000;
  webappUrl = "https://cal.example.com";
  nextauthSecret = "actual_secure_secret_from_openssl";
  calendarEncryptionKey = "actual_secure_key_from_openssl";
  dbPassword = "very_secure_database_password";
};
```

## Data Persistence

Cal.com data is stored in:
- **PostgreSQL Data**: `/var/lib/containers/supplemental/calcom/postgres/`
- **Application Data**: `/var/lib/containers/supplemental/calcom/app_data/`

These directories are automatically created with proper permissions on system rebuild.

## Container Management

### View Container Status

```bash
sudo podman ps | grep calcom
```

### View Logs

```bash
# Cal.com application logs
sudo podman logs -f calcom

# Database logs
sudo podman logs -f calcom-db
```

### Restart Containers

```bash
sudo systemctl restart podman-calcom
sudo systemctl restart podman-calcom-db
```

### Stop Containers

```bash
sudo systemctl stop podman-calcom
sudo systemctl stop podman-calcom-db
```

## Troubleshooting

### Container Won't Start

Check logs:
```bash
sudo podman logs calcom
sudo podman logs calcom-db
```

### Database Connection Issues

Ensure the database is running:
```bash
sudo podman ps | grep calcom-db
```

Check database logs:
```bash
sudo podman logs calcom-db
```

### Migrations Failed

Try running migrations manually:
```bash
sudo podman exec -it calcom npx prisma migrate deploy
```

If migrations are corrupted, you may need to reset the database:
```bash
sudo systemctl stop podman-calcom
sudo systemctl stop podman-calcom-db
sudo rm -rf /var/lib/containers/supplemental/calcom/postgres/*
sudo nixos-rebuild switch
# Wait for containers to start, then run migrations again
```

### Access Database Directly

```bash
sudo podman exec -it calcom-db psql -U calcom -d calcom
```

## Security Considerations

### For Production Use

1. **Generate Strong Secrets**: Always use `openssl rand -hex 32` for secrets
2. **Use HTTPS**: Configure reverse proxy (Nginx/Caddy) for SSL/TLS
3. **Firewall Rules**: Restrict access to Cal.com port
4. **Regular Backups**: Backup PostgreSQL database regularly
5. **Update Container**: Keep Cal.com image updated

### Secrets Management with sops-nix

This module now supports sops-nix for secure secrets management. There are two ways to configure secrets:

#### Option 1: Direct Configuration (Development Only)
```nix
host.features.containersSupplemental = {
  enable = true;
  calcom = {
    enable = true;
    nextauthSecret = "your_generated_secret_here";
    calendarEncryptionKey = "your_generated_key_here";
    dbPassword = "secure_database_password";
  };
};
```

⚠️ **WARNING**: Never commit secrets directly to git!

#### Option 2: sops-nix Integration (Recommended for Production)

1. **Enable sops mode**:
```nix
host.features.containersSupplemental = {
  enable = true;
  calcom = {
    enable = true;
    useSops = true;  # Enable sops-nix integration
  };
};
```

2. **Add secrets to your `secrets/secrets.yaml`**:
```bash
# Generate the secrets first
openssl rand -base64 32  # For nextauth secret
openssl rand -base64 32  # For encryption key
# Choose a strong password for database

# Edit your secrets file
sops secrets/secrets.yaml
```

Add these entries:
```yaml
calcom-nextauth-secret: "your_nextauth_secret_here"
calcom-encryption-key: "your_encryption_key_here"
calcom-db-password: "your_db_password_here"
```

3. **The module will automatically**:
   - Define the sops secrets
   - Create environment file templates
   - Inject secrets into containers securely
   - Validate that all required secrets are present

Benefits of sops-nix:
- ✅ Secrets encrypted in repository
- ✅ Automatic decryption at runtime
- ✅ No secrets in Nix store
- ✅ Age/GPG encryption support
- ✅ Multi-user/host support

## Backup and Restore

### Backup Database

```bash
sudo podman exec calcom-db pg_dump -U calcom calcom > calcom-backup.sql
```

### Restore Database

```bash
cat calcom-backup.sql | sudo podman exec -i calcom-db psql -U calcom -d calcom
```

### Backup Application Data

```bash
sudo tar -czf calcom-appdata-backup.tar.gz /var/lib/containers/supplemental/calcom/app_data/
```

## Reverse Proxy Setup

### Nginx Example

```nix
services.nginx.virtualHosts."cal.example.com" = {
  enableACME = true;
  forceSSL = true;
  locations."/" = {
    proxyPass = "http://localhost:3000";
    proxyWebsockets = true;
  };
};
```

### Caddy Example

```nix
services.caddy.virtualHosts."cal.example.com".extraConfig = ''
  reverse_proxy localhost:3000
'';
```

## Integration Features

Cal.com supports integrations with:
- Google Calendar
- Microsoft 365
- Zoom
- Google Meet
- Stripe (for payments)
- And many more...

Configure these through the Cal.com web interface after setup.

## Resources

- **Official Documentation**: https://cal.com/docs
- **GitHub Repository**: https://github.com/calcom/cal.com
- **Community Forum**: https://github.com/calcom/cal.com/discussions
