# Enable flake-parts modules system for dendritic pattern
# Re-imports the official flake-parts modules system
{ inputs, ... }:
{
  imports = [
    # Use official flake-parts modules system
    # This enables proper module merging with deferredModule type
    inputs.flake-parts.flakeModules.modules
  ];

  # Note: The "unknown flake output 'modules'" warning is expected and harmless
  # It occurs because flake-parts exposes flake.modules as an output for external consumption
  # but Nix doesn't recognize 'modules' as a standard flake output type
  # The functionality works correctly - this is just a warning during flake check
}
