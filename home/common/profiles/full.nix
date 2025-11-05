# Full profile
# Complete configuration with all features enabled
# This profile includes base essentials plus optional features
{ ... }:
{
  imports = [
    ./base.nix
    ./optional.nix
  ];
}
