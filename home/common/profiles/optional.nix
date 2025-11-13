{ ... }:
{
  imports = [

    # ../apps/cursor  # Disabled to save ~1.04 GiB
    ../apps/lazydocker.nix
    ../features/development

    # Docker packages now handled by system-level virtualisation module
    # ../apps/docker.nix

    ./desktop.nix

    ../apps/aws.nix
  ];

}
