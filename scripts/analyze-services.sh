#!/usr/bin/env bash
set -euo pipefail

# Nix Store Service Usage Analyzer
# Helps identify which services are actually being used vs configured

echo "=== Nix Store Service Usage Analyzer ==="
echo ""
echo "Analyzing your system to identify optimization opportunities..."
echo ""

# Check running services
echo "=== Currently Running Services ==="
RUNNING_SERVICES=$(systemctl list-units --type=service --state=running --no-pager --no-legend 2>/dev/null | awk '{print $1}' | sed 's/\.service$//' || echo "")

# Check configured services
echo ""
echo "=== Configured Services (from your config) ==="

# Large services to check
declare -A SERVICES=(
    ["jellyseerr"]="826MB"
    ["jellyfin"]="~500MB"
    ["ollama"]="~1.8GB"
    ["open-webui"]="404MB"
    ["calcom"]="~300MB"
    ["home-assistant"]="345MB"
    ["radarr"]="~100MB"
    ["sonarr"]="~100MB"
    ["lidarr"]="~100MB"
    ["readarr"]="~100MB"
    ["prowlarr"]="~100MB"
    ["sabnzbd"]="~100MB"
)

# Check each service
USED_SERVICES=()
UNUSED_SERVICES=()
TOTAL_POTENTIAL_SAVINGS=0

for service in "${!SERVICES[@]}"; do
    size="${SERVICES[$service]}"
    if echo "$RUNNING_SERVICES" | grep -qi "$service"; then
        USED_SERVICES+=("$service ($size)")
        echo "  ✅ $service - RUNNING ($size)"
    else
        # Check if service exists but is stopped
        if systemctl list-unit-files --type=service 2>/dev/null | grep -q "$service"; then
            UNUSED_SERVICES+=("$service ($size)")
            echo "  ⚠️  $service - CONFIGURED but NOT RUNNING ($size)"
            # Extract number from size
            if [[ $size =~ ([0-9]+) ]]; then
                num="${BASH_REMATCH[1]}"
                if [[ $size =~ GB ]]; then
                    TOTAL_POTENTIAL_SAVINGS=$((TOTAL_POTENTIAL_SAVINGS + num * 1024))
                elif [[ $size =~ MB ]]; then
                    TOTAL_POTENTIAL_SAVINGS=$((TOTAL_POTENTIAL_SAVINGS + num))
                fi
            fi
        else
            echo "  ❌ $service - NOT CONFIGURED"
        fi
    fi
done

echo ""
echo "=== Service Status Summary ==="
echo "✅ Running services: ${#USED_SERVICES[@]}"
echo "⚠️  Configured but not running: ${#UNUSED_SERVICES[@]}"

if [ ${#UNUSED_SERVICES[@]} -gt 0 ]; then
    echo ""
    echo "Services you could disable to save space:"
    for service in "${UNUSED_SERVICES[@]}"; do
        echo "  - $service"
    done
    echo ""
    echo "Estimated potential savings: ~$((TOTAL_POTENTIAL_SAVINGS / 1024))GB"
fi

# Check for large packages
echo ""
echo "=== Large Packages Analysis ==="
echo "Checking for large packages that might be optional..."

LARGE_PACKAGES=$(du -sh /nix/store/*/ 2>/dev/null | sort -rh | head -20)

echo ""
echo "Top 20 largest packages in store:"
while IFS= read -r line; do
    size=$(echo "$line" | awk '{print $1}')
    name=$(echo "$line" | awk '{print $2}' | sed 's|/nix/store/||' | sed 's|/$||')

    # Check if it's referenced
    if [ -L /run/current-system ]; then
        CURRENT_SYSTEM=$(readlink -f /run/current-system)
        if nix-store -qR "$CURRENT_SYSTEM" 2>/dev/null | grep -q "^/nix/store/.*$name"; then
            echo "  📦 $size - $name (in use)"
        else
            echo "  🗑️  $size - $name (possibly unused)"
        fi
    else
        echo "  📦 $size - $name"
    fi
done <<< "$LARGE_PACKAGES"

# Check for LibreOffice
echo ""
echo "=== LibreOffice Analysis ==="
LIBREOFFICE_VERSIONS=$(du -sh /nix/store/*libreoffice* 2>/dev/null | wc -l)
if [ "$LIBREOFFICE_VERSIONS" -gt 1 ]; then
    echo "Found $LIBREOFFICE_VERSIONS LibreOffice installations"
    du -sh /nix/store/*libreoffice* 2>/dev/null | grep -E "(libreoffice-[0-9])" | head -5
    echo ""
    echo "💡 Tip: If you don't use LibreOffice, disable it:"
    echo "   productivity.office = false;"
else
    echo "✅ Only one LibreOffice version found"
fi

# Check for Ollama
echo ""
echo "=== Ollama Analysis ==="
OLLAMA_VERSIONS=$(du -sh /nix/store/*ollama* 2>/dev/null | grep -E "ollama-[0-9]" | wc -l)
if [ "$OLLAMA_VERSIONS" -gt 1 ]; then
    echo "Found $OLLAMA_VERSIONS Ollama versions"
    du -sh /nix/store/*ollama* 2>/dev/null | grep -E "ollama-[0-9]" | head -5
    echo ""
    if ! echo "$RUNNING_SERVICES" | grep -qi "ollama"; then
        echo "⚠️  Ollama is NOT running!"
        echo "💡 Tip: Disable it to save ~1.8GB:"
        echo "   aiTools.enable = false;"
    else
        echo "✅ Ollama is running (but has multiple versions)"
    fi
else
    echo "✅ Only one Ollama version found"
fi

# Check for development tools
echo ""
echo "=== Development Tools Analysis ==="
RUST_VERSIONS=$(du -sh /nix/store/*rustc* 2>/dev/null | grep -E "rustc-[0-9]" | wc -l)
if [ "$RUST_VERSIONS" -gt 1 ]; then
    echo "Found $RUST_VERSIONS Rust versions"
    echo "💡 Tip: Consider using rustup in devShells instead of global rustc"
fi

# Current store size
echo ""
echo "=== Current Store Size ==="
CURRENT_SIZE=$(du -sh /nix/store 2>/dev/null | awk '{print $1}')
echo "Current size: $CURRENT_SIZE"

# Recommendations
echo ""
echo "=== Recommendations ==="
echo ""
echo "1. ✅ Run cleanup script (already done!)"
echo "2. Review services above - disable unused ones"
echo "3. Consider disabling:"
if [ ${#UNUSED_SERVICES[@]} -gt 0 ]; then
    for service in "${UNUSED_SERVICES[@]}"; do
        echo "   - $service"
    done
fi

if ! echo "$RUNNING_SERVICES" | grep -qi "ollama"; then
    echo "   - Ollama (~1.8GB) - not running"
fi

if [ "$LIBREOFFICE_VERSIONS" -gt 0 ]; then
    echo "   - LibreOffice (~1.3GB) - if not needed"
fi

echo ""
echo "4. More aggressive GC settings:"
echo "   - Reduce GC retention to 3 days"
echo "   - Limit system generations to 5"

echo ""
echo "=== To disable a service ==="
echo "Edit hosts/jupiter/default.nix and set:"
echo "  featureName.serviceName.enable = false;"
echo ""
echo "Then rebuild:"
echo "  sudo nixos-rebuild switch --flake ~/.config/nix#jupiter"
