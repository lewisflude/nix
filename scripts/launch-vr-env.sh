#!/usr/bin/env bash
# Launch VR Development Environment with Correct Exports

echo "🕶️ Launching VR Environment..."
echo "This will start a new shell with the correct OpenGL/OpenXR environment variables."
echo ""

# Check if we are inside a flake repo
if [ -f "flake.nix" ]; then
    nix develop .#vr
else
    echo "❌ Error: flake.nix not found in current directory."
    exit 1
fi
