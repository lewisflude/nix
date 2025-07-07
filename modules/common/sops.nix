{
  ...
}:
{
  # Note: SOPS package installation is handled at user-level in home/common/sops.nix
  # Platform-specific SOPS configurations are in:
  # - modules/darwin/sops.nix (uses wheel group)
  # - modules/nixos/sops.nix (uses root group)
}
