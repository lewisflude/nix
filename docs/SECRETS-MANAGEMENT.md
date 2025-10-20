# Secrets Management with sops-nix

This guide explains how to properly manage secrets in your NixOS configuration using `sops-nix`.

## Overview

**Current State:** Some services (like Doplarr) accept secrets via configuration options, which stores them in the world-readable Nix store.

**Recommended Approach:** Use `sops-nix` to encrypt secrets and mount them as files into containers.

## Why Use sops-nix?

### ❌ Problems with Current Approach

```nix
# BAD: Secrets in configuration
doplarr = {
  environment = {
    DISCORD_TOKEN = "abc123...";  # Stored in Nix store (world-readable!)
  };
};
```

**Issues:**
- Secrets visible in `/nix/store` (world-readable)
- Secrets in `git` history if committed
- Secrets visible in `podman inspect`
- No rotation mechanism
- No access control

### ✅ Benefits of sops-nix

- ✅ Secrets encrypted at rest
- ✅ Decrypted only at runtime
- ✅ File-based secrets (not environment variables)
- ✅ Age or GPG encryption
- ✅ Per-host keys
- ✅ Git-friendly (encrypted values)

## Setup Guide

### 1. Initial sops-nix Configuration

Your configuration already includes `sops-nix` as an input. First, create a host key:

```bash
# Generate age key for this host
mkdir -p /var/lib/sops-nix
age-keygen -o /var/lib/sops-nix/key.txt

# Get the public key (for .sops.yaml)
age-keygen -y /var/lib/sops-nix/key.txt
# Output: age1abc123...xyz789
```

### 2. Create .sops.yaml

Create `.sops.yaml` in your configuration root:

```yaml
# .sops.yaml
keys:
  # Your user key (for encrypting/editing)
  - &user_lewis age1abc123yourpersonalkeyxyz789
  
  # Jupiter host key (for decrypting on the system)
  - &host_jupiter age1def456jupiterhostkey123abc

creation_rules:
  # Secrets for Jupiter host
  - path_regex: secrets/jupiter\.yaml$
    key_groups:
      - age:
          - *user_lewis
          - *host_jupiter
  
  # Shared secrets across all hosts
  - path_regex: secrets/common\.yaml$
    key_groups:
      - age:
          - *user_lewis
          - *host_jupiter
          # Add other host keys here
```

### 3. Create Encrypted Secrets File

```bash
# Create secrets directory
mkdir -p secrets

# Create and edit encrypted secrets file
sops secrets/jupiter.yaml
```

In the editor, add your secrets:

```yaml
# secrets/jupiter.yaml (encrypted by sops)
doplarr:
  discord_token: "your-discord-bot-token-here"
  sonarr_api_key: "your-sonarr-api-key"
  radarr_api_key: "your-radarr-api-key"

calcom:
  nextauth_secret: "generated-nextauth-secret"
  calendar_encryption_key: "generated-calendar-key"
  db_password: "secure-database-password"
```

Save and exit. The file will be encrypted automatically.

### 4. Configure sops-nix in NixOS

In your host configuration (e.g., `hosts/jupiter/configuration.nix`):

```nix
{ config, ... }: {
  # Point sops-nix to your age key
  sops = {
    defaultSopsFile = ../../secrets/jupiter.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    
    # Define secrets that should be extracted
    secrets = {
      "doplarr/discord_token" = {
        owner = "1000";  # Container UID
        group = "100";   # Container GID
        mode = "0400";   # Read-only for owner
      };
      
      "doplarr/sonarr_api_key" = {
        owner = "1000";
        group = "100";
        mode = "0400";
      };
      
      "doplarr/radarr_api_key" = {
        owner = "1000";
        group = "100";
        mode = "0400";
      };
      
      "calcom/nextauth_secret" = {
        owner = "1000";
        group = "100";
        mode = "0400";
      };
      
      "calcom/calendar_encryption_key" = {
        owner = "1000";
        group = "100";
        mode = "0400";
      };
      
      "calcom/db_password" = {
        owner = "1000";
        group = "100";
        mode = "0400";
      };
    };
  };
}
```

### 5. Update Container Configuration

**Option A: Mount Secrets as Files (Recommended)**

```nix
# modules/nixos/services/containers-supplemental/default.nix
virtualisation.oci-containers.containers = {
  doplarr = mkIf cfg.doplarr.enable {
    image = "ghcr.io/hotio/doplarr:release-3.7.0";
    
    # Mount secrets as read-only files
    volumes = [
      "${cfg.configPath}/doplarr:/config"
      "${config.sops.secrets."doplarr/discord_token".path}:/run/secrets/discord_token:ro"
      "${config.sops.secrets."doplarr/sonarr_api_key".path}:/run/secrets/sonarr_api_key:ro"
      "${config.sops.secrets."doplarr/radarr_api_key".path}:/run/secrets/radarr_api_key:ro"
    ];
    
    # Use _FILE suffix if supported by the application
    environment = commonEnv // {
      DISCORD_TOKEN_FILE = "/run/secrets/discord_token";
      SONARR_API_KEY_FILE = "/run/secrets/sonarr_api_key";
      RADARR_API_KEY_FILE = "/run/secrets/radarr_api_key";
      SONARR_URL = "http://localhost:8989";
      RADARR_URL = "http://localhost:7878";
    };
    
    extraOptions = ["--network=host"];
  };
};
```

**Option B: Read Secrets into Environment (Less Secure)**

If the application doesn't support `_FILE` suffix:

```nix
# Create a helper script that reads secrets
systemd.services.podman-doplarr = {
  preStart = ''
    export DISCORD_TOKEN=$(cat ${config.sops.secrets."doplarr/discord_token".path})
    export SONARR_API_KEY=$(cat ${config.sops.secrets."doplarr/sonarr_api_key".path})
    export RADARR_API_KEY=$(cat ${config.sops.secrets."doplarr/radarr_api_key".path})
  '';
};
```

**Note:** This still exposes secrets in the process environment. File-based is preferred.

### 6. Update Configuration Options

Remove plaintext secret options and document sops-nix usage:

```nix
# modules/nixos/services/containers-supplemental/default.nix
options.host.services.containersSupplemental = {
  # ... other options ...
  
  # Remove these plaintext options:
  # doplarr = {
  #   discordToken = mkOption { ... };  # REMOVED
  #   sonarrApiKey = mkOption { ... };  # REMOVED
  # };
  
  # Add documentation instead
  doplarr.enable = mkEnableOption "Doplarr Discord bot" // {
    description = ''
      Enable Doplarr Discord bot.
      
      Secrets must be configured via sops-nix:
      - doplarr/discord_token
      - doplarr/sonarr_api_key
      - doplarr/radarr_api_key
      
      See docs/SECRETS-MANAGEMENT.md for setup instructions.
    '';
  };
};
```

## Complete Example: Cal.com with Secrets

```nix
# In host configuration
sops.secrets = {
  "calcom/nextauth_secret" = {
    owner = "1000";
    group = "100";
    restartUnits = ["podman-calcom.service"];  # Auto-restart on secret change
  };
  "calcom/calendar_encryption_key" = {
    owner = "1000";
    group = "100";
    restartUnits = ["podman-calcom.service"];
  };
  "calcom/db_password" = {
    owner = "1000";
    group = "100";
    restartUnits = ["podman-calcom.service" "podman-calcom-db.service"];
  };
};

# In containers-supplemental module
virtualisation.oci-containers.containers = {
  calcom-db = {
    image = "docker.io/library/postgres:16.3-alpine";
    
    volumes = [
      "${cfg.configPath}/calcom/postgres:/var/lib/postgresql/data"
      "${config.sops.secrets."calcom/db_password".path}:/run/secrets/db_password:ro"
    ];
    
    # PostgreSQL supports Docker secrets via _FILE suffix
    environment = {
      POSTGRES_USER = "calcom";
      POSTGRES_PASSWORD_FILE = "/run/secrets/db_password";
      POSTGRES_DB = "calcom";
    };
  };
  
  calcom = {
    image = "docker.io/calcom/cal.com:v4.0.8";
    
    volumes = [
      "${cfg.configPath}/calcom/app_data:/app/data"
      "${config.sops.secrets."calcom/nextauth_secret".path}:/run/secrets/nextauth_secret:ro"
      "${config.sops.secrets."calcom/calendar_encryption_key".path}:/run/secrets/calendar_key:ro"
      "${config.sops.secrets."calcom/db_password".path}:/run/secrets/db_password:ro"
    ];
    
    environment = {
      DATABASE_URL = "postgresql://calcom:$(cat /run/secrets/db_password)@calcom-db:5432/calcom";
      NEXTAUTH_SECRET_FILE = "/run/secrets/nextauth_secret";
      CALENDSO_ENCRYPTION_KEY_FILE = "/run/secrets/calendar_key";
      NEXT_PUBLIC_WEBAPP_URL = cfg.calcom.webappUrl;
      CALCOM_TIMEZONE = cfg.timezone;
    };
  };
};
```

## Best Practices

### ✅ DO

1. **Use file-based secrets** with `_FILE` suffix when possible
2. **Set restrictive permissions** (0400 or 0440)
3. **Use per-service secrets** (don't share unnecessarily)
4. **Rotate secrets regularly** (edit with `sops secrets/jupiter.yaml`)
5. **Use `restartUnits`** to auto-restart on secret changes
6. **Keep age keys secure** (`/var/lib/sops-nix/key.txt` should be 0600)

### ❌ DON'T

1. **Don't commit plaintext secrets** to git
2. **Don't use environment variables** when file-based is available
3. **Don't share secrets** across unrelated services
4. **Don't use weak permissions** (777, 666, etc.)
5. **Don't store secrets in Nix store** (via configuration options)

## Troubleshooting

### Secret file not found

```bash
# Check if secret was extracted
ls -la /run/secrets/
ls -la /run/secrets-for-users/

# Verify sops configuration
nixos-rebuild dry-activate 2>&1 | grep sops
```

### Permission denied

```bash
# Check secret file permissions
ls -la $(nix-instantiate --eval -E '(import <nixpkgs> {}).config.sops.secrets."doplarr/discord_token".path' | tr -d '"')

# Verify container UID/GID matches secret owner
podman inspect doplarr | grep -A5 User
```

### Secret not decrypting

```bash
# Verify age key exists and is readable
ls -la /var/lib/sops-nix/key.txt

# Test decryption manually
sops -d secrets/jupiter.yaml

# Check if host public key is in .sops.yaml
grep "host_jupiter" .sops.yaml
```

## Migration Path

For existing deployments with hardcoded secrets:

### Phase 1: Add sops-nix (No Breaking Changes)
1. Set up sops-nix infrastructure
2. Keep existing plaintext options as fallback
3. Test with non-critical services first

### Phase 2: Migrate Secrets
1. Move secrets to sops
2. Update container configurations
3. Verify containers start successfully

### Phase 3: Remove Plaintext Options
1. Remove configuration options that accepted plaintext
2. Add documentation pointing to sops-nix
3. Clean up any remaining hardcoded values

## Additional Resources

- [sops-nix Documentation](https://github.com/Mic92/sops-nix)
- [Mozilla SOPS](https://github.com/mozilla/sops)
- [Age Encryption](https://github.com/FiloSottile/age)
- [Docker Secrets Best Practices](https://docs.docker.com/engine/swarm/secrets/)
