# Fix pamixer compilation with newer ICU
# ICU 76.1 requires C++17 for std::u16string_view and other features
#
# PERFORMANCE NOTE (Tip 10): This overlay modifies core package build flags,
# causing cache misses and forcing local rebuilds. This is an acceptable
# trade-off for compatibility with newer ICU versions.
_final: prev: {
  pamixer = prev.pamixer.overrideAttrs (oldAttrs: {
    # Ensure C++17 is used for compilation
    env =
      (oldAttrs.env or {})
      // {
        NIX_CFLAGS_COMPILE = (oldAttrs.env.NIX_CFLAGS_COMPILE or "") + " -std=c++17";
      };
  });
}
