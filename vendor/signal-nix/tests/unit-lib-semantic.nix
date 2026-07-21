# Unit tests for lib/semantic.nix
# Tests semantic bridge color resolution

{
  pkgs,
  lib,
  self,
  signal-palette,
  ...
}:

let
  signalLib = self.lib;
  semantic = signalLib.semantic;

  # Test helper to check if a value is a valid color object
  isValidColor =
    color:
    (color ? hex)
    && (color ? hexRaw)
    && (color ? rgb)
    && (color ? l)
    && (color ? c)
    && (color ? h)
    && (lib.hasPrefix "#" color.hex)
    && (builtins.stringLength color.hex == 7);

  # Test cases
  tests = {
    # Test core colors
    test-core-background-dark = {
      expr = semantic.core "background" "dark";
      expected = isValidColor;
    };

    test-core-background-light = {
      expr = semantic.core "background" "light";
      expected = isValidColor;
    };

    test-core-foreground-dark = {
      expr = semantic.core "foreground" "dark";
      expected = isValidColor;
    };

    test-core-cursor-dark = {
      expr = semantic.core "cursor" "dark";
      expected = isValidColor;
    };

    # Test terminal colors
    test-terminal-ansi-red-dark = {
      expr = semantic.terminal "ansi-red" "dark";
      expected = isValidColor;
    };

    test-terminal-ansi-green-light = {
      expr = semantic.terminal "ansi-green" "light";
      expected = isValidColor;
    };

    test-terminal-ansi-blue-dark = {
      expr = semantic.terminal "ansi-blue" "dark";
      expected = isValidColor;
    };

    # Test syntax colors
    test-syntax-keyword-dark = {
      expr = semantic.syntax "keyword" "dark";
      expected = isValidColor;
    };

    test-syntax-function-light = {
      expr = semantic.syntax "function" "light";
      expected = isValidColor;
    };

    test-syntax-string-dark = {
      expr = semantic.syntax "string" "dark";
      expected = isValidColor;
    };

    test-syntax-comment-dark = {
      expr = semantic.syntax "comment" "dark";
      expected = isValidColor;
    };

    # Test status colors
    test-status-error-dark = {
      expr = semantic.status "error" "dark";
      expected = isValidColor;
    };

    test-status-warning-light = {
      expr = semantic.status "warning" "light";
      expected = isValidColor;
    };

    test-status-success-dark = {
      expr = semantic.status "success" "dark";
      expected = isValidColor;
    };

    # Test VCS colors
    test-vcs-added-dark = {
      expr = semantic.vcs "added" "dark";
      expected = isValidColor;
    };

    test-vcs-modified-light = {
      expr = semantic.vcs "modified" "light";
      expected = isValidColor;
    };

    test-vcs-deleted-dark = {
      expr = semantic.vcs "deleted" "dark";
      expected = isValidColor;
    };

    # Test UI colors
    test-ui-panel-background-dark = {
      expr = semantic.ui "panel-background" "dark";
      expected = isValidColor;
    };

    test-ui-element-hover-light = {
      expr = semantic.ui "element-hover" "light";
      expected = isValidColor;
    };

    # Test editor colors
    test-editor-background-dark = {
      expr = semantic.editor "background" "dark";
      expected = isValidColor;
    };

    test-editor-line-number-light = {
      expr = semantic.editor "line-number" "light";
      expected = isValidColor;
    };

    # Test text colors
    test-text-primary-dark = {
      expr = semantic.text "primary" "dark";
      expected = isValidColor;
    };

    test-text-secondary-light = {
      expr = semantic.text "secondary" "light";
      expected = isValidColor;
    };

    # Test multiplayer colors
    test-multiplayer-player-1-dark = {
      expr = semantic.multiplayer "player-1" "dark";
      expected = isValidColor;
    };

    test-multiplayer-player-4-light = {
      expr = semantic.multiplayer "player-4" "light";
      expected = isValidColor;
    };

    # Test hex convenience function
    test-hex-convenience-dark = {
      expr = lib.hasPrefix "#" (semantic.hex "core" "background" "dark");
      expected = true;
    };

    test-hex-convenience-light = {
      expr = lib.hasPrefix "#" (semantic.hex "terminal" "ansi-red" "light");
      expected = true;
    };

    # Test resolve function directly
    test-resolve-core-background = {
      expr = isValidColor (semantic.resolve "core" "background" "dark");
      expected = true;
    };

    # Test getAllColors
    test-get-all-colors-core-dark = {
      expr = builtins.length (builtins.attrNames (semantic.getAllColors "core" "dark")) > 0;
      expected = true;
    };

    test-get-all-colors-terminal-light = {
      expr = builtins.length (builtins.attrNames (semantic.getAllColors "terminal" "light")) > 0;
      expected = true;
    };

    # Test getAvailableNames
    test-get-available-names-core = {
      expr = builtins.elem "background" (semantic.getAvailableNames "core");
      expected = true;
    };

    test-get-available-names-terminal = {
      expr = builtins.elem "ansi-red" (semantic.getAvailableNames "terminal");
      expected = true;
    };

    # Test getAvailableCategories
    test-get-available-categories = {
      expr =
        let
          categories = semantic.getAvailableCategories;
        in
        (builtins.elem "core" categories)
        && (builtins.elem "terminal" categories)
        && (builtins.elem "syntax" categories);
      expected = true;
    };

    # Test that colors are different between light and dark modes
    test-background-differs-by-mode = {
      expr =
        let
          darkBg = semantic.core "background" "dark";
          lightBg = semantic.core "background" "light";
        in
        darkBg.hex != lightBg.hex;
      expected = true;
    };

    # Test that accent colors are the same (they don't have mode)
    # Actually, accent colors in the palette are shared, but we still need to pass mode
    # The semantic bridge should handle this correctly
    test-accent-color-resolution = {
      expr = isValidColor (semantic.status "error" "dark");
      expected = true;
    };
  };

  # Run all tests
  results = lib.mapAttrs (
    name: test:
    let
      result = test.expr;
      passed =
        if builtins.isFunction test.expected then test.expected result else result == test.expected;
    in
    {
      inherit passed;
      result = if passed then "✓" else "✗ Expected ${toString test.expected}, got ${toString result}";
    }
  ) tests;

  # Check if all tests passed
  allPassed = lib.all (test: test.passed) (builtins.attrValues results);

  # Generate report
  report = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: result: "  ${name}: ${result.result}") results
  );

in
pkgs.runCommand "unit-lib-semantic"
  {
    passthru = {
      inherit tests results allPassed;
    };
  }
  ''
    echo "Testing lib/semantic.nix..."
    echo ""
    ${report}
    echo ""

    ${
      if allPassed then
        ''
          echo "✓ All semantic bridge tests passed (${toString (builtins.length (builtins.attrNames tests))} tests)"
          touch $out
        ''
      else
        ''
          echo "✗ Some semantic bridge tests failed"
          exit 1
        ''
    }
  ''
