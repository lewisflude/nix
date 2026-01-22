{
  self,
  ...
}:
let
  # Helper to check if system is Linux
  isLinux =
    system:
    builtins.elem system [
      "x86_64-linux"
      "aarch64-linux"
    ];
in
{
  perSystem =
    { system, ... }:
    {
      # nix-topology module configuration
      # Only enable for Linux systems that have NixOS configurations
      topology.modules =
        if isLinux system then
          [
            {
              inherit (self) nixosConfigurations;
            }
          ]
        else
          [ ];
    };
}
