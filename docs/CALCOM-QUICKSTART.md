# Cal.com Quick Start Guide

Cal.com has been enabled in your NixOS configuration! Here's how to get started.

## Overview

Cal.com is now running as a container on your system with:
- **Web UI**: http://localhost:3000
- **Database**: PostgreSQL (calcom-db container)
- **Data**: `/var/lib/containers/supplemental/calcom/`

## Configuration Details

### Current Settings

```nix
calcom.enable = true;
calcom.port = 3000;  # Default
calcom.webappUrl = "http://localhost:3000";  # Change for production
```

### Important Security Keys

⚠️ **WARNING**: Default secrets are currently in use. For production, you should:

1. **Generate new secrets**:
   ```bash
   # Generate NextAuth secret
   openssl rand -base64 32
   
   # Generate Calendar encryption key
   openssl rand -base64 32
   
   # Generate database password
   openssl rand -base64 32
   ```

2. **Update configuration**:
   ```nix
   # In hosts/jupiter/default.nix
   containersSupplemental = {
     enable = true;
     calcom = {
       enable = true;
       port = 3000;
       webappUrl = "http://localhost:3000";  # Or your domain
       nextauthSecret = "YOUR-NEW-SECRET-HERE";
       calendarEncryptionKey = "YOUR-NEW-KEY-HERE";
       dbPassword = "YOUR-NEW-PASSWORD-HERE";
     };
   };
   ```

3. **Better: Use sops-nix for secrets**
   - See `docs/SECRETS-MANAGEMENT.md` for proper secret management

## First Time Setup

### 1. Rebuild Your System

```bash
cd ~/.config/nix
nixos-rebuild switch --flake .#jupiter
```

This will:
- Create the PostgreSQL database container
- Create the Cal.com application container
- Set up necessary directories with correct permissions
- Start both services

### 2. Check Service Status

```bash
# Check if containers are running
systemctl status podman-calcom-db.service
systemctl status podman-calcom.service

# Or check with podman directly
podman ps | grep calcom
```

You should see both `calcom-db` and `calcom` containers running.

### 3. Access Cal.com

Open your browser and go to: **http://localhost:3000**

On first visit, you'll see the Cal.com setup wizard.

### 4. Complete Initial Setup

1. **Create your account** - First user becomes the admin
2. **Set up your profile** - Name, bio, timezone
3. **Connect calendars** (optional) - Google Calendar, Outlook, etc.
4. **Create event types** - Define your meeting types

## Usage

### Creating an Event Type

1. Go to **Event Types** in the sidebar
2. Click **New Event Type**
3. Configure:
   - Duration (15min, 30min, 1hr, etc.)
   - Availability windows
   - Buffer time between meetings
   - Required/optional attendee info

### Sharing Your Booking Link

Your booking link will be: `http://localhost:3000/your-username/event-type`

**For Production**: Set `webappUrl` to your public domain (e.g., `https://cal.yourdomain.com`)

### Connecting Calendars

Cal.com can sync with:
- Google Calendar
- Microsoft Outlook
- Apple Calendar
- CalDAV

Go to **Settings → Calendars** to connect.

## Production Setup

### Using a Domain Name

1. **Update configuration**:
   ```nix
   containersSupplemental.calcom = {
     enable = true;
     port = 3000;
     webappUrl = "https://cal.yourdomain.com";
   };
   ```

2. **Set up reverse proxy** (Caddy example):
   ```nix
   services.caddy = {
     enable = true;
     virtualHosts."cal.yourdomain.com".extraConfig = ''
       reverse_proxy localhost:3000
     '';
   };
   ```

3. **Open firewall** (if needed):
   ```nix
   networking.firewall.allowedTCPPorts = [ 80 443 ];
   ```

### SSL/HTTPS

The reverse proxy (Caddy, nginx, etc.) handles SSL automatically when configured properly.

## Backups

### What Gets Backed Up

Cal.com data is stored in:
```
/var/lib/containers/supplemental/calcom/
├── postgres/          # PostgreSQL database
└── app_data/          # Application data
```

### Manual Backup

```bash
# Stop the containers
systemctl stop podman-calcom.service podman-calcom-db.service

# Create backup
tar czf calcom-backup-$(date +%Y%m%d).tar.gz \
  -C /var/lib/containers/supplemental calcom

# Restart containers
systemctl start podman-calcom-db.service podman-calcom.service
```

### Database Dump (Recommended)

```bash
# Dump PostgreSQL database
podman exec calcom-db pg_dump -U calcom calcom > calcom-dump.sql

# Restore from dump
cat calcom-dump.sql | podman exec -i calcom-db psql -U calcom calcom
```

### Automated Backups

Your configuration includes Restic backups. Cal.com data will be included automatically.

See `docs/BACKUP-STRATEGY.md` for details.

## Troubleshooting

### Container Won't Start

```bash
# Check logs
journalctl -u podman-calcom.service -f
journalctl -u podman-calcom-db.service -f

# Or with podman
podman logs calcom
podman logs calcom-db
```

### Database Connection Issues

```bash
# Check if database is ready
podman exec calcom-db pg_isready -U calcom

# Restart in order
systemctl restart podman-calcom-db.service
sleep 10  # Wait for DB to be ready
systemctl restart podman-calcom.service
```

### Port Already in Use

If port 3000 is in use, change it:

```nix
containersSupplemental.calcom.port = 3001;  # Use different port
```

Then access at: `http://localhost:3001`

### Reset Admin Password

```bash
# Connect to database
podman exec -it calcom-db psql -U calcom calcom

# Check users
SELECT id, email, username FROM users;

# Reset password (requires bcrypt hash)
# Generate hash: https://bcrypt-generator.com/
UPDATE users SET password = '$2a$10$...' WHERE email = 'your@email.com';
```

## Monitoring

### Check Container Health

```bash
# Health check status
podman healthcheck run calcom
podman healthcheck run calcom-db

# Resource usage
podman stats calcom calcom-db
```

### View Logs

```bash
# Cal.com application logs
podman logs -f calcom

# Database logs
podman logs -f calcom-db

# System logs
journalctl -u podman-calcom* -f
```

## Resource Usage

Typical resource consumption:
- **Cal.com app**: ~1GB RAM, 1-2 CPU cores
- **PostgreSQL**: ~500MB RAM, 1 CPU core
- **Disk**: ~500MB (grows with bookings)

Resource limits are configured to:
- Cal.com: 2GB RAM, 2 CPUs
- PostgreSQL: 1GB RAM, 2 CPUs

## Integration Options

Cal.com supports integrations with:
- **Video**: Zoom, Google Meet, Microsoft Teams
- **Calendars**: Google, Outlook, Apple, CalDAV
- **Payment**: Stripe (for paid bookings)
- **CRM**: Salesforce, HubSpot
- **Email**: Custom SMTP, SendGrid, etc.

Configure in **Settings → Integrations**

## Useful Commands

```bash
# Start/Stop Cal.com
systemctl start podman-calcom.service
systemctl stop podman-calcom.service

# Restart (if changes don't apply)
systemctl restart podman-calcom.service

# Check status
systemctl status podman-calcom.service

# View container details
podman inspect calcom

# Execute command in container
podman exec -it calcom sh

# Database shell
podman exec -it calcom-db psql -U calcom calcom
```

## Updating Cal.com

To update to a newer version:

1. **Check latest version**: https://github.com/calcom/cal.com/releases

2. **Update image tag** in `modules/nixos/services/containers-supplemental/default.nix`:
   ```nix
   image = "docker.io/calcom/cal.com:v4.1.0";  # New version
   ```

3. **Rebuild**:
   ```bash
   nixos-rebuild switch --flake .#jupiter
   ```

The update will:
- Pull new image
- Restart container
- Run database migrations automatically

## Additional Resources

- [Cal.com Documentation](https://cal.com/docs)
- [Self-Hosting Guide](https://cal.com/docs/self-hosting)
- [Environment Variables](https://cal.com/docs/self-hosting/environment-variables)
- [GitHub Repository](https://github.com/calcom/cal.com)

## Support

- Cal.com Community: https://cal.com/slack
- GitHub Issues: https://github.com/calcom/cal.com/issues
- Documentation: https://cal.com/docs

---

**Next Steps:**
1. Access http://localhost:3000 and complete setup
2. Create your first event type
3. Share your booking link!
4. Consider setting up a custom domain for production use
5. Configure calendar integrations
