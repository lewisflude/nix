{
  pkgs,
  lib,
  system,
  ...
}:
let
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem system;
in
pkgs.mkShell {
  buildInputs =
    with pkgs;
    [
      # System provides: node, pnpm, typescript
      # Add React Native-specific tools
      watchman
    ]
    ++ lib.optionals platformLib.isDarwin [
      cocoapods
      xcbuild
    ];
  shellHook = ''
    echo "📱 React Native development environment loaded (using system Node.js)"
    echo "Node version: $(node --version)"
    echo "React Native CLI ready"
    ${lib.optionalString platformLib.isDarwin "echo \"macOS tools: CocoaPods, xcbuild\""}

    # Project-specific aliases
    alias rn="npx react-native"
    alias ios="npx react-native run-ios"
    alias android="npx react-native run-android"
    alias metro="npx react-native start"
    alias pods="cd ios && pod install && cd .."

    # React Native environment
    export REACT_NATIVE_CLI_PATH="$(which react-native)"
    export FLIPPER_DISABLE_PLUGIN_AUTO_UPDATE=1
  '';
}
