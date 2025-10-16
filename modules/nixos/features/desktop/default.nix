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

  # --- AND ADD THIS SECTION ---
  config = lib.mkIf cfg.enable (
    let
      # Define all hardware features this module enables
      hardwareToEnable = ["bluetooth" "keyboard" "mouse" "usb" "yubikey"];

      # Function to generate the { hardware.<name>.enable = true; } attrset
      mkEnable = name: {hardware."${name}".enable = true;};
    in
      # Map over the list and merge all attrsets into one
      lib.mergeAttrsOf (map mkEnable hardwareToEnable)
      // {
        # Automatically add the user to desktop-related groups
        users.users.${config.host.username}.extraGroups = [
          "audio"
          "video"
          "input"
          "networkmanager"
        ];
      }
  );
  # ----------------------------
}
