{
  inputs,
  lib,
  ...
}:
{
  imports = lib.optionals (inputs ? nixos-hardware && inputs.nixos-hardware ? nixosModules) [
    inputs.nixos-hardware.nixosModules.common-cpu-intel

    inputs.nixos-hardware.nixosModules.common-pc-ssd

    inputs.nixos-hardware.nixosModules.common-hidpi
  ];

}
