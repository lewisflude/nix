# How to Test Container Services - Quick Reference

## 🎯 Simplest Test (2 minutes)

```bash
# 1. Enable test mode in hosts/jupiter/default.nix
containers = {
  enable = true;
  test.enable = true;
  mediaManagement.enable = false;
  productivity.enable = false;
};

# 2. Rebuild
cd ~/.config/nix && sudo nixos-rebuild switch --flake .#jupiter

# 3. Verify
podman ps
curl http://localhost:8888

# 4. Run test script
./scripts/containers/test-containers.sh
```

**✅ If you see "NixOS Container Test Works!" - your setup is correct!**

---

## 📚 Full Testing Documentation

Detailed testing guides are available:

1. **`TESTING-GUIDE.md`** - Complete step-by-step testing procedures
2. **`TEST-CONTAINERS.md`** - In-depth test phases and troubleshooting
3. **`scripts/containers/test-containers.sh`** - Automated test script

---

## 🚀 Ready to Use for Real?

Once tests pass, enable the actual services:

```nix
# In hosts/jupiter/default.nix
containers = {
  enable = true;
  test.enable = false;  # Turn off test mode
  
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
```

Then rebuild:

```bash
sudo nixos-rebuild switch --flake .#jupiter
```

---

## 🔍 Quick Health Check

After enabling services, verify they're working:

```bash
# See all running containers
podman ps

# Count running services
systemctl list-units 'podman-*' | grep running | wc -l

# Test key services
curl http://localhost:9696  # Prowlarr
curl http://localhost:7878  # Radarr
curl http://localhost:8989  # Sonarr
curl http://localhost:8096  # Jellyfin

# Run comprehensive test
./scripts/containers/test-containers.sh
```

---

## 📖 Documentation Index

- **`HOW-TO-TEST.md`** ← You are here (quick reference)
- **`TESTING-GUIDE.md`** - Step-by-step testing
- **`TEST-CONTAINERS.md`** - Detailed test procedures
- **`CONTAINERS-QUICKSTART.md`** - Getting started guide
- **`docs/CONTAINERS-SETUP.md`** - Complete setup documentation
- **`modules/nixos/services/containers/README.md`** - Module reference
- **`modules/nixos/services/containers/MIGRATION.md`** - Migration guide

---

That's it! Start with the simple test, and if it works, you're ready to enable everything. 🎉
