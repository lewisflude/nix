# Backward compatibility shim for imports
# Maintains compatibility with existing system configurations that import:
#   modules/shared/features/theming/applications/desktop/ironbar-home.nix
#
# This allows gradual migration to the direct import:
#   modules/shared/features/theming/applications/desktop/ironbar-home/default.nix
#
# Can be removed once all system configs are updated.
import ./ironbar-home/default.nix
