{
  lib,
  system,
  ...
}:
{
  imports = [
    # Cross-platform system modules
    ./yubikey.nix
    ./usb.nix
    ./keyboard.nix
    ./video-conferencing.nix

    # Linux-specific system modules
  ] ++ lib.optionals (lib.hasInfix "linux" system) [
    ./auto-update.nix
    ./mangohud.nix
    ./yubikey-touch-detector.nix
  ];
}