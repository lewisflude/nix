{
  imports = [
    ./version-control.nix
    # Language-specific packages removed - now managed by modules/shared/features/development.nix
    # ./python.nix
    # ./go.nix
    # ./node.nix
    # ./lua.nix
    ./language-tools.nix
  ];
}
