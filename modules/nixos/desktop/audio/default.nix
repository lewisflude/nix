{ ... }: {
  imports = [
    ./pipewire.nix
    ./hardware-specific.nix
    ./packages.nix
  ];
}
