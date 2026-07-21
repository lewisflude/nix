# Signal Design System - NMT (Nix Module Test) Test Suite
#
# This test suite uses the NMT framework (used by home-manager) to test
# actual Home Manager activation packages and generated configuration files.
#
# Unlike evaluation-only tests, NMT tests verify:
# - Actual file generation (not just evaluation)
# - Exact file content (golden file testing)
# - Activation package correctness
# - Cross-module interactions
#
# See docs/TESTING_GUIDE.md for detailed information on writing tests.

{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  nmt,
  self,
  signal-palette,
  nix-colorizer,
}:

let
  # Import the NMT test framework
  nmtLib = import nmt {
    inherit lib pkgs;
  };

  # Shared test configuration for all tests
  baseModules = [
    self.homeManagerModules.signal
    {
      # Fix impurities - prevent user environment leaking into tests
      xdg.enable = lib.mkDefault true;
      home = {
        username = "test-user";
        homeDirectory = "/home/test-user";
        stateVersion = lib.mkDefault "24.11";
      };

      # Avoid building documentation (speeds up tests)
      manual.manpages.enable = lib.mkDefault false;
      manual.html.enable = lib.mkDefault false;
      manual.json.enable = lib.mkDefault false;

      # Import test helpers
      imports = [ ./lib/test-helpers.nix ];
    }
  ];

  # Helper to scrub derivations for fast evaluation
  # This prevents building every package during tests
  scrubDerivations =
    name: value:
    if lib.isDerivation value then
      value
      // {
        outPath = "@${lib.getName value}@";
        outputs = [ "out" ];
        outputSpecified = true;
      }
    else if lib.isAttrs value then
      lib.mapAttrs scrubDerivations value
    else
      value;

  # Create a test pkgs with scrubbed derivations
  # Whitelist packages commonly needed in tests
  scrubbedPkgs =
    let
      rawPkgs = scrubDerivations "pkgs" pkgs;
    in
    rawPkgs
    // {
      inherit (pkgs)
        # Core utilities needed for tests
        coreutils
        findutils
        gnugrep
        gnused
        diffutils
        jq

        # Shell and basic tools
        bash

        # Packages commonly referenced in modules
        ;
    };

  # Create a test Home Manager configuration
  mkTest =
    name: modules:
    nmtLib.runTest {
      inherit name;
      modules = baseModules ++ modules;
      pkgs = scrubbedPkgs;
    };

  # Import all test modules
  testModules = {
    # Editors
    programs.helix = import ./modules/programs/helix { inherit lib pkgs self; };
    programs.alacritty = import ./modules/programs/alacritty { inherit lib pkgs self; };
    programs.kitty = import ./modules/programs/kitty { inherit lib pkgs self; };
    programs.bat = import ./modules/programs/bat { inherit lib pkgs self; };
    programs.fzf = import ./modules/programs/fzf { inherit lib pkgs self; };

    # Terminals
    terminals.ghostty = import ./modules/terminals/ghostty { inherit lib pkgs self; };
    terminals.foot = import ./modules/terminals/foot { inherit lib pkgs self; };
    terminals.wezterm = import ./modules/terminals/wezterm { inherit lib pkgs self; };

    # Desktop
    desktop.gtk = import ./modules/desktop/gtk { inherit lib pkgs self; };

    # Integration tests
    integration = import ./integration { inherit lib pkgs self; };
  };

in
{
  # Export all tests
  inherit (testModules.programs.helix)
    nmt-helix-basic-dark
    nmt-helix-basic-light
    nmt-helix-auto-mode
    nmt-helix-color-accuracy
    ;

  inherit (testModules.programs.alacritty)
    nmt-alacritty-basic-dark
    nmt-alacritty-basic-light
    nmt-alacritty-ansi-colors
    ;

  inherit (testModules.programs.kitty)
    nmt-kitty-basic-dark
    nmt-kitty-basic-light
    ;

  inherit (testModules.programs.bat)
    nmt-bat-basic-dark
    nmt-bat-basic-light
    ;

  inherit (testModules.programs.fzf)
    nmt-fzf-basic-dark
    nmt-fzf-basic-light
    ;

  inherit (testModules.terminals.ghostty)
    nmt-ghostty-basic-dark
    nmt-ghostty-basic-light
    nmt-ghostty-ansi-palette
    ;

  inherit (testModules.terminals.foot)
    nmt-foot-basic-dark
    nmt-foot-basic-light
    ;

  inherit (testModules.terminals.wezterm)
    nmt-wezterm-basic-dark
    nmt-wezterm-basic-light
    ;

  inherit (testModules.desktop.gtk)
    nmt-gtk-basic-dark
    nmt-gtk-basic-light
    nmt-gtk-adwaita-palette
    ;

  inherit (testModules.integration)
    nmt-integration-multi-module
    nmt-integration-auto-enable
    nmt-integration-color-consistency
    ;
}
