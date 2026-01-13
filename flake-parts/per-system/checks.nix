{
  outputBuilders,
  ...
}:
{
  perSystem =
    { system, pkgs, ... }:
    {
      # Checks for this system (pre-commit, tests, etc.)
      checks =
        (outputBuilders.mkChecks.${system} or { }) // (import ../../tests/default.nix { inherit pkgs; });
    };
}
