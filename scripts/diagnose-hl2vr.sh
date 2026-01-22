#!/usr/bin/env bash
# Half Life 2 VR Setup Diagnostic Script
# Checks all requirements for HL2VR to work on NixOS

set -e

echo "========================================="
echo "Half Life 2 VR Diagnostic"
echo "========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

has_errors=0
has_warnings=0

echo "1. Checking Graphics Drivers..."
echo "-----------------------------------"

# Check if 32-bit graphics support is enabled
if nix eval --raw nixosConfigurations.jupiter.config.hardware.graphics.enable32Bit 2>/dev/null | grep -q "true"; then
    check_pass "32-bit graphics drivers enabled"
else
    check_fail "32-bit graphics drivers NOT enabled"
    echo "   Fix: Ensure hardware.graphics.enable32Bit = true"
    has_errors=1
fi

# Check NVIDIA driver
if lsmod | grep -q nvidia; then
    check_pass "NVIDIA driver loaded"
    nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || check_warn "nvidia-smi not available"
else
    check_warn "NVIDIA driver not detected"
fi

echo ""
echo "2. Checking VR Runtime..."
echo "-----------------------------------"

# Check if WiVRn is running
if systemctl --user is-active --quiet wivrn; then
    check_pass "WiVRn service running"
    wivrn_pid=$(systemctl --user show -p MainPID --value wivrn)
    if [ "$wivrn_pid" != "0" ]; then
        check_pass "WiVRn process active (PID: $wivrn_pid)"
    fi
else
    check_warn "WiVRn service not running"
    echo "   Start with: systemctl --user start wivrn"
    has_warnings=1
fi

# Check OpenXR runtime
if [ -f "$HOME/.config/openxr/1/active_runtime.json" ]; then
    check_pass "OpenXR runtime configured"
    runtime_path=$(jq -r '.runtime.library_path' "$HOME/.config/openxr/1/active_runtime.json" 2>/dev/null || echo "unknown")
    echo "   Runtime: $runtime_path"
else
    check_fail "OpenXR runtime NOT configured"
    has_errors=1
fi

echo ""
echo "3. Checking Steam & SteamVR..."
echo "-----------------------------------"

# Check if Steam is installed
if command -v steam &> /dev/null; then
    check_pass "Steam installed"
else
    check_fail "Steam NOT installed"
    echo "   Fix: Enable features.gaming.steam = true"
    has_errors=1
fi

# Check if SteamVR is installed
if [ -d "$HOME/.local/share/Steam/steamapps/common/SteamVR" ]; then
    check_pass "SteamVR installed"
else
    check_warn "SteamVR NOT installed"
    echo "   Install via Steam Library → Tools → SteamVR"
    has_warnings=1
fi

# Check if Half-Life 2 is owned
if [ -d "$HOME/.local/share/Steam/steamapps/common/Half-Life 2" ]; then
    check_pass "Half-Life 2 base game installed"
else
    check_warn "Half-Life 2 NOT installed"
    echo "   You must own and install Half-Life 2 from Steam"
    has_warnings=1
fi

# Check if HL2VR mod is installed
if [ -d "$HOME/.local/share/Steam/steamapps/common/hlvr" ]; then
    check_pass "Half-Life 2: VR Mod installed"
else
    check_warn "Half-Life 2: VR Mod NOT installed"
    echo "   Install 'Half-Life 2: VR Mod' from Steam"
    has_warnings=1
fi

echo ""
echo "4. Checking 32-bit Support..."
echo "-----------------------------------"

# This is the critical check for HL2VR
check_warn "WiVRn does NOT support 32-bit games"
echo "   Half-Life 2 VR is a 32-bit application"
echo "   You MUST use SteamVR for this game"
echo ""
echo "   Solution: Use SteamVR as the OpenVR runtime for HL2VR"
echo "   - WiVRn will still stream to your headset"
echo "   - But SteamVR handles the 32-bit game execution"

# Check if SteamVR feature is enabled
if nix eval --raw nixosConfigurations.jupiter.config.host.features.vr.steamvr 2>/dev/null | grep -q "true"; then
    check_pass "SteamVR feature enabled in config"
else
    check_fail "SteamVR feature NOT enabled"
    echo "   Fix: Set features.vr.steamvr = true in hosts/jupiter/default.nix"
    has_errors=1
fi

echo ""
echo "5. Checking Launch Options..."
echo "-----------------------------------"

echo "For Half-Life 2: VR Mod, you need these launch options:"
echo ""
echo "In Steam → Right-click game → Properties → Launch Options:"
echo ""
echo "    %command%"
echo ""
echo "That's it! Do NOT add PRESSURE_VESSEL or xrizer options."
echo "SteamVR will handle everything for 32-bit games."

echo ""
echo "========================================="
echo "Summary"
echo "========================================="

if [ $has_errors -eq 0 ] && [ $has_warnings -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "You should be ready to play Half-Life 2 VR."
    echo ""
    echo "Quick start:"
    echo "1. Connect your Quest headset to WiVRn"
    echo "2. Launch SteamVR from Steam"
    echo "3. Launch 'Half-Life 2: VR Mod' from Steam"
elif [ $has_errors -eq 0 ]; then
    echo -e "${YELLOW}⚠ Some warnings found${NC}"
    echo "Review warnings above and install missing components."
else
    echo -e "${RED}✗ Configuration issues detected${NC}"
    echo "Fix the errors above before attempting to play."
    exit 1
fi

echo ""
echo "========================================="
echo "How HL2VR Works on Your System"
echo "========================================="
echo ""
echo "1. WiVRn streams display to Quest 3 (wireless)"
echo "2. SteamVR handles 32-bit game execution"
echo "3. WiVRn receives frames from SteamVR"
echo "4. Everything works seamlessly!"
echo ""
echo "This hybrid approach solves the 32-bit limitation."
