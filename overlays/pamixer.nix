# Fix pamixer compilation with newer ICU
# ICU 76.1 requires C++17 for std::u16string_view and other features
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
