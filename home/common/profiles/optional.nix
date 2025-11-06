{ ... }:
{
  imports = [

    ../apps/cursor
    ../apps/lazydocker.nix
    ../features/development

    ../apps/docker.nix

    ./desktop.nix

    ../apps/aws.nix
  ];

}
