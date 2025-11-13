# This file is kept for backwards compatibility.
# The host options have been split into separate files:
# - ./host-options/core.nix - Core host options (username, hostname, etc.)
# - ./host-options/features.nix - Feature options (development, gaming, etc.)
# - ./host-options/services/media-management.nix - Media management options
# - ./host-options/services/containers-supplemental.nix - Container service options
#
# This file re-exports all the split modules for backwards compatibility.
{
  imports = [
    ./host-options/core.nix
    ./host-options/features.nix
    ./host-options/services/media-management.nix
    ./host-options/services/containers-supplemental.nix
  ];
}
