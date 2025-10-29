#!/usr/bin/env bash
# Helper script to set up Cachix on local machine
set -euo pipefail

echo "🗄️  Cachix Local Setup Helper"
echo "=============================="
echo ""

# Check if cachix is installed
if ! command -v cachix &> /dev/null; then
    echo "❌ Cachix CLI not found. Installing..."
    nix-env -iA cachix -f https://cachix.org/api/v1/install
    echo "✅ Cachix installed"
fi

# Prompt for cache name
echo "📝 What is your Cachix cache name?"
echo "   (You created this at app.cachix.org)"
read -p "Cache name: " CACHE_NAME

if [ -z "$CACHE_NAME" ]; then
    echo "❌ Cache name cannot be empty"
    exit 1
fi

echo ""
echo "🔧 Configuring Cachix..."
cachix use "$CACHE_NAME"

echo ""
echo "✅ Cachix configured locally!"
echo ""
echo "📝 Next steps:"
echo "   1. Update your flake.nix with your cache URL and public key"
echo "   2. See docs/CACHIX_FLAKEHUB_SETUP.md for detailed instructions"
echo "   3. Add GitHub secrets (CACHIX_CACHE_NAME and CACHIX_AUTH_TOKEN)"
echo "   4. Run the 'Build and Cache' workflow on GitHub"
echo ""
echo "🧪 Test it out:"
echo "   nh os switch  # or: darwin-rebuild switch --flake ."
echo "   Look for: copying path from 'https://$CACHE_NAME.cachix.org'"
