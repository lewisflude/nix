{ ... }:
{
  imports = [

    ../apps/cursor
    ../apps/lazydocker.nix
    ../features/development

    # Docker packages now handled by system-level virtualisation module
    # ../apps/docker.nix

    ./desktop.nix

    ../apps/aws.nix
  ];

}
