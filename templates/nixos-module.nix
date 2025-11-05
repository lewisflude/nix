{
  pkgs,
  lib,
  username,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    systemd
    udev
    linux-firmware
  ];
  systemd.services.example = {
    description = "Example service";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.example}/bin/example";
      Restart = "on-failure";
    };
  };
  systemd.timers.example = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
  hardware = {
    example.enable = true;
  };
  boot = {
    loader.systemd-boot.enable = lib.mkDefault true;
    kernelModules = [ "example-module" ];
  };
  networking = {
    firewall.allowedTCPPorts = [
      80
      443
    ];
  };
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };
}
