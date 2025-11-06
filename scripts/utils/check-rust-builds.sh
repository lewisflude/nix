#!/usr/bin/env bash
# Detailed analysis of what Rust packages will be built
# Usage: ./check-rust-builds.sh [hostname]

set -euo pipefail

HOST="${1:-jupiter}"
TARGET=".#nixosConfigurations.${HOST}.config.system.build.toplevel"

echo "?? Analyzing Rust Package Builds"
echo "=================================="
echo ""

# Get all derivations that will be built
echo "Getting list of derivations to build..."
TEMP_FILE=$(mktemp)
trap "rm -f '$TEMP_FILE'" EXIT

nix build --dry-run --print-build-logs "$TARGET" > "$TEMP_FILE" 2>&1 || true

# Extract the "these X derivations will be built" line
BUILD_COUNT=$(grep -oP "these \K[0-9]+ derivations will be built" "$TEMP_FILE" | head -1 || echo "0")

echo "Total derivations to build: $BUILD_COUNT"
echo ""

# Get Rust-related derivations
echo "?? Rust-related derivations that will be built:"
echo ""

# Extract derivation paths and filter for Rust-related
grep -E "\.drv$" "$TEMP_FILE" | grep -iE "(rust|cargo)" | head -30 | while read -r drv; do
  # Get the store path name
  NAME=$(basename "$drv" .drv | sed 's/-[0-9].*$//')
  echo "  - $NAME"
done

echo ""
echo "?? Summary:"
echo ""

# Count different types
RUST_TOOLCHAIN=$(grep -cE "(rustc|cargo|rustfmt|clippy).*\.drv" "$TEMP_FILE" || echo "0")
RUST_ANALYZER=$(grep -c "rust-analyzer.*\.drv" "$TEMP_FILE" || echo "0")
CARGO_TOOLS=$(grep -cE "(cargo-watch|cargo-audit|cargo-edit).*\.drv" "$TEMP_FILE" || echo "0")
RUST_CRATES=$(grep -cE "rust.*crate|\.rs\.drv" "$TEMP_FILE" || echo "0")

echo "  Rust toolchain components: $RUST_TOOLCHAIN"
echo "  rust-analyzer: $RUST_ANALYZER"
echo "  Cargo tools (watch/audit/edit): $CARGO_TOOLS"
echo "  Rust crates (dependencies): $RUST_CRATES"
echo ""

echo "?? Note:"
echo "  - rust-overlay provides pre-built rustc/cargo/rustfmt/clippy (should be substitutable)"
echo "  - rust-analyzer and cargo tools need to be built from source"
echo "  - The 600+ builds are likely from rust-analyzer and cargo tools dependencies"
