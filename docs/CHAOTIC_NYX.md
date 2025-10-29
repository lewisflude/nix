# Chaotic Nyx Integration

[Chaotic Nyx](https://github.com/chaotic-cx/nyx) provides bleeding-edge packages and experimental modules for NixOS.

## 🎯 What We Use It For

- **Gaming Performance**: CachyOS kernels optimized for gaming
- **Latest Graphics**: Bleeding-edge Mesa drivers
- **Audio Production**: Latest audio tools and real-time kernels
- **Desktop Environment**: Cutting-edge Wayland/compositor updates
- **Binary Cache**: Pre-built binaries for faster rebuilds

## 📦 Available on Jupiter (NixOS)

Chaotic Nyx is only enabled for NixOS hosts. Your macOS hosts use stable packages from nixpkgs.

## 🔧 Usage Examples

### Option 1: Enable Specific Modules (Recommended)

Add to `hosts/jupiter/configuration.nix`:

```nix
{
  # Enable bleeding-edge Mesa drivers (better gaming performance)
  chaotic.mesa-git.enable = true;

  # Use CachyOS kernel for gaming performance
  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  # Install specific bleeding-edge packages
  environment.systemPackages = with pkgs; [
    firefox_nightly  # Latest Firefox
    # More packages available - see below
  ];
}
```

### Option 2: Use Specific Packages

```nix
{
  environment.systemPackages = with pkgs; [
    # Browsers
    firefox_nightly
    chromium_git

    # Gaming
    gamescope_git
    mangohud_git

    # Desktop/Wayland
    wlroots_git
    sway_git

    # Media
    mpv_git
    ffmpeg_git

    # Development
    neovim_git
  ];
}
```

### Option 3: Test Packages Without Installing

```bash
# Try Firefox Nightly without installing
nix run github:chaotic-cx/nyx/nyxpkgs-unstable#firefox_nightly

# Run from your config (uses cache)
nix run .#legacyPackages.x86_64-linux.firefox_nightly
```

## 🎮 Gaming Optimization (Jupiter)

Perfect for your gaming setup on Jupiter:

```nix
{
  # === Gaming Kernel ===
  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  # === Optional: CachyOS with sched-ext schedulers ===
  # From kernel 6.12+, sched-ext provides better game scheduling
  services.scx = {
    enable = true;
    scheduler = "scx_rusty"; # or scx_lavd for gaming
    package = pkgs.scx_git.full; # Latest schedulers
  };

  # === Bleeding-edge Graphics ===
  chaotic.mesa-git.enable = true;

  # === Gaming Tools ===
  environment.systemPackages = with pkgs; [
    gamescope_git       # Latest Gamescope
    mangohud_git        # Performance overlay
    # Your existing gaming packages...
  ];
}
```

**Performance Benefits:**

- CachyOS kernel: Optimized for gaming/desktop workloads
- sched-ext schedulers: Better CPU scheduling for games
- mesa_git: Latest graphics optimizations
- Pre-built binaries: No compilation wait time

## 🎵 Audio Production (Jupiter)

You have audio production enabled - consider:

```nix
{
  environment.systemPackages = with pkgs; [
    ardour_git      # Latest DAW features
    carla_git       # Plugin host
    # Add more as needed
  ];
}
```

## 📋 Popular Packages Available

### Desktop/Wayland

- `sway_git` - Tiling Wayland compositor
- `wlroots_git` - Wayland compositor library
- `waybar_git` - Status bar
- `swww_git` - Wallpaper daemon
- `hyprland_git` - Dynamic tiling compositor

### Gaming

- `gamescope_git` - Gaming micro-compositor
- `mangohud_git` - Performance overlay
- `obs-studio_git` - Streaming/recording

### Browsers

- `firefox_nightly` - Firefox bleeding-edge
- `chromium_git` - Chromium latest

### Media

- `mpv_git` - Media player
- `ffmpeg_git` - Video processing

### Development

- `neovim_git` - Latest Neovim
- `zellij_git` - Terminal multiplexer

### System

- `linux_cachyos` - Gaming-optimized kernel
- `linux_cachyos-lto` - LTO-optimized kernel
- `linux_cachyos-hardened` - Hardened kernel
- `scx_git` - sched-ext schedulers

## 🎯 Kernel Options

```nix
{
  # Standard CachyOS kernel (recommended)
  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  # OR: Hardened variant
  boot.kernelPackages = pkgs.linuxPackages_cachyos-hardened;

  # OR: LTO-optimized (LLVM/Clang, may have issues with some modules)
  boot.kernelPackages = pkgs.linuxPackages_cachyos-lto;

  # OR: Release candidate (not cached, will build locally)
  boot.kernelPackages = pkgs.linuxPackages_cachyos-rc;
}
```

### Microarchitecture Optimization (Advanced)

For even more performance (not cached, builds locally):

```nix
{
  boot.kernelPackages = pkgs.linuxPackages_cachyos.cachyOverride {
    mArch = "GENERIC_V4";  # or GENERIC_V2, GENERIC_V3, ZEN4
  };
}
```

## ⚠️ Important Notes

### Cache Compatibility

**DO NOT** add `inputs.nixpkgs.follows = "nixpkgs"` to the chaotic input!

```nix
# ❌ WRONG - Breaks cache
chaotic = {
  url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  inputs.nixpkgs.follows = "nixpkgs";
};

# ✅ CORRECT - Uses cache
chaotic = {
  url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  # No follows - this is intentional!
};
```

### Stability

- **Production systems**: Stick to stable packages
- **Gaming/Desktop**: CachyOS kernel + mesa-git is well-tested
- **Experimental features**: Test before relying on them

### Binary Cache

The cache is automatically configured in `flake.nix`:

- URL: `https://chaotic-nyx.cachix.org`
- Key: `chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8=`

## 🔍 Finding More Packages

```bash
# Search available packages
nix search github:chaotic-cx/nyx/nyxpkgs-unstable

# List all Chaotic packages
nix eval github:chaotic-cx/nyx/nyxpkgs-unstable#legacyPackages.x86_64-linux --apply builtins.attrNames

# Check package details
nix eval github:chaotic-cx/nyx/nyxpkgs-unstable#firefox_nightly.meta.description
```

## 📚 Resources

- **Official Docs**: <https://www.nyx.chaotic.cx/>
- **GitHub**: <https://github.com/chaotic-cx/nyx>
- **Package List**: <https://www.nyx.chaotic.cx/#lists-of-options-and-packages>
- **Telegram News**: <https://t.me/s/chaotic_nyx>
- **Support**:
  - GitHub Issues: <https://github.com/chaotic-cx/nyx/issues>
  - Matrix: `#chaotic-nyx:ubiquelambda.dev`
  - Telegram: <https://t.me/chaotic_nyx_sac>

## 🚀 Next Steps

1. **Update flake**: `nix flake update` (to fetch chaotic-nyx)
2. **Test a package**: `nix run .#legacyPackages.x86_64-linux.firefox_nightly`
3. **Enable features**: Add options to `hosts/jupiter/configuration.nix`
4. **Rebuild**: Follow your usual rebuild process (don't forget - I can't run rebuild for you!)

## 🎮 Recommended Setup for Jupiter

Based on your configuration (gaming + audio + media server):

```nix
{
  # Gaming-optimized kernel
  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  # Better game scheduling (6.12+ kernels)
  services.scx = {
    enable = true;
    scheduler = "scx_rusty";
  };

  # Bleeding-edge graphics for gaming
  chaotic.mesa-git.enable = true;

  # Optional: Latest gaming tools
  environment.systemPackages = with pkgs; [
    gamescope_git
    mangohud_git
  ];
}
```

This gives you:

- ✅ Better gaming performance
- ✅ Latest graphics drivers
- ✅ Pre-built binaries (no waiting)
- ✅ Stable enough for daily use
