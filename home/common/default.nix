{ ... }:
{
  imports = [
    # Base profile (core tools and configuration)
    ./profiles/base.nix

    # Optional profile (additional tools and features)
    ./profiles/optional.nix
  ];
}
