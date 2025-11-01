#!/usr/bin/env bash
set -euo pipefail

# Nix Store Cleanup Script
# Removes old/unused package versions while keeping the latest versions
# Run with: sudo bash scripts/cleanup-duplicates.sh
# For non-interactive mode: NON_INTERACTIVE=1 sudo bash scripts/cleanup-duplicates.sh

# Detect non-interactive mode (set by caller or environment)
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"
if [ -t 0 ]; then
    # stdin is a terminal, interactive mode
    NON_INTERACTIVE="false"
else
    # stdin is not a terminal, non-interactive mode
    NON_INTERACTIVE="true"
fi

# Auto-detect current system if available
if [ -L /run/current-system ]; then
    CURRENT_SYSTEM=$(readlink -f /run/current-system)
else
    # Fallback: try to find it
    echo "Warning: /run/current-system not found, trying to detect..."
    CURRENT_SYSTEM=$(find /nix/store -maxdepth 1 -name "*-nixos-system-*" -type l 2>/dev/null | head -1 || echo "")
    if [ -z "$CURRENT_SYSTEM" ]; then
        echo "Error: Could not determine current system."
        echo "Please run this script on a NixOS system or set CURRENT_SYSTEM manually."
        exit 1
    fi
fi

echo "=== Nix Store Cleanup Script ==="
echo ""
echo "This script will:"
echo "1. Run garbage collection to remove truly dead paths"
echo "2. Remove specific old package versions"
echo ""
echo "Current system: $CURRENT_SYSTEM"
echo ""

# Function to check if a path is referenced by current system or user profiles
is_referenced() {
    local path="$1"
    # Check system closure
    nix-store -qR "$CURRENT_SYSTEM" 2>/dev/null | grep -q "^$path$" && return 0
    # Check user profiles
    for profile in /nix/var/nix/profiles/per-user/*/*; do
        if [ -L "$profile" ]; then
            nix-store -qR "$(readlink -f "$profile")" 2>/dev/null | grep -q "^$path$" && return 0
        fi
    done
    return 1
}

# Step 1: Garbage collection
echo "=== Step 1: Running garbage collection ==="
echo "This will remove all paths not referenced by any profile..."
echo ""

if [ "$NON_INTERACTIVE" = "true" ]; then
    echo "Running nix-store --gc (non-interactive mode)..."
    nix-store --gc 2>&1 | tail -5
    echo ""
else
    read -p "Continue with garbage collection? (yes/no): " -r
    echo
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Running nix-store --gc..."
        nix-store --gc 2>&1 | tail -5
        echo ""
    else
        echo "Skipping garbage collection."
        echo ""
    fi
fi

# Step 2: Remove specific old versions
echo "=== Step 2: Removing specific old package versions ==="
echo ""

# Collect paths to delete
PATHS_TO_DELETE=()

# LibreOffice - keep only 25.2.6.2 (wrapped version used by system)
echo "Analyzing LibreOffice..."
for path in /nix/store/*libreoffice*24.8.7.2* /nix/store/7mspwdd46kar6x9sj3pgkf9v2zzpyaq8-libreoffice-25.2.6.2 /nix/store/lnm88zzb3iqb5k3pwg8fgvx3b0750b9g-libreoffice-25.2.6.2; do
    [ -e "$path" ] || continue
    if ! is_referenced "$path"; then
        PATHS_TO_DELETE+=("$path")
        echo "  Will delete: $(basename $path)"
    else
        echo "  Keep (referenced): $(basename $path)"
    fi
done

# Ollama - keep only kxdp2kj2lz277bpzclgr62cnhz32ic91-ollama-0.12.6
echo "Analyzing Ollama..."
for path in /nix/store/*ollama-0.12.5* /nix/store/kkyw934ba0zhsskchr1jvsy9dl6jqr2x-ollama-0.12.6; do
    [ -e "$path" ] || continue
    if ! is_referenced "$path"; then
        PATHS_TO_DELETE+=("$path")
        echo "  Will delete: $(basename $path)"
    else
        echo "  Keep (referenced): $(basename $path)"
    fi
done

# NVIDIA drivers - keep only 6.6.112-rt63
echo "Analyzing NVIDIA drivers..."
for path in /nix/store/*nvidia-x11-580.95.05-6.6.101-rt59* /nix/store/*nvidia-x11-565.77-6.6.76*; do
    [ -e "$path" ] || continue
    if ! is_referenced "$path"; then
        PATHS_TO_DELETE+=("$path")
        echo "  Will delete: $(basename $path)"
    else
        echo "  Keep (referenced): $(basename $path)"
    fi
done

# LLVM/Clang - keep only 21.1.2
echo "Analyzing LLVM/Clang..."
for path in /nix/store/*clang-21.1.1-lib* /nix/store/*clang-19.1.7-lib* /nix/store/*llvm-21.1.1-lib* /nix/store/*llvm-20.1.8-lib* /nix/store/*llvm-18.1.8-lib* /nix/store/*llvm-19.1.7-lib* /nix/store/*llvm-18.1.7-lib* /nix/store/*llvm-20.1.6-lib*; do
    [ -e "$path" ] || continue
    if ! is_referenced "$path"; then
        PATHS_TO_DELETE+=("$path")
        echo "  Will delete: $(basename $path)"
    else
        echo "  Keep (referenced): $(basename $path)"
    fi
done

# OpenJDK - keep only 21.0.9+8
echo "Analyzing OpenJDK..."
for path in /nix/store/0x556ql275jkl46k6lklpyvwn5c4p244-openjdk-21.0.8+9 /nix/store/zxz5fgdkwxizvq3hyq98bwha5fifvnni-openjdk-minimal-jre-21.0.7+6 /nix/store/4s8x41xzb6p2qwd6lbhzdrddwpjmkh27-openjdk-minimal-jre-21.0.8+9; do
    [ -e "$path" ] || continue
    if ! is_referenced "$path"; then
        PATHS_TO_DELETE+=("$path")
        echo "  Will delete: $(basename $path)"
    else
        echo "  Keep (referenced): $(basename $path)"
    fi
done

# Iosevka fonts - keep only 33.3.3
echo "Analyzing Iosevka fonts..."
for path in /nix/store/kazq51c124yrcmj28nhh37664il6c208-Iosevka-33.3.1 /nix/store/k3l8d2z7g7vhrp4c2flxbvbs1hwk389i-Iosevka-33.2.5 /nix/store/j6lrwr1iznpwjrw7f55wdm83c9vrn2wm-Iosevka-33.3.2 /nix/store/6802if909gc6xz2d8yy1kl9b3zz9zx3a-Iosevka-33.2.6; do
    [ -e "$path" ] || continue
    if ! is_referenced "$path"; then
        PATHS_TO_DELETE+=("$path")
        echo "  Will delete: $(basename $path)"
    else
        echo "  Keep (referenced): $(basename $path)"
    fi
done

# cmake debug
echo "Analyzing cmake debug..."
for path in /nix/store/*cmake*debug*; do
    [ -e "$path" ] || continue
    if ! is_referenced "$path"; then
        PATHS_TO_DELETE+=("$path")
        echo "  Will delete: $(basename $path)"
    else
        echo "  Keep (referenced): $(basename $path)"
    fi
done

# Debug packages (if not needed for development)
echo "Analyzing other debug packages..."
for path in /nix/store/*-debug; do
    [ -e "$path" ] || continue
    if ! is_referenced "$path"; then
        PATHS_TO_DELETE+=("$path")
        echo "  Will delete: $(basename $path)"
    else
        echo "  Keep (referenced): $(basename $path)"
    fi
done

# Duplicate CUDA libraries
echo "Analyzing duplicate CUDA libraries..."
CUDA_LIBS=$(du -sh /nix/store/*libcublas* 2>/dev/null | sort -rh | head -3)
if [ -n "$CUDA_LIBS" ]; then
    # Keep only the first one, delete exact duplicates
    KEEP_LIB=$(echo "$CUDA_LIBS" | head -1 | awk '{print $2}')
    for path in /nix/store/*libcublas*; do
        [ -e "$path" ] || continue
        [ "$path" = "$KEEP_LIB" ] && continue
        if ! is_referenced "$path"; then
            PATHS_TO_DELETE+=("$path")
            echo "  Will delete: $(basename $path)"
        else
            echo "  Keep (referenced): $(basename $path)"
        fi
    done
fi

# Linux firmware - keep only latest
echo "Analyzing Linux firmware..."
for path in /nix/store/p3hcgmhfqi28s0ipk989557rfymzh0m8-linux-firmware-20250109-zstd; do
    [ -e "$path" ] || continue
    if ! is_referenced "$path"; then
        PATHS_TO_DELETE+=("$path")
        echo "  Will delete: $(basename $path)"
    else
        echo "  Keep (referenced): $(basename $path)"
    fi
done

# Zoom - keep only 6.6.5.5215
echo "Analyzing Zoom..."
for path in /nix/store/6h0l4clamp84rz13xyhx6g1i751zlcra-zoom-6.6.0.4410 /nix/store/xxsahv5pmfpyrfrlf3rfncqs3cr39jkp-zoom-6.4.10.2027 /nix/store/aky8mjyy7rajw33738sa9sq9ay4cvci4-zoom-6.5.3.2773; do
    [ -e "$path" ] || continue
    if ! is_referenced "$path"; then
        PATHS_TO_DELETE+=("$path")
        echo "  Will delete: $(basename $path)"
    else
        echo "  Keep (referenced): $(basename $path)"
    fi
done

# Rust - remove old versions if not referenced
echo "Analyzing Rust..."
for path in /nix/store/*rustc-1.78.0 /nix/store/*rustc-1.88.0 /nix/store/*rustc-wrapper-1.88.0-doc* /nix/store/*rust-docs-1.90*; do
    [ -e "$path" ] || continue
    if ! is_referenced "$path"; then
        PATHS_TO_DELETE+=("$path")
        echo "  Will delete: $(basename $path)"
    else
        echo "  Keep (referenced): $(basename $path)"
    fi
done

echo ""
echo "=== Summary ==="
echo "Found ${#PATHS_TO_DELETE[@]} paths to delete"
echo ""

# Calculate total size
TOTAL_SIZE=0
for path in "${PATHS_TO_DELETE[@]}"; do
    if [ -e "$path" ]; then
        SIZE=$(du -sk "$path" 2>/dev/null | cut -f1 || echo "0")
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
    fi
done
if command -v bc >/dev/null 2>&1; then
    TOTAL_SIZE_GB=$(echo "scale=2; $TOTAL_SIZE / 1024 / 1024" | bc)
else
    TOTAL_SIZE_GB=$(awk "BEGIN {printf \"%.2f\", $TOTAL_SIZE / 1024 / 1024}")
fi

echo "Estimated space to free: ${TOTAL_SIZE_GB}GB"
echo ""

if [ "$NON_INTERACTIVE" = "true" ]; then
    echo "Running in non-interactive mode (auto-confirming)..."
else
    read -p "Do you want to proceed with deletion? (yes/no): " -r
    echo
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo ""
echo "=== Deleting packages ==="
DELETED=0
FAILED=0

for path in "${PATHS_TO_DELETE[@]}"; do
    if [ -e "$path" ]; then
        echo "Deleting: $(basename $path)"
        if nix-store --delete "$path" 2>/dev/null; then
            DELETED=$((DELETED + 1))
        else
            echo "  Failed (may be referenced elsewhere)"
            FAILED=$((FAILED + 1))
        fi
    fi
done

echo ""
echo "=== Cleanup complete ==="
echo "Deleted: $DELETED packages"
echo "Failed: $FAILED packages"
echo ""
echo "Running final garbage collection..."
nix-store --gc

echo ""
echo "Optimizing store..."
nix-store --optimise

echo ""
echo "=== Final store size ==="
du -sh /nix/store
