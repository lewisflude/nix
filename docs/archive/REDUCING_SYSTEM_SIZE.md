# Reducing NixOS System Size

Your NixOS system is currently ~32GB, which is unusually large. This guide identifies the major contributors and how to reduce them.

## Major Size Contributors

Based on your configuration (`hosts/jupiter/default.nix`), here are the largest packages:

### 1. **Home Assistant** (~2-4GB)

**Location**: `modules/nixos/services/home-assistant.nix`

Home Assistant is a massive Python application with many dependencies. It includes:

- Full Python runtime with many packages
- Many extra components enabled (71+ components)
- Custom components (home-llm, localtuya)

**Options to reduce**:

- Disable if not actively used
- Reduce `extraComponents` list to only what you need
- Remove unused custom components

### 2. **Steam & Gaming** (~5-10GB)

**Location**: `modules/nixos/features/gaming.nix`

Steam and gaming tools are very large:

- Steam client (~2-3GB)
- Proton/Wine (~2-3GB)
- Gamescope (~500MB)
- Mangohud, gamemode, etc.

**Options to reduce**:

- Disable if not gaming: `gaming.enable = false` in `hosts/jupiter/default.nix`
- Or disable just Steam: `gaming.steam = false`

### 3. **Media Management Stack** (~3-5GB)

**Location**: `modules/nixos/features/media-management.nix`

Multiple large services:

- Jellyfin (~500MB-1GB)
- Radarr, Sonarr, Lidarr, Readarr (~200MB each)
- qBittorrent (~300MB)
- SABnzbd (~200MB)
- Jellyseerr (~800MB)
- Navidrome (~200MB)

**Options to reduce**:

- Disable unused services individually
- Or disable entire stack: `mediaManagement.enable = false`

### 4. **Ollama with CUDA** (~2-3GB)

**Location**: `modules/nixos/services/ai-tools/ollama.nix`

Ollama with CUDA support includes:

- CUDA libraries (~1GB)
- Ollama binary (~600MB)
- CUDA toolkit dependencies

**Options to reduce**:

- Disable if not using: `aiTools.enable = false`
- Or use CPU-only: `aiTools.ollama.acceleration = null`

### 5. **Development Toolchains** (~3-5GB)

**Location**: `lib/package-sets.nix`

Multiple language toolchains:

- Rust toolchain (~1-2GB with docs)
- Python with packages (~500MB-1GB)
- Node.js (~300MB)
- Clang/LLVM (~2GB if multiple versions)
- CMake (~500MB)

**Options to reduce**:

- Remove unused languages: Set `development.rust = false`, etc.
- Use devShells instead of global toolchains
- Remove debug packages: `cmake-debug` is huge

### 6. **NVIDIA Drivers** (~1-2GB)

**Location**: `modules/nixos/features/desktop/graphics.nix`

NVIDIA drivers for multiple kernel versions:

- Current kernel driver (~500MB)
- Old kernel drivers (if not cleaned up)

**Options to reduce**:

- Already handled by cleanup script
- Only keep current kernel version

### 7. **Linux Firmware** (~500MB-1GB)

**Location**: System packages

Firmware blobs for hardware support.

**Options to reduce**:

- Use `linux-firmware-small` if you know your hardware
- Or remove old firmware versions

### 8. **LibreOffice** (~1.3GB)

**Location**: `home/common/features/productivity/default.nix`

Full office suite.

**Options to reduce**:

- Disable if not needed: `productivity.office = false`

### 9. **Chromium** (~500MB)

**Location**: `home/nixos/browser.nix`

Web browser.

**Options to reduce**:

- Use Firefox instead (smaller)
- Or use ungoogled-chromium

### 10. **Multiple Package Versions**

Old versions of packages still in store.

**Options to reduce**:

- Run cleanup script: `nix run .#cleanup-duplicates`
- Regular garbage collection: `nix-collect-garbage -d`

## Quick Wins (Estimated Savings)

1. **Disable Gaming** (if not used): **~5-10GB**
2. **Disable Home Assistant** (if not used): **~2-4GB**
3. **Disable Media Management** (if not used): **~3-5GB**
4. **Disable AI Tools** (if not used): **~2-3GB**
5. **Remove unused dev toolchains**: **~1-2GB**
6. **Run cleanup script**: **~2-5GB** (duplicates)

### Total Potential Savings

~15-29GB

## Recommended Actions

### Step 1: Identify What You Actually Use

Review your enabled features in `hosts/jupiter/default.nix`:

```nix
features = {
  gaming.enable = true;        # 5-10GB - Do you game?
  mediaManagement.enable = true; # 3-5GB - Do you use Jellyfin?
  aiTools.enable = true;      # 2-3GB - Do you use Ollama?
  productivity.office = true;  # 1.3GB - Do you use LibreOffice?
}
```

### Step 2: Disable Unused Features

Edit `hosts/jupiter/default.nix` and set unused features to `false`:

```nix
features = defaultFeatures // {
  gaming = {
    enable = false;  # Disable if not gaming
  };

  mediaManagement = {
    enable = false;  # Disable if not using media server
  };

  aiTools = {
    enable = false;  # Disable if not using AI tools
  };

  productivity = {
    office = false;  # Disable LibreOffice if not needed
  };
};
```

### Step 3: Clean Up Duplicates

Run the cleanup script:

```bash
nix run .#cleanup-duplicates -- --dry-run  # Preview
nix run .#cleanup-duplicates              # Actually clean
```

### Step 4: Use DevShells Instead of Global Tools

Move development toolchains to devShells instead of global packages:

```nix
# Instead of global rust/python/node
# Use: nix develop .#rust-dev
# Or: direnv with .envrc
```

### Step 5: Optimize Home Assistant (if keeping it)

Reduce Home Assistant components in `modules/nixos/services/home-assistant.nix`:

```nix
extraComponents = [
  # Only include what you actually use
  "default_config"
  "mqtt"
  # Remove unused components
];
```

### Step 6: Regular Maintenance

Add to your workflow:

```bash
# Weekly cleanup
nix-collect-garbage -d
nix-store --optimise

# Monthly deep cleanup
nix run .#cleanup-duplicates
```

## Size Analysis Script

To see what's actually taking space:

```bash
# Analyze current system
nix path-info -rS /run/current-system | sort -rn | head -20

# Or use the analyze script
nix run .#analyze-services
```

## Expected Results

After optimizations, a typical NixOS system should be:

- **Minimal desktop**: ~8-12GB
- **With development tools**: ~12-18GB
- **With media server**: ~15-22GB
- **With gaming**: ~20-30GB

Your current 32GB suggests multiple large services + duplicates.

## Configuration Examples

### Minimal Configuration

```nix
features = {
  development = {
    enable = true;
    rust = false;  # Use devShell instead
    python = false;  # Use devShell instead
    node = false;  # Use devShell instead
  };

  gaming.enable = false;
  mediaManagement.enable = false;
  aiTools.enable = false;
  productivity.office = false;
};
```

### Optimized Configuration

```nix
features = {
  development = {
    enable = true;
    # Only keep what you use daily
    rust = true;
    python = false;  # Use devShell when needed
  };

  gaming = {
    enable = true;
    steam = true;
    performance = false;  # Disable if not needed
  };

  mediaManagement = {
    enable = true;
    # Disable unused services
    unpackerr.enable = false;
    navidrome.enable = false;
  };
};
```
