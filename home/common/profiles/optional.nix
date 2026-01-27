{ ... }:
{
  imports = [

    ../apps/cursor
    ../features/development

    # Docker packages now handled by system-level virtualisation module
    # ../apps/docker.nix

    ./desktop.nix

    ../apps/aws.nix
  ];

}
