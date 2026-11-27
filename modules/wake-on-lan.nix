# Wake-on-LAN module
# Uses a systemd .link unit (applied by udev when the NIC appears) rather than
# networking.interfaces.wakeOnLan, which regressed DHCP under systemd-networkd
# (nixpkgs #339082), or an ethtool oneshot.
_: {
  flake.modules.nixos.wakeOnLan = {
    # .link [Match] runs before renaming, so match on the onboard name udev's
    # net_id builtin computed (imported earlier in 80-net-setup-link.rules).
    #
    # The first matching .link wins, so this replaces 99-default.link for this
    # NIC; carry its naming/MAC policy so eno2 keeps its name.
    systemd.network.links."50-wol-eno2" = {
      matchConfig.Property = "ID_NET_NAME_ONBOARD=eno2";
      linkConfig = {
        WakeOnLan = "magic";
        NamePolicy = "keep kernel database onboard slot path";
        AlternativeNamesPolicy = "database onboard slot path";
        MACAddressPolicy = "persistent";
      };
    };

    # No firewall rule needed: magic packets are handled by the NIC while
    # the host is off, before the kernel firewall exists.
  };
}
