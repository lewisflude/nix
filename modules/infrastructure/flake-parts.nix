# Enable flake-parts modules system for dendritic pattern
{ inputs, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.modules
  ];
}
