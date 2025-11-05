# Python overlay using nixpkgs-python
# Replaces standard nixpkgs Python interpreters with versions from nixpkgs-python
# This provides better cache coverage and pre-built Python packages
# Note: We only override the interpreters; packages will automatically use the new interpreters
{
  inputs,
  system,
}:
prev:
let
  pythonPkgs = inputs.nixpkgs-python.packages.${system} or { };

  # Helper to get Python from nixpkgs-python or fallback to nixpkgs
  # Only use nixpkgs-python if the package exists
  getPython = version: default: pythonPkgs.${version} or default;
in
{
  # Python 3.12 (default version used in this config)
  python312 = getPython "3.12" prev.python312;

  # Python 3.13 (used by Home Assistant)
  python313 = getPython "3.13" prev.python313;

  # Default python3 (use 3.12 as fallback)
  python3 = getPython "3.12" prev.python3;

  # Don't override packages directly - they will automatically use the new interpreters above
  # The packages from nixpkgs-python Python interpreters should be compatible
  # python312Packages, python313Packages, and python3Packages will use final.python312.pkgs, etc.
}
