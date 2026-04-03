# Printing Module - Dendritic Pattern
# CUPS printing services with network printer discovery via Avahi
_: {
  flake.modules.nixos.printing =
    { pkgs, ... }:
    {
      services.printing.enable = true;

      # Network printer discovery via mDNS/DNS-SD
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };

      environment.systemPackages = [ pkgs.cups-pk-helper ];
    };
}
