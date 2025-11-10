{ ... }:
{
  imports = [

    # ../apps/cursor  # Disabled to save ~1.04 GiB
    ../apps/lazydocker.nix
    ../features/development

    ../apps/docker.nix

    ./desktop.nix

    ../apps/aws.nix
  ];

}
