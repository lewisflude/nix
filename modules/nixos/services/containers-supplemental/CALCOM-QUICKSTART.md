# Cal.com Quick Start

## 1. Generate Secrets

```bash
echo "NEXTAUTH_SECRET=$(openssl rand -hex 32)"
echo "CALENDSO_ENCRYPTION_KEY=$(openssl rand -hex 32)"
```

## 2. Enable in Your Host Config

Edit `hosts/jupiter/default.nix` (or your host file):

```nix
containersSupplemental = {
  enable = true;
  
  calcom = {
    enable = true;
    nextauthSecret = "paste_generated_secret_here";
    calendarEncryptionKey = "paste_generated_key_here";
    dbPassword = "choose_secure_db_password";
  };
};
```

## 3. Apply Configuration

```bash
sudo nixos-rebuild switch
```

## 4. Initialize Database

```bash
# Wait for containers to start
sleep 10

# Run migrations
sudo podman exec -it calcom npx prisma migrate deploy
```

## 5. Access Cal.com

Open browser: http://localhost:3000

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `enable` | `false` | Enable Cal.com service |
| `port` | `3000` | Host port to expose |
| `webappUrl` | `http://localhost:3000` | Public URL |
| `nextauthSecret` | `null` | Required auth secret |
| `calendarEncryptionKey` | `null` | Required encryption key |
| `dbPassword` | `calcom_secure_password` | PostgreSQL password |

## Data Locations

- Database: `/var/lib/containers/supplemental/calcom/postgres/`
- App Data: `/var/lib/containers/supplemental/calcom/app_data/`

## Useful Commands

```bash
# View status
sudo podman ps | grep calcom

# View logs
sudo podman logs -f calcom
sudo podman logs -f calcom-db

# Restart
sudo systemctl restart podman-calcom
sudo systemctl restart podman-calcom-db

# Database access
sudo podman exec -it calcom-db psql -U calcom -d calcom
```

## Troubleshooting

### Container won't start?
```bash
sudo podman logs calcom
sudo podman logs calcom-db
```

### Need to reset database?
```bash
sudo systemctl stop podman-calcom podman-calcom-db
sudo rm -rf /var/lib/containers/supplemental/calcom/postgres/*
sudo nixos-rebuild switch
# Wait, then run migrations again
```

## Production Tips

1. **Use HTTPS**: Set up Nginx/Caddy reverse proxy
2. **Secure Secrets**: Use sops-nix or agenix
3. **Regular Backups**: Backup PostgreSQL database
4. **Update Image**: Keep container updated
5. **Monitor Logs**: Watch for errors

For full documentation, see `CALCOM-SETUP.md`
