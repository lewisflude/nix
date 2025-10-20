# Testing Container Services

This guide provides step-by-step testing to verify the container setup works before enabling all services.

## Test Strategy

We'll test in phases:
1. **Basic Test** - Single lightweight container
2. **Network Test** - Verify Podman networks work
3. **Single Service Test** - One real media service
4. **Full Stack Test** - Enable everything

---

## Phase 1: Basic Podman Test

This tests that Podman installation and configuration works.

### 1.1 Enable Test Mode

Edit `hosts/jupiter/default.nix`:

```nix
features = {
  # ... existing features ...
  
  containers = {
    enable = true;
    test.enable = true;  # Just for testing!
    mediaManagement.enable = false;
    productivity.enable = false;
  };
};
```

### 1.2 Rebuild

```bash
cd ~/.config/nix
sudo nixos-rebuild switch --flake .#jupiter
```

**Expected output:**
- Podman gets installed
- Two test containers are created: `test-nginx` and `test-busybox`

### 1.3 Verify Podman Installation

```bash
# Check Podman is installed
podman --version

# Should show: podman version 4.x.x or higher
```

### 1.4 Verify Test Containers

```bash
# Check systemd services
systemctl list-units 'podman-*'

# Should see:
# - podman-test-nginx.service
# - podman-test-busybox.service

# Check they're running
systemctl status podman-test-nginx
systemctl status podman-test-busybox

# View with Podman
podman ps

# Should show both containers running
```

### 1.5 Test Container Functionality

```bash
# Test the nginx container
curl http://localhost:8888

# Should return: "NixOS Container Test Works!"

# Check busybox logs
podman logs test-busybox

# Should show: "Container test successful!"

# Check systemd logs
journalctl -u podman-test-nginx -n 20
journalctl -u podman-test-busybox -n 20
```

### 1.6 Test Container Management

```bash
# Restart a container
sudo systemctl restart podman-test-nginx

# Stop a container
sudo systemctl stop podman-test-nginx

# Check it stopped
podman ps -a

# Start it again
sudo systemctl start podman-test-nginx

# Verify it's back
curl http://localhost:8888
```

✅ **Phase 1 Complete** if all above works!

---

## Phase 2: Network Test

This tests that Podman networks work correctly.

### 2.1 Check Networks Created

```bash
# List Podman networks
podman network ls

# Should see:
# - podman (default)
# - media (if containers are enabled)
# - frontend (if containers are enabled)
```

### 2.2 Test Network Connectivity

```bash
# Create test containers on the media network
podman run -d --name test-alpine1 --network media alpine sleep 3600
podman run -d --name test-alpine2 --network media alpine sleep 3600

# Test connectivity between them
podman exec test-alpine1 ping -c 2 test-alpine2

# Should successfully ping!

# Test DNS resolution
podman exec test-alpine1 nslookup test-alpine2

# Cleanup
podman stop test-alpine1 test-alpine2
podman rm test-alpine1 test-alpine2
```

✅ **Phase 2 Complete** if networks and DNS work!

---

## Phase 3: Single Service Test

Test one real media service to verify the full configuration works.

### 3.1 Enable Just Prowlarr

Edit `hosts/jupiter/default.nix`:

```nix
features = {
  containers = {
    enable = true;
    test.enable = false;  # Disable test containers
    
    mediaManagement = {
      enable = true;
      dataPath = "/mnt/storage";
      configPath = "/var/lib/containers/media-management";
    };
    
    productivity.enable = false;  # Not yet
  };
};
```

But temporarily comment out all services except Prowlarr in `modules/nixos/services/containers/media-management.nix`:

```nix
# In media-management.nix, comment out all containers except:
virtualisation.oci-containers.containers = {
  prowlarr = {
    # ... keep this one
  };
  
  # Comment out the rest for now:
  # radarr = { ... };
  # sonarr = { ... };
  # etc.
};
```

### 3.2 Rebuild

```bash
sudo nixos-rebuild switch --flake .#jupiter
```

### 3.3 Verify Prowlarr

```bash
# Check service
systemctl status podman-prowlarr

# Check container
podman ps | grep prowlarr

# Check logs
journalctl -u podman-prowlarr -f

# Test web interface
curl http://localhost:9696

# Or open in browser:
# http://jupiter:9696
```

### 3.4 Check Configuration

```bash
# Verify config directory was created
ls -la /var/lib/containers/media-management/prowlarr/

# Check permissions
stat /var/lib/containers/media-management/prowlarr/

# Should be owned by UID 1000, GID 100
```

✅ **Phase 3 Complete** if Prowlarr starts and is accessible!

---

## Phase 4: Full Media Stack Test

Now enable all media services.

### 4.1 Uncomment All Services

In `modules/nixos/services/containers/media-management.nix`, uncomment all the containers.

### 4.2 Rebuild

```bash
sudo nixos-rebuild switch --flake .#jupiter
```

This will take longer as it pulls all container images.

### 4.3 Monitor Startup

```bash
# Watch services start up
watch -n 2 'systemctl list-units "podman-*" | grep running'

# Or check status of all
systemctl status 'podman-*'

# View logs of all containers
journalctl -u 'podman-*' -f
```

### 4.4 Verify All Services

```bash
# Check all containers are running
podman ps

# Count running containers
podman ps | wc -l

# Should be 19+ containers for media stack

# Test each service endpoint
curl -I http://localhost:9696  # Prowlarr
curl -I http://localhost:7878  # Radarr
curl -I http://localhost:8989  # Sonarr
curl -I http://localhost:8686  # Lidarr
curl -I http://localhost:8080  # qBittorrent
curl -I http://localhost:8082  # SABnzbd
curl -I http://localhost:8096  # Jellyfin
```

### 4.5 Check Dependencies

```bash
# Verify services started in correct order
# (dependent services should start after their dependencies)

systemctl list-dependencies podman-radarr.service
systemctl list-dependencies podman-sonarr.service
```

### 4.6 Test Health Checks

```bash
# Services with health checks should show healthy
podman inspect radarr --format='{{.State.Health.Status}}'
podman inspect sonarr --format='{{.State.Health.Status}}'

# Should show: healthy (after ~60 seconds)
```

✅ **Phase 4 Complete** if all services start and are accessible!

---

## Phase 5: Productivity Stack Test

Test GPU-enabled containers.

### 5.1 Prerequisites

```bash
# Verify NVIDIA drivers
nvidia-smi

# Should show GPU info

# Check container toolkit
nvidia-container-cli info

# Should show NVIDIA Container CLI info
```

### 5.2 Enable Productivity Stack

```nix
features = {
  containers = {
    enable = true;
    mediaManagement.enable = true;
    productivity.enable = true;  # Enable this
  };
};
```

### 5.3 Rebuild

```bash
sudo nixos-rebuild switch --flake .#jupiter
```

### 5.4 Verify GPU Containers

```bash
# Check Ollama
systemctl status podman-ollama

# Check GPU access in container
podman exec ollama nvidia-smi

# Should show GPU!

# Test Open WebUI
curl http://localhost:7000

# Test ComfyUI
curl http://localhost:8188
```

✅ **Phase 5 Complete** if GPU containers work!

---

## Quick Test Script

Here's a comprehensive test script:

```bash
#!/usr/bin/env bash
# Save as: test-containers.sh

echo "=== Testing NixOS Container Services ==="

echo -e "\n1. Testing Podman Installation..."
podman --version || echo "❌ Podman not installed"

echo -e "\n2. Checking Running Containers..."
RUNNING=$(podman ps --format "{{.Names}}" | wc -l)
echo "Running containers: $RUNNING"

echo -e "\n3. Testing Services..."
services=(
  "prowlarr:9696"
  "radarr:7878"
  "sonarr:8989"
  "jellyfin:8096"
)

for service in "${services[@]}"; do
  name="${service%%:*}"
  port="${service##*:}"
  
  if systemctl is-active --quiet "podman-$name"; then
    if curl -sf "http://localhost:$port" > /dev/null; then
      echo "✅ $name (port $port) - OK"
    else
      echo "⚠️  $name running but not responding on port $port"
    fi
  else
    echo "❌ $name - Not running"
  fi
done

echo -e "\n4. Checking Networks..."
podman network ls

echo -e "\n5. Checking GPU (if applicable)..."
if command -v nvidia-smi &> /dev/null; then
  nvidia-smi > /dev/null && echo "✅ GPU available"
else
  echo "ℹ️  No GPU configured"
fi

echo -e "\n=== Test Complete ==="
```

Run it:

```bash
chmod +x test-containers.sh
./test-containers.sh
```

---

## Troubleshooting Tests

### Container won't start

```bash
# Check service status
systemctl status podman-<service>

# View detailed logs
journalctl -u podman-<service> -n 100 --no-pager

# Check if image pulled
podman images | grep <service>

# Try pulling manually
podman pull <image-name>
```

### Permission errors

```bash
# Check directory ownership
ls -la /var/lib/containers/media-management/

# Fix if needed
sudo chown -R 1000:100 /var/lib/containers/media-management/<service>
```

### Port conflicts

```bash
# Check if port is already in use
sudo ss -tlnp | grep <port>

# If Docker is still running, stop it
docker ps
docker stop $(docker ps -q)
```

### Network issues

```bash
# Recreate networks
sudo systemctl restart podman-network-media
sudo systemctl restart podman-network-frontend

# Test connectivity
podman exec <container> ping google.com
```

---

## Cleanup Test Containers

After testing, clean up:

```bash
# Disable test mode
# Edit hosts/jupiter/default.nix and set:
# containers.test.enable = false;

# Rebuild
sudo nixos-rebuild switch --flake .#jupiter

# Or manually remove test containers
podman stop test-nginx test-busybox
podman rm test-nginx test-busybox
```

---

## Success Criteria

Your setup is working correctly if:

- ✅ Podman is installed and running
- ✅ Test containers start and respond
- ✅ Networks are created and functional
- ✅ At least one real service (Prowlarr) starts
- ✅ All media services start without errors
- ✅ Services are accessible on their ports
- ✅ GPU containers work (if using productivity stack)
- ✅ Services restart on boot
- ✅ Logs are available via journalctl

---

## Next Steps After Successful Testing

1. Configure services through their web UIs
2. Set up secrets with sops-nix
3. Stop/remove old Docker Compose setup
4. Set up backups for `/var/lib/containers`
5. Monitor resource usage

Happy testing! 🧪
