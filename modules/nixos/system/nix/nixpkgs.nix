# nixpkgs configuration module
#
# PURPOSE:
# This module is intentionally minimal. Overlays and nixpkgs configuration are
# managed centrally to ensure consistency across the system.
#
# OVERLAY APPLICATION:
# Overlays are applied in lib/system-builders.nix via functionsLib.mkOverlays,
# which imports overlays/default.nix. This ensures overlays are applied before
# any modules are evaluated, so all modules receive packages with overlays
# already applied.
#
# See:
# - lib/system-builders.nix (lines 187-196 for NixOS, 120-129 for Darwin)
# - lib/functions.nix (mkOverlays function)
# - overlays/default.nix (overlay definitions)
# - docs/PERFORMANCE_TUNING.md (overlay performance impact)
#
# NIXPKGS CONFIGURATION:
# nixpkgs configuration (allowUnfree, etc.) is also managed centrally via
# functionsLib.mkPkgsConfig in lib/functions.nix and applied in the same
# location as overlays.
#
# This module is kept for potential future nixpkgs-specific configuration
# that doesn't belong in overlays or system-builders.
_: {
  # Overlays and nixpkgs config are applied in lib/system-builders.nix
  # See that file for the canonical overlay application mechanism
}
