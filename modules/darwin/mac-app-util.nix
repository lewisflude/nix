{
  lib,
  inputs,
  ...
}:
let
  mac-app-util = inputs.mac-app-util or null;
in
{
  # mac-app-util: Utilities for Mac App launchers
  #
  # This module automatically handles Nix-installed .app bundles on macOS:
  #
  # Features:
  # - Creates trampoline launchers for Nix-installed .app bundles
  # - Makes Nix apps searchable in Spotlight (?+Space)
  # - Allows Dock pinning that persists across Nix updates
  # - Handles apps installed via both nix-darwin and home-manager
  #
  # How it works:
  # The module runs automatically on each darwin-rebuild switch and scans
  # for .app bundles in the Nix store, creating launchers in ~/Applications/
  #
  # Apps that benefit from this:
  # - Cursor (via programs.vscode with pkgs.cursor.cursor)
  # - Zed Editor (via programs.zed-editor)
  # - Any other Nix package that provides a /Applications/*.app bundle
  #
  # See: https://github.com/hraban/mac-app-util
  config = lib.mkIf (mac-app-util != null) {
    # Note: The actual mac-app-util module is loaded in lib/system-builders.nix:
    # - nix-darwin module: mac-app-util.darwinModules.default
    # - home-manager module: mac-app-util.homeManagerModules.default
    #
    # Currently, mac-app-util works with zero configuration - just loading
    # the module is sufficient. It automatically:
    # - Scans home.packages for .app bundles
    # - Creates trampolines in ~/Applications/
    # - Updates Spotlight indexing
    # - Syncs Dock references when apps move locations
    #
    # Future configuration options (if mac-app-util adds them) can be added here.
  };
}
