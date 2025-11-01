# Nix Store Dependency Analysis

**Total Store Size:** ~62GB
**Analysis Date:** $(date)

## Top 50 Largest Packages

Based on analysis of `/nix/store`, here are the largest dependencies:

### 1. Media Management Services (~826MB)

- **jellyseerr-2.7.3**: 826MB - Media request management platform

### 2. Linux Firmware (~1.1GB total)

- **linux-firmware-20251021-zstd**: 718MB
- **linux-firmware-20250109-zstd**: 402MB

### 3. LibreOffice (~1.7GB total)

- **libreoffice-25.2.6.2**: 695MB (main) + 359MB (variant)
- **libreoffice-24.8.7.2**: 659MB

### 4. NVIDIA CUDA Libraries (~1.3GB)

- **libcublas-12.8.4.1-lib**: 672MB (duplicate entries)

### 5. Ollama AI Runtime (~1.8GB total)

- **ollama-0.12.6**: 603MB + 599MB (variants)
- **ollama-0.12.5**: 571MB

### 6. Nerd Fonts (~1.6GB total)

- **nerd-fonts-iosevka**: 501MB
- **Iosevka-33.3.1**: 228MB
- **Iosevka-33.3.2**: 227MB
- **Iosevka-33.3.3**: 227MB
- **Iosevka-33.2.5**: 227MB
- **Iosevka-33.2.6**: 227MB

### 7. Java Runtime (~920MB total)

- **openjdk-21.0.9+8**: 456MB
- **openjdk-21.0.8+9**: 464MB

### 8. Zoom (~1GB total)

- **zoom-6.6.0.4410**: 461MB
- **zoom-6.4.10.2027**: 354MB
- **zoom-6.5.3.2773**: 224MB

### 9. NVIDIA Drivers (~1.2GB total)

- **nvidia-x11-580.95.05-6.6.101-rt59**: 440MB
- **nvidia-x11-580.95.05-6.6.112-rt63**: 378MB
- **nvidia-x11-565.77-6.6.76**: 352MB

### 10. Rust Toolchain (~1.5GB total)

- **rustc-1.89.0**: 426MB
- **rustc-1.88.0**: 408MB
- **rustc-1.78.0**: 320MB
- **rustc-wrapper-1.88.0-doc**: 371MB
- **rust-docs-1.90**: 301MB

### 11. LLVM/Clang Toolchain (~1.5GB total)

- **clang-21.1.1-lib**: 254MB
- **clang-19.1.7-lib**: 254MB
- **llvm-21.1.2-lib**: 251MB
- **llvm-21.1.1-lib**: 237MB
- **llvm-20.1.8-lib**: 235MB
- **llvm-18.1.8-lib**: 219MB

### 12. Other Large Packages

- **open-webui-frontend-0.6.34**: 404MB
- **cmake-3.31.7-debug**: 454MB (debug version)
- **homeassistant-2025.10.4**: 345MB
- **chromium-unwrapped**: 265MB + 250MB = ~515MB
- **cursor**: 236MB + 229MB = ~465MB
- **papirus-icon-theme**: 283MB
- **zig-0.15.2**: 229MB
- **1password**: 311MB

## Key Issues Identified

### 1. Multiple Versions of Same Package

Many packages have multiple versions installed simultaneously:

- **LibreOffice**: 3 versions (newest + older)
- **Rust**: 3 versions (1.78, 1.88, 1.89)
- **Ollama**: 2 versions (0.12.5, 0.12.6)
- **NVIDIA drivers**: 3 versions (different kernel versions)
- **Linux firmware**: 2 versions
- **Zoom**: 3 versions
- **OpenJDK**: 2 versions
- **LLVM/Clang**: 6 versions
- **Iosevka fonts**: 6 versions
- **Chromium**: 2 versions

### 2. Debug/Development Packages

- **cmake-3.31.7-debug**: 454MB - Debug symbols version

### 3. Duplicate Entries

- **libcublas**: Appears twice with same version (possibly different build variants)

## Recommendations

### Immediate Actions (High Impact)

1. **Run Garbage Collection**

   ```bash
   sudo nix-store --gc
   sudo nix-store --optimise
   ```

2. **Remove Old Kernel Versions**
   - Keep only the current kernel version
   - Old NVIDIA drivers for removed kernels can be deleted

3. **Remove Unused Package Versions**
   - LibreOffice: Keep only latest version
   - Rust: Consider keeping only latest stable version
   - Zoom: Keep only latest version
   - OpenJDK: Keep only latest version

4. **Remove Debug Packages**
   - Remove `cmake-3.31.7-debug` if not needed for development

5. **Clean Up Font Packages**
   - Multiple Iosevka font versions: Keep only the version you use
   - Nerd fonts are large but likely needed

### Configuration Changes

1. **Review Service Configuration**
   - **Jellyseerr** (826MB): Large but likely needed for media management
   - **Ollama** (1.8GB): Multiple versions suggest updates without cleanup
   - **Home Assistant** (345MB): Large but likely needed

2. **Development Toolchains**
   - Consider using `rustup` instead of multiple rustc versions
   - Review if all LLVM versions are needed
   - Consider development shells instead of global installs

3. **Media Management**
   - Services are large but likely intentional
   - Ensure old versions are cleaned up after updates

### Long-term Optimization

1. **Use Development Shells**
   - Move development tools to `devShells` instead of global packages
   - This reduces system closure size

2. **Conditional Package Installation**
   - Only install packages when actually needed
   - Use feature flags to disable large optional dependencies

3. **Regular Cleanup**
   - Set up periodic garbage collection
   - Review large packages periodically

## Estimated Savings

If you clean up duplicate/old versions:

- **LibreOffice**: ~1GB (keep latest only)
- **Rust**: ~700MB (keep latest only)
- **Ollama**: ~600MB (keep latest only)
- **NVIDIA drivers**: ~700MB (keep current kernel only)
- **LLVM/Clang**: ~1GB (keep latest only)
- **Zoom**: ~600MB (keep latest only)
- **OpenJDK**: ~460MB (keep latest only)
- **Iosevka fonts**: ~1GB (keep one version)
- **Linux firmware**: ~400MB (keep latest only)
- **cmake debug**: ~450MB (remove if not needed)

**Total Potential Savings: ~7-8GB** (without removing essential services)

## Commands to Analyze Further

```bash
# Find all package versions
nix-store -q --references /nix/var/nix/profiles/system | xargs -I {} nix-store -q --size {}

# Check what's referencing old packages
nix-store --gc --print-dead

# Analyze closure size
nix path-info -rSh /nix/var/nix/profiles/system | sort -rn | head -50

# Use nix-du for interactive analysis
nix-du /nix/store
```
