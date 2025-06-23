{ pkgs, ... }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nodejs_22
    nodePackages.pnpm
    nodePackages.typescript
    nodePackages.eslint
    nodePackages.prettier
    nodePackages."@react-native-community/cli"
    nodePackages.typescript-language-server
    # Mobile development tools
    cocoapods
    watchman
    # Android tools would be system-specific
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    # macOS-specific tools for iOS development
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