{
  config,
  lib,
  ...
}: let
  cfg = config.features.desktop;
in {
  imports = [
    ./audio
    ./desktop-environment.nix
    ./graphics.nix
    ./hyprland.nix
    ./niri.nix
    ./theme.nix
    ./xwayland.nix

    # --- ADD THIS SECTION ---
    # Hardware
    ../../hardware/bluetooth.nix
    ../../hardware/keyboard.nix
    ../../hardware/mouse.nix
    ../../hardware/usb.nix
    ../../hardware/yubikey.nix
    # ------------------------
  ];

  options.features.desktop = {
    enable = lib.mkEnableOption "Enable desktop environment";
  };

  config = lib.mkIf cfg.enable {
    # Automatically add the user to desktop-related groups
    users.users.${config.host.username}.extraGroups = [
      "audio"
      "video"
      "input"
      "networkmanager"
    ];
  };
}
