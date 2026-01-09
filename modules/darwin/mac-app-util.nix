{
  lib,
  inputs,
  ...
}:
let
  mac-app-util = inputs.mac-app-util or null;
in
{
  # Enables mac-app-util for Nix-installed .app bundles on macOS
  # Makes apps searchable in Spotlight and allows Dock pinning
  # See: https://github.com/hraban/mac-app-util
  config = lib.mkIf (mac-app-util != null) {
    # Module loaded in lib/system-builders.nix - no configuration needed
  };
}
