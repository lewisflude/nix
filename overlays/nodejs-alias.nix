# Node.js version alias overlay
#
# PURPOSE:
# Ensures all packages that depend on the default `nodejs` package use `nodejs_24`
# instead. This prevents conflicts when both `nodejs` (default, version 22) and
# `nodejs_24` are included in the same environment, as they both provide `corepack`
# in the same location.
#
# PERFORMANCE NOTE:
# This overlay creates an alias, so it doesn't cause cache misses. It simply
# redirects `nodejs` to `nodejs_24`.
#
# REMOVAL CONDITIONS:
# This overlay can be removed when:
# 1. nixpkgs updates the default `nodejs` to version 24, OR
# 2. All packages in the configuration explicitly use `nodejs_24` instead of `nodejs`
#
_final: prev: {
  # Alias the default nodejs to nodejs_24 to prevent version conflicts
  # This ensures all packages use the same Node.js version (24)
  nodejs = prev.nodejs_24;
}
