# Node.js version alias overlay
#
# PURPOSE:
# Previously aliased nodejs to nodejs_24, but now disabled to use default nodejs.
# This overlay is kept as a no-op for potential future use.
#
# PERFORMANCE NOTE:
# This overlay is now a no-op and has no performance impact.
#
_final: _prev: {
  # Overlay disabled - using default nodejs from nixpkgs
}
