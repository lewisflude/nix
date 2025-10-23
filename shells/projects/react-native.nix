{
  pkgs,
  lib,
  system,
  ...
}: let
  platformLib = (import ../../lib/functions.nix {inherit lib;}).withSystem system;
in
  pkgs.mkShell {
    buildInputs = with pkgs;
      [
        (platformLib.getVersionedPackage pkgs platformLib.versions.nodejs)
        watchman
      ]
      ++ lib.optionals platformLib.isDarwin [
        cocoapods
        xcbuild
      ];
    shellHook = ''
      echo "📱 React Native development environment loaded"
      echo "Node version: $(node --version)"
      echo "React Native CLI ready"
      alias rn="npx react-native"
      alias ios="npx react-native run-ios"
      alias android="npx react-native run-android"
      alias metro="npx react-native start"
      alias pods="cd ios && pod install && cd .."
      export REACT_NATIVE_CLI_PATH="$(which react-native)"
      export FLIPPER_DISABLE_PLUGIN_AUTO_UPDATE=1
    '';
  }
