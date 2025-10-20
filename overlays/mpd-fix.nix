# Fix for MPD build issue with io_uring on kernel 6.14.11
# io_uring causes build failures, so we disable it
_final: prev: {
  mpd = prev.mpd.overrideAttrs (old: {
    mesonFlags = (old.mesonFlags or []) ++ ["-Dio_uring=disabled"];
  });
}
