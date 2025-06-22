{ pkgs, ... }: {
  services.udev.packages = with pkgs; [
    vial
    via
  ];
}
