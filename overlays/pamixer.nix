# Fix pamixer compilation with newer ICU
# ICU 76.1+ requires C++17 for std::u16string_view and other features
#
# PERFORMANCE NOTE (Tip 10): This overlay modifies core package build flags,
# causing cache misses and forcing local rebuilds. This is an acceptable
# trade-off for compatibility with newer ICU versions.
#
# REMOVAL CONDITIONS:
# This overlay can be removed when:
# 1. nixpkgs version includes pamixer built with C++17 support by default, OR
# 2. nixpkgs version includes ICU < 76.1 (unlikely, as ICU versions are increasing), OR
# 3. pamixer upstream explicitly supports ICU 76.1+ without requiring C++17 flag
#
# TESTING: To verify if this overlay is still needed:
# 1. Comment out this overlay in overlays/default.nix
# 2. Run: nix build -f '<nixpkgs>' pamixer
# 3. If build succeeds without C++17 errors, overlay can be removed
# 4. If build fails with C++17/std::u16string_view errors, keep overlay
_final: prev: {
  pamixer = prev.pamixer.overrideAttrs (oldAttrs: {
    # Ensure C++17 is used for compilation
    env = (oldAttrs.env or { }) // {
      NIX_CFLAGS_COMPILE = (oldAttrs.env.NIX_CFLAGS_COMPILE or "") + " -std=c++17";
    };
  });
}
