{ outputBuilders, ... }:
{
  perSystem =
    { system, ... }:
    {
      # Checks for this system (pre-commit, tests, etc.)
      # Note: NixOS VM tests are temporarily disabled due to infinite recursion issues
      checks = outputBuilders.mkChecks.${system} or { };
    };
}
