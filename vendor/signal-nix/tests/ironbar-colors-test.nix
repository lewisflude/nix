# Test ironbar color exposure
{
  pkgs ? import <nixpkgs> { },
}:
let
  # Import the signal-nix module
  signalModule = import ../modules/common/default.nix {
    palette = import ../lib/palette.nix;
    nix-colorizer = pkgs.lib; # Simple stub
  };

  # Create a minimal test configuration
  testConfig = pkgs.lib.evalModules {
    modules = [
      signalModule
      {
        theming.signal = {
          enable = true;
          ironbar.enable = true;
          mode = "dark";
        };
      }
    ];
  };

  # Extract the colors
  ironbarColors = testConfig.config.theming.signal.colors.ironbar or null;
in
{
  # Test outputs
  inherit testConfig;
  cssFile = ironbarColors.cssFile or "NOT FOUND";
  tokens = ironbarColors.tokens or "NOT FOUND";

  # Check if cssFile is a valid path
  isValidPath = builtins.isPath (ironbarColors.cssFile or "");

  # Get the actual CSS content for verification
  cssContent =
    if ironbarColors != null then builtins.readFile ironbarColors.cssFile else "Colors not exposed";
}
