{ ... }:
{
  imports = [
    ../apps/cursor
    # NOTE: development features are imported via home/common/features/default.nix
    # Do not import here to avoid duplicate module imports (causes neovim conflict)

    # Docker packages now handled by system-level virtualisation module
    # ../apps/docker.nix

    ./desktop.nix

    ../apps/aws.nix
  ];
}
