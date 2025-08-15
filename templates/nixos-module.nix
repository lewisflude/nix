# Template for modules/nixos/ - NixOS/Linux-specific system modules
{
  pkgs,
  lib,
  username,
  ...
}: {
  # NixOS-specific system configuration
  # No platform detection needed - this module only loads on NixOS

  # Linux-specific packages
  environment.systemPackages = with pkgs; [
    # Linux-specific packages
    systemd
    udev
    linux-firmware
  ];

  # Systemd services (Linux only)
  systemd.services.example = {
    description = "Example service";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "${pkgs.example}/bin/example";
      Restart = "on-failure";
    };
  };

  # Systemd timers (Linux only)
  systemd.timers.example = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # Linux-specific hardware configuration
  hardware = {
    example.enable = true;
  };

  # Boot configuration (NixOS only)
  boot = {
    loader.systemd-boot.enable = lib.mkDefault true;
    kernelModules = ["example-module"];
  };

  # Linux-specific network configuration
  networking = {
    firewall.allowedTCPPorts = [80 443];
  };

  # User management (NixOS style)
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager"];
  };
}
