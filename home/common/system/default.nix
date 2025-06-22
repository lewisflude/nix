{
  lib,
  system,
  ...
}:
{
  imports = [
    # Cross-platform system modules
    ./auto-update.nix
    ./yubikey.nix
    ./usb.nix
    ./keyboard.nix
    ./video-conferencing.nix

    # Linux-specific system modules
  ] ++ lib.optionals (lib.hasInfix "linux" system) [
    ./mangohud.nix
    ./yubikey-touch-detector.nix
  ];
}