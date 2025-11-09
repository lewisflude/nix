{
  outputBuilders,
  ...
}:
{
  perSystem =
    { system, ... }:
    {
      # Checks for this system (pre-commit, tests, etc.)
      checks = outputBuilders.mkChecks.${system} or { };
    };
}
