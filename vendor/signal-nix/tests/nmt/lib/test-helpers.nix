# Signal Design System - Test Helpers
#
# Shared utilities and assertions for NMT tests

{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.test = {
    # Custom test assertions
    assertions = {
      expected = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Expected assertion messages";
      };
    };

    warnings = {
      expected = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Expected warning messages";
      };
    };
  };

  config = {
    # Helper to capture and verify assertions
    home.file = lib.mkMerge [
      (lib.mkIf (config.test.assertions.expected != [ ]) {
        "test/assertions.actual".text = lib.concatMapStringsSep "\n---\n" (x: x.message) (
          lib.filter (x: !x.assertion) config.assertions
        );

        "test/assertions.expected".text = lib.concatStringsSep "\n---\n" config.test.assertions.expected;
      })

      (lib.mkIf (config.test.warnings.expected != [ ]) {
        "test/warnings.actual".text = lib.concatStringsSep "\n---\n" config.warnings;

        "test/warnings.expected".text = lib.concatStringsSep "\n---\n" config.test.warnings.expected;
      })
    ];

    # NMT assertion scripts
    nmt.script = lib.mkMerge [
      (lib.mkIf (config.test.assertions.expected != [ ]) ''
        assertFileContent \
          home-files/test/assertions.actual \
          home-files/test/assertions.expected
      '')

      (lib.mkIf (config.test.warnings.expected != [ ]) ''
        assertFileContent \
          home-files/test/warnings.actual \
          home-files/test/warnings.expected
      '')
    ];
  };
}
