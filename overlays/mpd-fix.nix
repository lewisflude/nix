# Fix for MPD build issue with io_uring on kernel 6.14.11
#
# PURPOSE:
# MPD (Music Player Daemon) fails to build on kernel 6.14.11 when io_uring is enabled.
# This overlay disables io_uring support to allow MPD to build successfully.
#
# TECHNICAL DETAILS:
# - Adds `-Dio_uring=disabled` to mesonFlags during MPD build
# - io_uring is a Linux async I/O interface that can improve performance but is
#   causing build failures in this specific kernel version
# - Disabling io_uring doesn't significantly impact MPD functionality for most use cases
#
# PERFORMANCE NOTE (Tip 10):
# This overlay modifies core package build flags, causing cache misses and forcing
# local rebuilds of MPD and any packages that depend on it. This is an acceptable
# trade-off for fixing build failures on kernel 6.14.11.
#
# REMOVAL CONDITIONS:
# This overlay can be removed when:
# 1. MPD upstream fixes the io_uring compatibility issue with kernel 6.14.11+, OR
# 2. nixpkgs includes the fix upstream, OR
# 3. Kernel version is downgraded below 6.14.11 (not recommended)
#
# TESTING: To verify if this overlay is still needed:
# 1. Comment out this overlay in overlays/default.nix
# 2. Run: nix build -f '<nixpkgs>' mpd
# 3. If build succeeds without io_uring errors, overlay can be removed
# 4. If build fails with io_uring-related errors, keep overlay
#
# STATUS: Active - Required for kernel 6.14.11 compatibility
_final: prev: {
  mpd = prev.mpd.overrideAttrs (old: {
    # Disable io_uring to fix build on kernel 6.14.11
    mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dio_uring=disabled" ];
  });
}
