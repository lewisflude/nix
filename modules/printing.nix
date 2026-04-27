# Printing Module - Dendritic Pattern
# CUPS printing services with network printer discovery via Avahi
_: {
  flake.modules.nixos.printing =
    { pkgs, ... }:
    {
      services.printing.enable = true;

      # Avahi (mDNS printer discovery) is enabled in core/networking.nix

      environment.systemPackages = [ pkgs.cups-pk-helper ];
    };
}
