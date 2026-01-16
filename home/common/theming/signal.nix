# Signal Design System Integration
# Imports Signal flake module for theming
{
  inputs,
  ...
}:
{
  imports = [
    inputs.signal.homeManagerModules.default
  ];

  # Configuration is done in home/common/theming/default.nix
  # This file only imports the Signal flake module
  config = { };
}
