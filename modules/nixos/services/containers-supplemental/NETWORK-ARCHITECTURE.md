# Container Network Architecture

This document describes the network isolation strategy for containerized services in this NixOS configuration.

## Network Overview

Our container deployment uses a multi-network approach for security and service isolation:

```
┌─────────────────────────────────────────────────────────────┐
│                         Host Network                         │
│  (Direct host access - use sparingly for special cases)    │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼────────┐  ┌─────────▼────────┐  ┌────────▼────────┐
│   Bridge/NAT   │  │  Default Bridge  │  │  Host Network   │
│   (Isolated)   │  │   (Container)    │  │  (Privileged)   │
└────────────────┘  └──────────────────┘  └─────────────────┘
```

## Network Types

### 1. **Default Bridge Network** (Preferred)
- **Usage**: Most containers
- **Security**: Isolated from host, port mapping required
- **DNS**: Automatic container-to-container DNS resolution
- **Examples**: Homarr, Wizarr, ComfyUI, Cal.com

**Benefits:**
- Network isolation by default
- Explicit port exposure (principle of least privilege)
- Container-to-container communication via DNS names
- Easy to firewall and monitor

**Configuration:**
```nix
virtualisation.oci-containers.containers = {
  homarr = {
    ports = ["7575:7575"];  # Explicit port mapping
    # Uses default bridge network automatically
  };
};
```

### 2. **Host Network** (Use Sparingly)
- **Usage**: Services requiring direct network access or complex port requirements
- **Security**: ⚠️ Lower isolation, direct host network access
- **Examples**: Doplarr (Discord bot), Music Assistant (multicast)

**When to Use:**
- Services requiring multicast/broadcast (DLNA, mDNS)
- Complex dynamic port allocation
- Performance-critical networking (rare)

**Security Considerations:**
- ⚠️ Container can see all host network interfaces
- ⚠️ Must secure with capabilities instead of network isolation
- ⚠️ Prefer specific capabilities over `--privileged`

**Configuration:**
```nix
virtualisation.oci-containers.containers = {
  doplarr = {
    extraOptions = ["--network=host"];
    # No port mapping needed - uses host network directly
  };
};
```

### 3. **Custom Networks** (Legacy - Not Used)
- Media network, frontend network (legacy container setup)
- Native services don't require custom networks

## Port Allocation Strategy

### Standard Port Ranges

| Service Category | Port Range | Examples |
|-----------------|------------|----------|
| Web Dashboards  | 7000-8000  | Homarr (7575), OpenWebUI (7000) |
| Media Services  | 8000-9000  | Jellyfin (8096), Prowlarr (9696) |
| Databases       | 5432, 5433 | PostgreSQL (Cal.com) |
| AI/ML Services  | 8188, 11434 | ComfyUI (8188), Ollama (11434) |

### Firewall Configuration

Containers use explicit port mappings that integrate with NixOS firewall:

```nix
networking.firewall = {
  allowedTCPPorts = [
    7575  # Homarr
    5690  # Wizarr
    # Additional ports as needed
  ];
};
```

## Container-to-Container Communication

### Same Host Communication

**Preferred Method: Service Discovery via DNS**

Containers can communicate using container names:
```bash
# From cal.com container
curl http://calcom-db:5432  # PostgreSQL database

# From doplarr container  
curl http://localhost:8989  # Sonarr (host network mode)
```

**Configuration:**
```nix
virtualisation.podman = {
  enable = true;
  defaultNetwork.settings.dns_enabled = true;  # Enable DNS resolution
};

virtualisation.oci-containers.containers = {
  calcom = {
    environment = {
      DATABASE_URL = "postgresql://calcom:password@calcom-db:5432/calcom";
      #                                              ^^^^^^^^^ Container name as hostname
    };
    dependsOn = ["calcom-db"];  # Ensures database starts first
  };
};
```

## Security Best Practices

### ✅ DO: Use Default Bridge Network
```nix
# Good: Explicit port mapping, isolated network
homarr = {
  ports = ["7575:7575"];
};
```

### ✅ DO: Limit Capabilities Instead of --privileged
```nix
# Good: Specific capabilities only
music-assistant = {
  extraOptions = [
    "--cap-add=NET_ADMIN"
    "--cap-add=NET_RAW"
  ];
};
```

### ❌ DON'T: Use --privileged
```nix
# Bad: Full root access to host
container = {
  extraOptions = ["--privileged"];  # NEVER DO THIS
};
```

### ❌ DON'T: Use Host Network Unless Necessary
```nix
# Bad: Unnecessary host network access
container = {
  extraOptions = ["--network=host"];  # Only if absolutely required
};
```

## Troubleshooting

### Container Can't Reach Other Containers

**Check DNS resolution is enabled:**
```nix
virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
```

**Verify containers are on same network:**
```bash
podman network inspect podman
```

### Port Conflicts

**Check for port conflicts:**
```bash
ss -tlnp | grep :7575  # Check if port is in use
```

**Use unique ports for each service:**
```nix
# Assign different external ports if needed
ports = ["7576:7575"];  # Map host port 7576 to container port 7575
```

### Performance Issues with Bridge Network

**Rarely needed, but if required:**
- Use `--network=host` for performance-critical services
- Document the security trade-off
- Add additional hardening (capabilities, seccomp profiles)

## Migration from Legacy Networks

This configuration previously used custom Podman networks (`media`, `frontend`). These have been replaced with:

1. **Native NixOS services** - No container networking needed
2. **Default bridge network** - For remaining containers
3. **Host network** - Only for special cases (multicast, etc.)

**Benefits of Current Approach:**
- Simpler configuration
- Better NixOS integration
- Easier to reason about security boundaries
- Consistent with NixOS native services

## References

- [Podman Networking Documentation](https://docs.podman.io/en/latest/markdown/podman-network.1.html)
- [Container Security Best Practices](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [NixOS Podman Module](https://search.nixos.org/options?channel=unstable&query=virtualisation.podman)
