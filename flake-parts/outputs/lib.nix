{
  functionsLib,
  ...
}:
{
  # Flake library exports
  # Makes custom functions available to other flakes that import this one
  flake.lib = functionsLib;
}
