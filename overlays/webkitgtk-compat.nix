# Compatibility overlay for webkitgtk removal
#
# PURPOSE:
# webkitgtk was removed from nixpkgs and replaced with a throw. Packages should use
# versioned variants (webkitgtk_6_0, webkitgtk_6_2, etc.), but many packages haven't
# been updated yet. This overlay provides a temporary alias to maintain compatibility.
#
# PERFORMANCE NOTE (Tip 10):
# This overlay does NOT modify build flags, so it doesn't cause cache misses.
# It only provides an alias, which is a pure evaluation-time operation with no
# performance impact.
#
# REMOVAL CONDITIONS:
# This overlay can be removed when:
# 1. All packages in the configuration have been updated to use versioned webkitgtk
#    variants (webkitgtk_6_0, webkitgtk_6_2, etc.), OR
# 2. nixpkgs restores the unversioned webkitgtk alias (unlikely)
#
# TESTING: To verify if this overlay is still needed:
# 1. Comment out this overlay in overlays/default.nix
# 2. Run: nix flake check
# 3. If evaluation succeeds, overlay can be removed
# 4. If evaluation fails with "webkitgtk is a throw", overlay is still needed
#
# TECHNICAL DETAILS:
# - Uses webkitgtk_6_0 as the default version
# - This is a compatibility layer only, no build modifications
final: _prev: {
  # Override the throw with an actual package - use webkitgtk_6_0 as the default
  webkitgtk = final.webkitgtk_6_0;
}
