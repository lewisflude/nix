{ pkgs, lib, system, ... }:
let
  platformLib = import ../../lib/functions.nix { inherit lib system; };
in

pkgs.mkShell {
  buildInputs =
    with pkgs;
    [
      nodejs_24
      nodePackages_latest.pnpm
      nodePackages_latest.typescript
      nodePackages_latest.eslint
      nodePackages_latest.prettier
      nodePackages_latest.typescript-language-server
      # Mobile development tools
      watchman
      # Android tools would be system-specific
    ]
    ++ lib.optionals platformLib.isDarwin [
      # macOS-specific tools for iOS development
      cocoapods
      xcbuild
    ];

  shellHook = ''
    echo "📱 React Native development environment loaded"
    echo "Node version: $(node --version)"
    echo "React Native CLI ready"

    # Set up aliases
    alias rn="npx react-native"
    alias ios="npx react-native run-ios"
    alias android="npx react-native run-android"
    alias metro="npx react-native start"
    alias pods="cd ios && pod install && cd .."

    # Environment variables
    export REACT_NATIVE_CLI_PATH="$(which react-native)"
    export FLIPPER_DISABLE_PLUGIN_AUTO_UPDATE=1
  '';
}
