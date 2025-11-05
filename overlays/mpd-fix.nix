# Fix for MPD build issue with io_uring on kernel 6.14.11
# io_uring causes build failures, so we disable it
#
# PERFORMANCE NOTE (Tip 10): This overlay modifies core package build flags,
# causing cache misses and forcing local rebuilds. This is an acceptable
# trade-off for fixing build failures on kernel 6.14.11.
_final: prev: {
  mpd = prev.mpd.overrideAttrs (old: {
    mesonFlags = (old.mesonFlags or []) ++ ["-Dio_uring=disabled"];
  });
}
