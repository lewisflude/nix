# Wake-on-LAN module
# Uses ethtool service instead of networking.interfaces.wakeOnLan to avoid
# DHCP regression with systemd-networkd (nixpkgs #339082)
_:
{
  flake.modules.nixos.wakeOnLan =
    { pkgs, ... }:
    {
      systemd.services.wakeonlan = {
        description = "Enable Wake-on-LAN for eno2";
        after = [ "network.target" ];
        serviceConfig = {
          Type = "simple";
          RemainAfterExit = true;
          ExecStart = "${pkgs.ethtool}/sbin/ethtool -s eno2 wol g";
        };
        wantedBy = [ "default.target" ];
      };

      networking.firewall.allowedUDPPorts = [ 9 ];
    };
}
