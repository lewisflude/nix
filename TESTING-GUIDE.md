# Quick Testing Guide

Follow these steps to safely test your container configuration.

## 🧪 Option 1: Quick Test (5 minutes)

Test with minimal containers first:

### Step 1: Enable Test Mode

Edit `hosts/jupiter/default.nix`:

```nix
features = {
  containers = {
    enable = true;
    test.enable = true;  # <-- Just for testing!
    mediaManagement.enable = false;
    productivity.enable = false;
  };
};
```

### Step 2: Rebuild

```bash
cd ~/.config/nix
sudo nixos-rebuild switch --flake .#jupiter
```

### Step 3: Run Test Script

```bash
./scripts/containers/test-containers.sh
```

**Expected output:**
```
✓ Podman is installed: podman version 4.x.x
✓ Found 2 container services
✓ 2 containers are running
✓ Podman networks exist
✓ test-nginx responding on port 8888
```

### Step 4: Manual Verification

```bash
# Check containers are running
podman ps

# Test nginx container
curl http://localhost:8888
# Should return: "NixOS Container Test Works!"

# Check logs
journalctl -u podman-test-nginx -n 20
```

✅ **If this works, your Podman setup is correct!**

---

## 🎯 Option 2: Single Service Test (10 minutes)

Test one real service before enabling everything.

### Step 1: Enable Just Prowlarr

Edit `hosts/jupiter/default.nix`:

```nix
features = {
  containers = {
    enable = true;
    test.enable = false;  # Disable test mode
    
    mediaManagement = {
      enable = true;
      dataPath = "/mnt/storage";
      configPath = "/var/lib/containers/media-management";
    };
    
    productivity.enable = false;
  };
};
```

**Temporarily** edit `modules/nixos/services/containers/media-management.nix`:

Comment out all containers except Prowlarr:

```nix
virtualisation.oci-containers.containers = {
  # Keep only this one:
  prowlarr = {
    # ... leave unchanged
  };
  
  # Comment out everything else for now:
  # radarr = { ... };
  # sonarr = { ... };
  # etc.
};
```

### Step 2: Rebuild

```bash
sudo nixos-rebuild switch --flake .#jupiter
```

### Step 3: Test Prowlarr

```bash
# Wait a moment for it to start, then check
systemctl status podman-prowlarr

# Should show: active (running)

# Check it's accessible
curl http://localhost:9696

# Or open in browser:
firefox http://localhost:9696
```

### Step 4: Check Configuration

```bash
# Config directory should exist
ls -la /var/lib/containers/media-management/prowlarr/

# Check permissions (should be 1000:100)
stat /var/lib/containers/media-management/prowlarr/
```

✅ **If Prowlarr works, you can enable all services!**

---

## 🚀 Option 3: Full Stack Test (30 minutes)

Enable everything at once.

### Step 1: Enable All Services

Edit `hosts/jupiter/default.nix`:

```nix
features = {
  containers = {
    enable = true;
    
    mediaManagement = {
      enable = true;
      dataPath = "/mnt/storage";
      configPath = "/var/lib/containers/media-management";
    };
    
    productivity = {
      enable = true;
      configPath = "/var/lib/containers/productivity";
    };
  };
};
```

Make sure all services are uncommented in `media-management.nix`.

### Step 2: Rebuild

```bash
sudo nixos-rebuild switch --flake .#jupiter
```

This will take longer (5-10 minutes) to pull all images.

### Step 3: Monitor Startup

```bash
# Watch services start
watch -n 2 'systemctl list-units "podman-*" --no-pager | grep running | wc -l'

# View all container services
systemctl list-units 'podman-*'

# Follow logs
journalctl -u 'podman-*' -f
```

### Step 4: Run Comprehensive Test

```bash
./scripts/containers/test-containers.sh
```

### Step 5: Test Each Service

```bash
# Test each web interface
curl -I http://localhost:9696  # Prowlarr
curl -I http://localhost:7878  # Radarr
curl -I http://localhost:8989  # Sonarr
curl -I http://localhost:8686  # Lidarr
curl -I http://localhost:8080  # qBittorrent
curl -I http://localhost:8096  # Jellyfin
curl -I http://localhost:7000  # Open WebUI
curl -I http://localhost:8188  # ComfyUI

# Or open all in browser:
firefox \
  http://localhost:9696 \
  http://localhost:7878 \
  http://localhost:8989 \
  http://localhost:8096
```

### Step 6: Check GPU (Productivity Stack)

```bash
# Verify GPU in container
podman exec ollama nvidia-smi

# Should show your GPU!
```

✅ **If all services are accessible, you're done!**

---

## 📊 What to Look For

### ✅ Success Indicators

- `podman ps` shows all containers running
- `systemctl list-units 'podman-*'` shows all services active
- Each service responds on its port
- No error messages in `journalctl -u podman-*`
- Web interfaces are accessible

### ⚠️ Warning Signs (Usually OK)

- "Container is starting" - Give it 1-2 minutes
- "Pulling image" - First run takes time
- Health checks not passing immediately - Takes ~60 seconds

### ❌ Problems to Investigate

- "Port already in use" - Stop Docker Compose first
- "Permission denied" - Check directory ownership
- "Image not found" - Check internet connection
- "Service failed" - Check logs: `journalctl -u podman-<service>`

---

## 🔧 Quick Fixes

### Container won't start

```bash
# Check logs
journalctl -u podman-radarr -n 50

# Try restarting
sudo systemctl restart podman-radarr

# Check image exists
podman images | grep radarr
```

### Port conflict

```bash
# Find what's using the port
sudo ss -tlnp | grep 7878

# If it's Docker, stop it
docker ps
docker stop <container-id>
```

### Permission error

```bash
# Fix directory ownership
sudo chown -R 1000:100 /var/lib/containers/media-management/<service>
```

### Network issue

```bash
# Restart networks
sudo systemctl restart podman-network-media
sudo systemctl restart podman-network-frontend
```

---

## 📝 Testing Checklist

Use this checklist to verify everything:

```
Basic Setup:
[ ] Podman is installed and working
[ ] Test containers start successfully
[ ] Can access test nginx on port 8888
[ ] Networks are created (media, frontend)

Single Service:
[ ] Prowlarr service starts
[ ] Prowlarr is accessible on port 9696
[ ] Configuration directory created
[ ] Logs show no errors

Media Stack:
[ ] All 19 containers are running
[ ] Each service is accessible
[ ] Networks connect services
[ ] Health checks pass

Productivity Stack:
[ ] Ollama starts with GPU access
[ ] Open WebUI is accessible
[ ] ComfyUI is accessible
[ ] GPU is detected in containers

Final Verification:
[ ] Services survive reboot
[ ] Logs are clean
[ ] All web UIs load
[ ] Can configure services
```

---

## 🎓 After Testing

Once everything works:

1. **Configure services** through their web interfaces
2. **Stop Docker Compose** (if migrating)
3. **Set up secrets** with sops-nix
4. **Add to backups** - `/var/lib/containers`
5. **Document any custom config**

---

## 📞 Need Help?

If tests fail:

1. **Check logs**: `journalctl -u podman-<service> -n 100`
2. **Review docs**: `modules/nixos/services/containers/README.md`
3. **Test script**: `./scripts/containers/test-containers.sh`
4. **Verify config**: `nix eval '.#nixosConfigurations.jupiter.config.virtualisation.oci-containers.backend'`

---

## 🎉 Success!

If all tests pass, you have successfully:

- ✅ Converted Docker Compose to NixOS containers
- ✅ Enabled Podman with all services
- ✅ Verified everything works correctly
- ✅ Tested networks, GPU, and service communication

Your media management and productivity stacks are now running declaratively on NixOS with Podman! 🚀
